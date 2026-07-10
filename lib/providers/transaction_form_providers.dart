// lib/providers/transaction_form_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tx_type.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/transfer.dart';
import '../core/utils/month.dart';
import 'db_providers.dart';
import 'account_providers.dart';
import 'transaction_providers.dart';

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
  final int? editingId;       // null = creating new; non-null = editing existing
  final DateTime? originalDateTime; // date before edits, for rollover recalculation

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
    this.editingId,
    this.originalDateTime,
  });

  bool get isEditing => editingId != null;

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
      editingId: editingId,
      originalDateTime: originalDateTime,
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
        editingId: state.editingId,
        originalDateTime: state.originalDateTime,
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

  /// Loads an existing transaction into the form for editing. Fetches the
  /// full record (TxEntry doesn't carry enough detail — no categoryId,
  /// accountId, note, etc.) via the appropriate repository.
  Future<void> loadForEdit(TxEntry entry) async {
    switch (entry.type) {
      case TxType.expense:
        final e = await ref.read(expenseRepositoryProvider).getById(entry.id);
        if (e == null) return;
        state = TransactionFormState(
          type: TxType.expense,
          dateTime: e.date,
          amount: e.amount,
          categoryId: e.categoryId,
          accountId: e.accountId,
          note: e.note ?? '',
          editingId: e.id,
          originalDateTime: e.date,
        );
      case TxType.income:
        final i = await ref.read(incomeRepositoryProvider).getById(entry.id);
        if (i == null) return;
        state = TransactionFormState(
          type: TxType.income,
          dateTime: i.date,
          amount: i.amount,
          sourceId: i.sourceId,
          accountId: i.accountId,
          note: i.note ?? '',
          editingId: i.id,
          originalDateTime: i.date,
        );
      case TxType.transfer:
        final t = await ref.read(transferRepositoryProvider).getById(entry.id);
        if (t == null) return;
        state = TransactionFormState(
          type: TxType.transfer,
          dateTime: t.date,
          amount: t.amount,
          fee: t.fee,
          feeExpanded: t.fee > 0,
          accountId: t.fromAccountId,
          toAccountId: t.toAccountId,
          note: t.note ?? '',
          editingId: t.id,
          originalDateTime: t.date,
        );
    }
  }

  Future<void> save() async {
    if (!state.isValid) return;

    switch (state.type) {
      case TxType.expense:
        if (state.isEditing) {
          await ref.read(expenseRepositoryProvider).update(Expense(
                id: state.editingId,
                date: state.dateTime,
                amount: state.amount!,
                categoryId: state.categoryId!,
                accountId: state.accountId!,
                note: state.note,
              ));
        } else {
          await ref.read(expenseRepositoryProvider).create(
                date: state.dateTime,
                amount: state.amount!,
                categoryId: state.categoryId!,
                accountId: state.accountId!,
                note: state.note,
              );
        }
      case TxType.income:
        if (state.isEditing) {
          await ref.read(incomeRepositoryProvider).update(Income(
                id: state.editingId,
                date: state.dateTime,
                amount: state.amount!,
                sourceId: state.sourceId!,
                accountId: state.accountId!,
                note: state.note,
              ));
        } else {
          await ref.read(incomeRepositoryProvider).create(
                date: state.dateTime,
                amount: state.amount!,
                sourceId: state.sourceId!,
                accountId: state.accountId!,
                note: state.note,
              );
        }
      case TxType.transfer:
        if (state.isEditing) {
          await ref.read(transferRepositoryProvider).update(Transfer(
                id: state.editingId,
                date: state.dateTime,
                amount: state.amount!,
                fee: state.fee ?? 0,
                fromAccountId: state.accountId!,
                toAccountId: state.toAccountId!,
                note: state.note,
              ));
        } else {
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

    // Recalculate from the earlier of the two dates if this was an edit
    // that moved the transaction to a different month.
    final earliestAffected = (state.originalDateTime != null &&
            state.originalDateTime!.isBefore(state.dateTime))
        ? state.originalDateTime!
        : state.dateTime;
    await ref.read(accountRepositoryProvider).recalculateRolloversFrom(
          MonthKey.fromDate(earliestAffected),
        );

    ref.invalidate(accountsProvider);
    ref.invalidate(accountBalancesProvider);
    ref.invalidate(monthEntriesProvider);
    ref.invalidate(monthSummaryTotalsProvider);
    ref.invalidate(calendarGridTotalsProvider);
  }

  /// Deletes the transaction currently loaded for editing. No-op if the
  /// form was never put into edit mode.
  Future<void> deleteCurrent() async {
    if (!state.isEditing) return;
    final id = state.editingId!;
    final deletedDate = state.dateTime;

    switch (state.type) {
      case TxType.expense:
        await ref.read(expenseRepositoryProvider).delete(id);
      case TxType.income:
        await ref.read(incomeRepositoryProvider).delete(id);
      case TxType.transfer:
        await ref.read(transferRepositoryProvider).delete(id);
    }

    await ref.read(accountRepositoryProvider).recalculateRolloversFrom(
          MonthKey.fromDate(deletedDate),
        );

    ref.invalidate(accountsProvider);
    ref.invalidate(accountBalancesProvider);
    ref.invalidate(monthEntriesProvider);
    ref.invalidate(monthSummaryTotalsProvider);
    ref.invalidate(calendarGridTotalsProvider);
  }
}

final transactionFormProvider =
    StateNotifierProvider.autoDispose<TransactionFormNotifier, TransactionFormState>(
  (ref) => TransactionFormNotifier(ref),
);