// lib/models/transfer.dart

class Transfer {
  final int? id;
  final DateTime date;
  final int amount;
  final int fee;         // 0 if no fee — this is the sole source of "Fees" category totals
  final String? note;
  final int fromAccountId;
  final int toAccountId;

  const Transfer({
    this.id,
    required this.date,
    required this.amount,
    this.fee = 0,
    this.note,
    required this.fromAccountId,
    required this.toAccountId,
  });

  factory Transfer.fromMap(Map<String, Object?> m) => Transfer(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        amount: m['amount'] as int,
        fee: m['fee'] as int? ?? 0,
        note: m['note'] as String?,
        fromAccountId: m['from_account_id'] as int,
        toAccountId: m['to_account_id'] as int,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'fee': fee,
        'note': note,
        'from_account_id': fromAccountId,
        'to_account_id': toAccountId,
      };
}