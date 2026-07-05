import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tx_type.dart';
import 'db_providers.dart';

class TransactionFormState {
  final TxType type;
  final DateTime dateTime;
  final int? amount;
  final int? fee;
  final bool feeExpanded;
  final int? categoryId;
  final int? sourceId;
  final int? accountId;
  final int? toAccountId;
  final String note;

  const TransactionFormState({
    this.type = TxType.expense,
    required this.dateTime,
    this.amount,
    this.fee,
    this.feeExpanded = false,
    this.categoryId,
    this.sourceId,
    this.accountId,
    this.toAccountId,
    this.note = '',
  });

  bool get isValid {
    if (amount == null || amount == 0) return false;
    switch (type) {
      case TxType.expense:
        return categoryId != null && accountId != null;
      case TxType.income:
        return sourceId != null && accountId != null;
      case TxType.transfer:
        return accountId != null && toAccountId != null && accountId != toAccountId;
    }
  }

  TransactionFormState copyWith({
    TxType? type,
    DateTime? dateTime,
    int? amount,
    bool clearAmount = false,
    int? fee,
    bool? feeExpanded,
    int? categoryId,
    int? sourceId,
    int? accountId,
    int? toAccountId,
    String? note,
  }) {
    return TransactionFormState(
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      amount: clearAmount ? null : (amount ?? this.amount),
      fee: fee ?? this.fee,
      feeExpanded: feeExpanded ?? this.feeExpanded,
      categoryId: categoryId ?? this.categoryId,
      sourceId: sourceId ?? this.sourceId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      note: note ?? this.note,
    );
  }
}

class TransactionFormNotifier extends StateNotifier<TransactionFormState> {
  final Ref ref;
  TransactionFormNotifier(this.ref) : super(TransactionFormState(dateTime: DateTime.now()));

  void setType(TxType type) => state = TransactionFormState(
        type: type,
        dateTime: state.dateTime,
        amount: state.amount,
        note: state.note,
      );

  void setDateTime(DateTime dt) => state = state.copyWith(dateTime: dt);
  void setAmount(int? amount) => state = state.copyWith(amount: amount, clearAmount: amount == null);
  void setFee(int? fee) => state = state.copyWith(fee: fee);
  void toggleFee() => state = state.copyWith(feeExpanded: !state.feeExpanded);
  void setCategory(int id) => state = state.copyWith(categoryId: id);
  void setSource(int id) => state = state.copyWith(sourceId: id);
  void setAccount(int id) => state = state.copyWith(accountId: id);
  void setToAccount(int id) => state = state.copyWith(toAccountId: id);
  void setNote(String note) => state = state.copyWith(note: note);

  void swapFromTo() {
    final from = state.accountId, to = state.toAccountId;
    if (from == null || to == null) return;
    state = state.copyWith(accountId: to, toAccountId: from);
  }

  Future<void> save() async {
    if (!state.isValid) return;
    switch (state.type) {
      case TxType.expense:
        await ref.read(expenseRepositoryProvider).create(
              date: state.dateTime,
              amount: state.amount!,
              categoryId: state.categoryId!,
              accountId: state.accountId!,
              note: state.note,
            );
      case TxType.income:
        await ref.read(incomeRepositoryProvider).create(
              date: state.dateTime,
              amount: state.amount!,
              sourceId: state.sourceId!,
              accountId: state.accountId!,
              note: state.note,
            );
      case TxType.transfer:
        await ref.read(transferRepositoryProvider).create(
              date: state.dateTime,
              amount: state.amount!,
              fee: state.fee ?? 0,
              fromAccountId: state.accountId!,
              toAccountId: state.toAccountId!,
              note: state.note,
            );
    }
  }
}

final transactionFormProvider =
    StateNotifierProvider.autoDispose<TransactionFormNotifier, TransactionFormState>(
  (ref) => TransactionFormNotifier(ref),
);
