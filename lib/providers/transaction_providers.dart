// lib/providers/transaction_providers.dart
//
// Cross-screen providers for computed transaction views: the flat
// month-list, single-day lookups, and calendar-grid totals. Lives here
// (not in a feature screen file) because transaction_form_providers.dart
// needs to invalidate these after every save — providers depending on a
// UI screen file would be backwards layering.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db_providers.dart';
import 'selected_month_provider.dart';
import '../core/utils/month.dart';

class TxEntry {
  final DateTime date;
  final int amount;
  final String label;
  const TxEntry(this.date, this.amount, this.label);
}

Future<List<TxEntry>> _loadMonthEntries(Ref ref, MonthKey month) async {
  final expenses = await ref.read(expenseRepositoryProvider).getForMonth(month.key);
  final incomes = await ref.read(incomeRepositoryProvider).getForMonth(month.key);
  final transfers = await ref.read(transferRepositoryProvider).getForMonth(month.key);

  final categories = {for (final c in await ref.read(categoryRepositoryProvider).getAll()) c.id: c.name};
  final sources = {for (final s in await ref.read(incomeSourceRepositoryProvider).getAll()) s.id: s.name};
  final accounts = {for (final a in await ref.read(accountRepositoryProvider).getAll()) a.id: a.name};

  return [
    ...expenses.map((e) => TxEntry(e.date, -e.amount,
        '${categories[e.categoryId] ?? '?'} · ${accounts[e.accountId] ?? '?'}')),
    ...incomes.map((i) => TxEntry(i.date, i.amount,
        '${sources[i.sourceId] ?? '?'} · ${accounts[i.accountId] ?? '?'}')),
    ...transfers.map((t) => TxEntry(t.date, -t.amount,
        '${accounts[t.fromAccountId] ?? '?'} → ${accounts[t.toAccountId] ?? '?'}')),
  ]..sort((a, b) => b.date.compareTo(a.date));
}

/// Flat, sorted list of every transaction in the currently selected month.
/// Backs the List view.
final monthEntriesProvider = FutureProvider.autoDispose<List<TxEntry>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  return _loadMonthEntries(ref, month);
});

/// Entries for one specific calendar day, resolved independently of
/// whichever month is currently selected — needed because the calendar
/// grid can show spillover days from the previous/next month too.
final dayEntriesProvider = FutureProvider.autoDispose.family<List<TxEntry>, DateTime>((ref, date) async {
  final start = DateTime(date.year, date.month, date.day);
  final end = start;

  final expenses = await ref.read(expenseRepositoryProvider).getForDateRange(start, end);
  final incomes = await ref.read(incomeRepositoryProvider).getForDateRange(start, end);
  final transfers = await ref.read(transferRepositoryProvider).getForMonth(MonthKey.fromDate(date).key);
  final dayTransfers = transfers.where((t) =>
      t.date.year == date.year && t.date.month == date.month && t.date.day == date.day).toList();

  final categories = {for (final c in await ref.read(categoryRepositoryProvider).getAll()) c.id: c.name};
  final sources = {for (final s in await ref.read(incomeSourceRepositoryProvider).getAll()) s.id: s.name};
  final accounts = {for (final a in await ref.read(accountRepositoryProvider).getAll()) a.id: a.name};

  return [
    ...expenses.map((e) => TxEntry(e.date, -e.amount,
        '${categories[e.categoryId] ?? '?'} · ${accounts[e.accountId] ?? '?'}')),
    ...incomes.map((i) => TxEntry(i.date, i.amount,
        '${sources[i.sourceId] ?? '?'} · ${accounts[i.accountId] ?? '?'}')),
    ...dayTransfers.map((t) => TxEntry(t.date, -t.amount,
        '${accounts[t.fromAccountId] ?? '?'} → ${accounts[t.toAccountId] ?? '?'}')),
  ]..sort((a, b) => b.date.compareTo(a.date));
});

/// Per-day income/expense totals. Deliberately excludes transfers — moving
/// money between your own accounts isn't income or an expense.
class DayTotals {
  final int income;
  final int expense;
  const DayTotals(this.income, this.expense);
  int get net => income - expense;
  bool get isEmpty => income == 0 && expense == 0;
}

Map<DateTime, DayTotals> _bucketByDate(List expenses, List incomes) {
  final incomeByDate = <DateTime, int>{};
  final expenseByDate = <DateTime, int>{};
  for (final i in incomes) {
    final d = DateTime(i.date.year, i.date.month, i.date.day);
    incomeByDate[d] = (incomeByDate[d] ?? 0) + (i.amount as int);
  }
  for (final e in expenses) {
    final d = DateTime(e.date.year, e.date.month, e.date.day);
    expenseByDate[d] = (expenseByDate[d] ?? 0) + (e.amount as int);
  }
  final days = <DateTime, DayTotals>{};
  for (final d in {...incomeByDate.keys, ...expenseByDate.keys}) {
    days[d] = DayTotals(incomeByDate[d] ?? 0, expenseByDate[d] ?? 0);
  }
  return days;
}

/// Totals for the header summary row — current month only, never includes
/// spillover days from adjacent months.
final monthSummaryTotalsProvider = FutureProvider.autoDispose<Map<DateTime, DayTotals>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final expenses = await ref.read(expenseRepositoryProvider).getForMonth(month.key);
  final incomes = await ref.read(incomeRepositoryProvider).getForMonth(month.key);
  return _bucketByDate(expenses, incomes);
});

/// Totals for the calendar grid. Current month comes from getForMonth();
/// leading/trailing spillover days (the handful shared with adjacent
/// months to complete the grid's first/last week) are fetched as a tight
/// date range instead of pulling entire adjacent months.
final calendarGridTotalsProvider = FutureProvider.autoDispose<Map<DateTime, DayTotals>>((ref) async {
  final month = ref.watch(selectedMonthProvider);

  final leading = month.start.weekday % 7; // Sun=0..Sat=6
  final daysInMonth = month.end.day;
  final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;
  final trailing = totalCells - leading - daysInMonth;

  final expenses = await ref.read(expenseRepositoryProvider).getForMonth(month.key);
  final incomes = await ref.read(incomeRepositoryProvider).getForMonth(month.key);

  if (leading > 0) {
    final leadStart = month.start.subtract(Duration(days: leading));
    final leadEnd = month.start.subtract(const Duration(days: 1));
    expenses.addAll(await ref.read(expenseRepositoryProvider).getForDateRange(leadStart, leadEnd));
    incomes.addAll(await ref.read(incomeRepositoryProvider).getForDateRange(leadStart, leadEnd));
  }

  if (trailing > 0) {
    final trailStart = month.end.add(const Duration(days: 1));
    final trailEnd = month.end.add(Duration(days: trailing));
    expenses.addAll(await ref.read(expenseRepositoryProvider).getForDateRange(trailStart, trailEnd));
    incomes.addAll(await ref.read(incomeRepositoryProvider).getForDateRange(trailStart, trailEnd));
  }

  return _bucketByDate(expenses, incomes);
});