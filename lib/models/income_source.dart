// lib/models/income_source.dart

/// Same shape as Category — deliberately. Income sources and expense
/// categories are both flat, user-managed lists with no special behavior
/// of their own (unlike accounts, which carry type/group logic).
class IncomeSource {
  final int? id;
  final String name;
  final int sortOrder;
  final bool archived;

  const IncomeSource({
    this.id,
    required this.name,
    this.sortOrder = 0,
    this.archived = false,
  });

  factory IncomeSource.fromMap(Map<String, Object?> m) => IncomeSource(
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