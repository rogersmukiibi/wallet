// lib/models/income.dart

class Income {
  final int? id;
  final DateTime date;
  final int amount;
  final String? note;
  final int sourceId;   // FK -> income_sources.id
  final int accountId;  // FK -> accounts.id

  const Income({
    this.id,
    required this.date,
    required this.amount,
    this.note,
    required this.sourceId,
    required this.accountId,
  });

  factory Income.fromMap(Map<String, Object?> m) => Income(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        amount: m['amount'] as int,
        note: m['note'] as String?,
        sourceId: m['source_id'] as int,
        accountId: m['account_id'] as int,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'note': note,
        'source_id': sourceId,
        'account_id': accountId,
      };
}