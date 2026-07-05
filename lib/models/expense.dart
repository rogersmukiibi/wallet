// lib/models/expense.dart

class Expense {
  final int? id;
  final DateTime date;
  final int amount;        // UGX, always positive — direction is implied by type
  final String? note;
  final int categoryId;    // FK -> categories.id (never the protected "Fees" row)
  final int accountId;     // FK -> accounts.id

  const Expense({
    this.id,
    required this.date,
    required this.amount,
    this.note,
    required this.categoryId,
    required this.accountId,
  });

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        amount: m['amount'] as int,
        note: m['note'] as String?,
        categoryId: m['category_id'] as int,
        accountId: m['account_id'] as int,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'note': note,
        'category_id': categoryId,
        'account_id': accountId,
      };
}