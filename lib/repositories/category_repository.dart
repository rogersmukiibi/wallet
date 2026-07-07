// lib/repositories/category_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/db_providers.dart';
import '../core/constants/protected_names.dart';

class CategoryRepository {
  final Ref ref;
  CategoryRepository(this.ref);

  Future<List<Category>> getAll({bool includeArchived = false}) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('categories',
        where: includeArchived ? null : 'archived = 0', orderBy: 'sort_order, name');
    return rows.map(Category.fromMap).toList();
  }

  /// Excludes protected categories — that row only ever gets written by transfer logic.
  Future<List<Category>> getSelectable() async {
    final all = await getAll();
    return all.where((c) => !ProtectedNames.isProtectedCategory(c.name)).toList();
  }

  Future<int> create(String name) async {
    if (ProtectedNames.isProtectedCategory(name.trim())) {
      throw ArgumentError('"$name" is a protected, auto-computed category.');
    }
    final db = await ref.read(databaseProvider.future);
    return db.insert('categories', {'name': name, 'sort_order': 0, 'archived': 0});
  }

  Future<void> archive(int id) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty && ProtectedNames.isProtectedCategory(rows.first['name'] as String)) {
      throw ArgumentError('"${rows.first['name']}" is protected and cannot be archived.');
    }
    await db.update('categories', {'archived': 1}, where: 'id = ?', whereArgs: [id]);
  }
}