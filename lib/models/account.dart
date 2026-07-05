// lib/models/account.dart
enum AccountType { debit, credit }

class AccountGroup {
  final int? id;
  final String name;
  final AccountType type;
  final int? parentGroupId; // null = top-level
  final int depth; // 1..3
  final int sortOrder;

  const AccountGroup({
    this.id,
    required this.name,
    required this.type,
    this.parentGroupId,
    required this.depth,
    this.sortOrder = 0,
  });

  factory AccountGroup.fromMap(Map<String, Object?> m) => AccountGroup(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: AccountType.values.byName(m['type'] as String),
        parentGroupId: m['parent_group_id'] as int?,
        depth: m['depth'] as int,
        sortOrder: m['sort_order'] as int? ?? 0,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type.name,
        'parent_group_id': parentGroupId,
        'depth': depth,
        'sort_order': sortOrder,
      };
}

class Account {
  final int? id;
  final String name;
  final AccountType type;
  final int? groupId; // nullable — ungrouped is valid
  final int sortOrder;
  final bool archived;

  const Account({
    this.id,
    required this.name,
    required this.type,
    this.groupId,
    this.sortOrder = 0,
    this.archived = false,
  });

  factory Account.fromMap(Map<String, Object?> m) => Account(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: AccountType.values.byName(m['type'] as String),
        groupId: m['group_id'] as int?,
        sortOrder: m['sort_order'] as int? ?? 0,
        archived: (m['archived'] as int? ?? 0) == 1,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type.name,
        'group_id': groupId,
        'sort_order': sortOrder,
        'archived': archived ? 1 : 0,
      };
}

/// Computed, never stored (except `rollover`, which lives in account_rollovers).
class AccountBalance {
  final Account account;
  final int rollover;
  final int earned;
  final int spent;
  const AccountBalance({
    required this.account,
    required this.rollover,
    required this.earned,
    required this.spent,
  });
  int get current => rollover + earned - spent;
}