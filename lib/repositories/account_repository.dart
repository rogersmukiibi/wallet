// lib/repositories/account_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../providers/db_providers.dart';
import '../core/utils/month.dart';

class AccountRepository {
  final Ref ref;
  AccountRepository(this.ref);

  Future<List<Account>> getAll({bool includeArchived = false}) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query(
      'accounts',
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'sort_order, name',
    );
    return rows.map(Account.fromMap).toList();
  }

  Future<int> create(Account account) async {
    final db = await ref.read(databaseProvider.future);
    return db.insert('accounts', account.toMap());
  }

  /// Rename / re-group / reorder. Deliberately does NOT accept `type` —
  /// flipping debit/credit after creation would invert the meaning of
  /// every past transaction against this account. Archive + recreate instead.
  Future<void> update(Account account) async {
    final db = await ref.read(databaseProvider.future);
    await db.update(
      'accounts',
      {
        'name': account.name,
        'group_id': account.groupId,
        'sort_order': account.sortOrder,
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> archive(int id) async {
    final db = await ref.read(databaseProvider.future);
    await db.update('accounts', {'archived': 1}, where: 'id = ?', whereArgs: [id]);
  }

  /// rollover + earned - spent, scoped to [month].
  Future<AccountBalance> getBalance(Account account, MonthKey month) async {
    final db = await ref.read(databaseProvider.future);
    final start = month.start.toIso8601String();
    final endExclusive = month.next.start.toIso8601String();

    final rolloverRows = await db.query(
      'account_rollovers',
      where: 'account_id = ? AND month = ?',
      whereArgs: [account.id, month.key],
    );
    final rollover = rolloverRows.isEmpty ? 0 : rolloverRows.first['rollover'] as int;

    final incomeSum = await _sum(db, 'incomes', 'amount',
        'account_id = ? AND date >= ? AND date < ?', [account.id, start, endExclusive]);
    final transfersInSum = await _sum(db, 'transfers', 'amount',
        'to_account_id = ? AND date >= ? AND date < ?', [account.id, start, endExclusive]);
    final expenseSum = await _sum(db, 'expenses', 'amount',
        'account_id = ? AND date >= ? AND date < ?', [account.id, start, endExclusive]);
    final transfersOutSum = await _sum(db, 'transfers', 'amount',
        'from_account_id = ? AND date >= ? AND date < ?', [account.id, start, endExclusive]);
    final feesOutSum = await _sum(db, 'transfers', 'fee',
        'from_account_id = ? AND date >= ? AND date < ?', [account.id, start, endExclusive]);

    return AccountBalance(
      account: account,
      rollover: rollover,
      earned: incomeSum + transfersInSum,
      spent: expenseSum + transfersOutSum + feesOutSum,
    );
  }

  Future<List<AccountBalance>> getAllBalances(MonthKey month) async {
    final accounts = await getAll();
    final balances = <AccountBalance>[];
    for (final a in accounts) {
      balances.add(await getBalance(a, month));
    }
    return balances;
  }

  Future<void> carryForward(MonthKey fromMonth) async {
    final db = await ref.read(databaseProvider.future);
    final accounts = await getAll();
    final toMonth = fromMonth.next;
    for (final a in accounts) {
      final balance = await getBalance(a, fromMonth);
      await db.insert(
        'account_rollovers',
        {'account_id': a.id, 'month': toMonth.key, 'rollover': balance.current},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Recomputes every stored rollover from [month] forward.
  ///
  /// This keeps later months in sync after a backdated transaction changes a
  /// prior month. It stops once the next month no longer has a stored rollover,
  /// which means it only refreshes months that were previously carried forward.
  Future<void> recalculateRolloversFrom(MonthKey month) async {
    final db = await ref.read(databaseProvider.future);
    var cursor = month;
    while (true) {
      final next = cursor.next;
      final hasNextRollover = await db.query(
        'account_rollovers',
        where: 'month = ?',
        whereArgs: [next.key],
        limit: 1,
      );
      if (hasNextRollover.isEmpty) break;
      await carryForward(cursor);
      cursor = next;
    }
  }

  /// For a freshly created account with no transaction history yet: writes
  /// the starting balance directly as [month]'s rollover. Not a transaction
  /// — there's no prior activity to reconcile against, so nothing to log.
  ///
  /// Guarded: throws if the account already has any income/expense/transfer
  /// activity in [month], or already has a rollover row for [month]. In
  /// either of those cases this isn't really an "opening" balance anymore —
  /// use adjustBalanceTo() instead so the correction is logged as a
  /// visible transaction rather than silently overwriting rollover.
  Future<void> setOpeningBalance(int accountId, MonthKey month, int amount) async {
    final db = await ref.read(databaseProvider.future);
    final start = month.start.toIso8601String();
    final endExclusive = month.next.start.toIso8601String();

    final existingRollover = await db.query(
      'account_rollovers',
      where: 'account_id = ? AND month = ?',
      whereArgs: [accountId, month.key],
    );
    if (existingRollover.isNotEmpty) {
      throw StateError(
        'Account $accountId already has a rollover for ${month.key}. '
        'Use adjustBalanceTo() to correct an existing balance instead.',
      );
    }

    final hasActivity = await _hasAnyActivity(db, accountId, start, endExclusive);
    if (hasActivity) {
      throw StateError(
        'Account $accountId already has transaction activity in ${month.key}. '
        'setOpeningBalance() is only safe on a month with no prior activity — '
        'use adjustBalanceTo() instead.',
      );
    }

    await db.insert(
      'account_rollovers',
      {'account_id': accountId, 'month': month.key, 'rollover': amount},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// For an account with existing history: corrects the *current* balance
  /// to [targetAmount] by writing a visible Income or Expense row against
  /// the protected "Balance Adjustment" category/source. Preserves the
  /// audit trail instead of silently rewriting rollover.
  Future<void> adjustBalanceTo({
    required Account account,
    required MonthKey month,
    required int targetAmount,
    String note = 'Balance adjustment',
    DateTime? date,
  }) async {
    final current = await getBalance(account, month);
    final delta = targetAmount - current.current;
    if (delta == 0) return;

    final db = await ref.read(databaseProvider.future);
    final txDate = (date ?? DateTime.now()).toIso8601String();

    if (delta > 0) {
      final sourceId = await _idByName(db, 'income_sources', 'Balance Adjustment');
      await db.insert('incomes', {
        'date': txDate,
        'amount': delta,
        'note': note,
        'source_id': sourceId,
        'account_id': account.id,
      });
    } else {
      final categoryId = await _idByName(db, 'categories', 'Balance Adjustment');
      await db.insert('expenses', {
        'date': txDate,
        'amount': -delta,
        'note': note,
        'category_id': categoryId,
        'account_id': account.id,
      });
    }
  }
  
  Future<bool> _hasAnyActivity(
    Database db,
    int accountId,
    String start,
    String endExclusive,
  ) async {
    final expenseCount = await _count(db, 'expenses',
        'account_id = ? AND date >= ? AND date < ?', [accountId, start, endExclusive]);
    if (expenseCount > 0) return true;

    final incomeCount = await _count(db, 'incomes',
        'account_id = ? AND date >= ? AND date < ?', [accountId, start, endExclusive]);
    if (incomeCount > 0) return true;

    final transfersOutCount = await _count(db, 'transfers',
        'from_account_id = ? AND date >= ? AND date < ?', [accountId, start, endExclusive]);
    if (transfersOutCount > 0) return true;

    final transfersInCount = await _count(db, 'transfers',
        'to_account_id = ? AND date >= ? AND date < ?', [accountId, start, endExclusive]);
    if (transfersInCount > 0) return true;

    return false;
  }

  Future<int> _count(Database db, String table, String where, List<Object?> args) async {
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM $table WHERE $where', args);
    return result.first['c'] as int;
  }
  
  Future<int> _idByName(Database db, String table, String name) async {
    final rows = await db.query(table, where: 'name = ?', whereArgs: [name], limit: 1);
    if (rows.isEmpty) {
      throw StateError('Expected protected row "$name" in $table — check migrations.');
    }
    return rows.first['id'] as int;
  }

  Future<int> _sum(Database db, String table, String column, String where, List<Object?> args) async {
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM($column), 0) as total FROM $table WHERE $where', args);
    return result.first['total'] as int;
  }
}