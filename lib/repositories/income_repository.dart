import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/income.dart';
import '../providers/db_providers.dart';

class IncomeRepository {
  final Ref ref;
  IncomeRepository(this.ref);

  Future<int> create({
    required DateTime date,
    required int amount,
    required int sourceId,
    required int accountId,
    String? note,
  }) async {
    final db = await ref.read(databaseProvider.future);
    return db.insert('incomes', Income(
      date: date, amount: amount, sourceId: sourceId, accountId: accountId, note: note,
    ).toMap());
  }

  Future<List<Income>> getForMonth(String monthKey) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('incomes',
        where: 'date LIKE ?', whereArgs: ['$monthKey%'], orderBy: 'date DESC');
    return rows.map(Income.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await ref.read(databaseProvider.future);
    await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }
}