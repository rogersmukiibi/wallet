// lib/repositories/expense_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/month.dart';
import '../models/expense.dart';
import '../providers/db_providers.dart';

class ExpenseRepository {
  final Ref ref;
  ExpenseRepository(this.ref);

  Future<int> create({
    required DateTime date,
    required int amount,
    required int categoryId,
    required int accountId,
    String? note,
  }) async {
    final db = await ref.read(databaseProvider.future);
    final id = await db.insert('expenses', Expense(
      date: date, amount: amount, categoryId: categoryId, accountId: accountId, note: note,
    ).toMap());
    await ref.read(accountRepositoryProvider).recalculateRolloversFrom(MonthKey.fromDate(date));
    return id;
  }

  Future<List<Expense>> getForMonth(String monthKey) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('expenses',
        where: 'date LIKE ?', whereArgs: ['$monthKey%'], orderBy: 'date DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('expenses', where: 'id = ?', whereArgs: [id], limit: 1);
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      await ref.read(accountRepositoryProvider)
          .recalculateRolloversFrom(MonthKey.fromDate(DateTime.parse(rows.first['date'] as String)));
    }
  }

  /// Fetches expenses within [start, end] inclusive. Used for calendar-grid
  /// spillover days from adjacent months, where pulling the whole adjacent
  /// month via getForMonth() would be wasteful.
  Future<List<Expense>> getForDateRange(DateTime start, DateTime end) async {
    final db = await ref.read(databaseProvider.future);
    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endExclusive = DateTime(end.year, end.month, end.day)
        .add(const Duration(days: 1))
        .toIso8601String();
    final rows = await db.query('expenses',
        where: 'date >= ? AND date < ?', whereArgs: [startStr, endExclusive], orderBy: 'date DESC');
    return rows.map(Expense.fromMap).toList();
  }
}