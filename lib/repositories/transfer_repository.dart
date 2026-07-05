import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer.dart';
import '../providers/db_providers.dart';

class TransferRepository {
  final Ref ref;
  TransferRepository(this.ref);

  Future<int> create({
    required DateTime date,
    required int amount,
    int fee = 0,
    required int fromAccountId,
    required int toAccountId,
    String? note,
  }) async {
    final db = await ref.read(databaseProvider.future);
    return db.insert('transfers', Transfer(
      date: date, amount: amount, fee: fee,
      fromAccountId: fromAccountId, toAccountId: toAccountId, note: note,
    ).toMap());
  }

  Future<List<Transfer>> getForMonth(String monthKey) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('transfers',
        where: 'date LIKE ?', whereArgs: ['$monthKey%'], orderBy: 'date DESC');
    return rows.map(Transfer.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await ref.read(databaseProvider.future);
    await db.delete('transfers', where: 'id = ?', whereArgs: [id]);
  }
}