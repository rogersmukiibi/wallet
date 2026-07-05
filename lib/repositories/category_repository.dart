import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/db_providers.dart';

class CategoryRepository {
  final Ref ref;
  CategoryRepository(this.ref);

  Future<List<Category>> getAll({bool includeArchived = false}) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.query('categories',
        where: includeArchived ? null : 'archived = 0', orderBy: 'sort_order, name');
    return rows.map(Category.fromMap).toList();
  }

  /// Excludes "Fees" — that row only ever gets written by transfer logic.
  Future<List<Category>> getSelectable() async {
    final all = await getAll();
    return all.where((c) => c.name != 'Fees').toList();
  }

  Future<int> create(String name) async {
    if (name.trim().toLowerCase() == 'fees') {
      throw ArgumentError('Fees is a protected, auto-computed category.');
    }
    final db = await ref.read(databaseProvider.future);
    return db.insert('categories', {'name': name, 'sort_order': 0, 'archived': 0});
  }

  Future<void> archive(int id) async {
    final db = await ref.read(databaseProvider.future);
    await db.update('categories', {'archived': 1}, where: 'id = ?', whereArgs: [id]);
  }
}