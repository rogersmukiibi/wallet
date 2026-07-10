// lib/repositories/transfer_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/month.dart';
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
    final id = await db.insert('transfers', Transfer(
      date: date, amount: amount, fee: fee,
      fromAccountId: fromAccountId, toAccountId: toAccountId, note: note,
    ).toMap());
    await ref.read(accountRepositoryProvider).recalculateRolloversFrom(MonthKey.fromDate(date));
    return id;
  }

  Future<List<Transfer>> getForMonth(String monthKey) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('transfers',
        where: 'date LIKE ?', whereArgs: ['$monthKey%'], orderBy: 'date DESC');
    return rows.map(Transfer.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('transfers', where: 'id = ?', whereArgs: [id], limit: 1);
    await db.delete('transfers', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      await ref.read(accountRepositoryProvider)
          .recalculateRolloversFrom(MonthKey.fromDate(DateTime.parse(rows.first['date'] as String)));
    }
  }

  Future<Transfer?> getById(int id) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('transfers', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Transfer.fromMap(rows.first);
  }

  Future<void> update(Transfer transfer) async {
    final db = await ref.read(databaseProvider.future);
    final oldRows = await db.query('transfers', where: 'id = ?', whereArgs: [transfer.id], limit: 1);
    await db.update('transfers', transfer.toMap(), where: 'id = ?', whereArgs: [transfer.id]);

    if (oldRows.isNotEmpty) {
      final oldDate = DateTime.parse(oldRows.first['date'] as String);
      await ref.read(accountRepositoryProvider).recalculateRolloversFrom(MonthKey.fromDate(oldDate));
    }
    await ref.read(accountRepositoryProvider).recalculateRolloversFrom(MonthKey.fromDate(transfer.date));
  }
}