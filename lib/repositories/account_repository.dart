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

  /// One-click carry-forward: writes next month's rollover as this
  /// month's closing balance. Explicit write, so a manual correction
  /// later isn't silently overwritten by a live recalculation.
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

  Future<int> _sum(Database db, String table, String column, String where, List<Object?> args) async {
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM($column), 0) as total FROM $table WHERE $where', args);
    return result.first['total'] as int;
  }
}