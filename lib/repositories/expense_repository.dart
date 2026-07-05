import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return db.insert('expenses', Expense(
      date: date, amount: amount, categoryId: categoryId, accountId: accountId, note: note,
    ).toMap());
  }

  Future<List<Expense>> getForMonth(String monthKey) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('expenses',
        where: 'date LIKE ?', whereArgs: ['$monthKey%'], orderBy: 'date DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await ref.read(databaseProvider.future);
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}