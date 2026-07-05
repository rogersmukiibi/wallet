// lib/models/category.dart
class Category {
  final int? id;
  final String name;
  final int sortOrder;
  final bool archived;
  const Category({this.id, required this.name, this.sortOrder = 0, this.archived = false});

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as int?,
        name: m['name'] as String,
        sortOrder: m['sort_order'] as int? ?? 0,
        archived: (m['archived'] as int? ?? 0) == 1,
      );
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'sort_order': sortOrder,
        'archived': archived ? 1 : 0,
      };
}