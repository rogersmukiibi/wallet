import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/income_source.dart';
import '../providers/db_providers.dart';

class IncomeSourceRepository {
  final Ref ref;
  IncomeSourceRepository(this.ref);

  Future<List<IncomeSource>> getAll({bool includeArchived = false}) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('income_sources',
        where: includeArchived ? null : 'archived = 0', orderBy: 'sort_order, name');
    return rows.map(IncomeSource.fromMap).toList();
  }

  Future<int> create(String name) async {
    final db = await ref.read(databaseProvider.future);
    return db.insert('income_sources', {'name': name, 'sort_order': 0, 'archived': 0});
  }

  Future<void> archive(int id) async {
    final db = await ref.read(databaseProvider.future);
    await db.update('income_sources', {'archived': 1}, where: 'id = ?', whereArgs: [id]);
  }
}