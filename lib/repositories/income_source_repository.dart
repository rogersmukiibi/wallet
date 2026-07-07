// lib/repositories/income_source_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/income_source.dart';
import '../providers/db_providers.dart';
import '../core/constants/protected_names.dart';

class IncomeSourceRepository {
  final Ref ref;
  IncomeSourceRepository(this.ref);

  Future<List<IncomeSource>> getAll({bool includeArchived = false}) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('income_sources',
        where: includeArchived ? null : 'archived = 0', orderBy: 'sort_order, name');
    return rows.map(IncomeSource.fromMap).toList();
  }

  /// Excludes protected income sources — only written by
  /// AccountRepository.adjustBalanceTo(), never picked by hand.
  Future<List<IncomeSource>> getSelectable() async {
    final all = await getAll();
    return all.where((s) => !ProtectedNames.isProtectedIncomeSource(s.name)).toList();
  }

  Future<int> create(String name) async {
    if (ProtectedNames.isProtectedIncomeSource(name.trim())) {
      throw ArgumentError('"$name" is a protected, auto-computed source.');
    }
    final db = await ref.read(databaseProvider.future);
    return db.insert('income_sources', {'name': name, 'sort_order': 0, 'archived': 0});
  }

  Future<void> archive(int id) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('income_sources', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty && ProtectedNames.isProtectedIncomeSource(rows.first['name'] as String)) {
      throw ArgumentError('"${rows.first['name']}" is protected and cannot be archived.');
    }
    await db.update('income_sources', {'archived': 1}, where: 'id = ?', whereArgs: [id]);
  }
}