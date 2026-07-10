// lib/features/transactions/transaction_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_transaction_screen.dart';
import '../../providers/selected_month_provider.dart';
import '../../providers/transaction_providers.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/month.dart';

enum _ViewMode { list, calendar }

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  _ViewMode _mode = _ViewMode.calendar;

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final entries = ref.watch(monthEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left),
                onPressed: () => ref.read(selectedMonthProvider.notifier).state = month.previous),
            Text(month.label),
            IconButton(icon: const Icon(Icons.chevron_right),
                onPressed: () => ref.read(selectedMonthProvider.notifier).state = month.next),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_mode == _ViewMode.list ? Icons.calendar_month : Icons.view_list),
            tooltip: _mode == _ViewMode.list ? 'Calendar view' : 'List view',
            onPressed: () => setState(() {
              _mode = _mode == _ViewMode.list ? _ViewMode.calendar : _ViewMode.list;
            }),
          ),
        ],
      ),
      body: _mode == _ViewMode.list
          ? entries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                if (list.isEmpty) return const Center(child: Text('No transactions this month'));
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = list[i];
                    final color = e.amount >= 0 ? Colors.blueAccent : Colors.redAccent;
                    return ListTile(
                      title: Text(e.label),
                      subtitle: Text('${e.date.day}/${e.date.month}/${e.date.year}'),
                      trailing: Text(formatUgx(e.amount), style: TextStyle(color: color)),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AddTransactionScreen(editing: e)),
                      ),
                    );
                  },
                );
              },
            )
          : _CalendarView(month: month),
    );
  }
}

class _CalendarView extends ConsumerWidget {
  final MonthKey month;
  const _CalendarView({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryTotals = ref.watch(monthSummaryTotalsProvider);
    final gridTotals = ref.watch(calendarGridTotalsProvider);

    return summaryTotals.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (summaryDays) {
        final monthIncome = summaryDays.values.fold<int>(0, (s, d) => s + d.income);
        final monthExpense = summaryDays.values.fold<int>(0, (s, d) => s + d.expense);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  _SummaryCell('Income', monthIncome, Colors.blueAccent),
                  _SummaryCell('Expenses', monthExpense, Colors.redAccent),
                  _SummaryCell('Total', monthIncome - monthExpense, Colors.white),
                ],
              ),
            ),
            const _WeekdayHeader(),
            const Divider(height: 1),
            Expanded(
              child: gridTotals.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (gridDays) => _buildGrid(context, gridDays),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, Map<DateTime, DayTotals> gridDays) {
    final daysInMonth = month.end.day;
    final leading = month.start.weekday % 7;
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;
    final gridStart = month.start.subtract(Duration(days: leading));

    return GridView.builder(
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final date = gridStart.add(Duration(days: index));
        final isCurrentMonth = date.month == month.month && date.year == month.year;
        final totals = gridDays[DateTime(date.year, date.month, date.day)];
        return _DayCell(
          date: date,
          totals: totals,
          dimmed: !isCurrentMonth,
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => _DayDetailScreen(date: date))),
        );
      },
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();
  static const _labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) => Row(
        children: _labels
            .map((l) => Expanded(
                  child: Center(
                    child: Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ))
            .toList(),
      );
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final DayTotals? totals;
  final bool dimmed;
  final VoidCallback onTap;
  const _DayCell({
    required this.date,
    required this.totals,
    required this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final dayNumberColor = dimmed ? Colors.grey.shade700 : Colors.white;
    final opacity = dimmed ? 0.5 : 1.0;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 4,
              child: Text('${date.day}', style: TextStyle(fontSize: 12, color: dayNumberColor)),
            ),
            if (totals != null && !totals!.isEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: opacity,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (totals!.income > 0)
                            Text(formatAmount(totals!.income),
                                style: const TextStyle(fontSize: 10, color: Colors.blueAccent),
                                overflow: TextOverflow.ellipsis),
                          if (totals!.expense > 0)
                            Text(formatAmount(totals!.expense),
                                style: const TextStyle(fontSize: 10, color: Colors.redAccent),
                                overflow: TextOverflow.ellipsis),
                          Text(formatAmount(totals!.net),
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SummaryCell(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(formatUgx(value), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _DayDetailScreen extends ConsumerWidget {
  final DateTime date;
  const _DayDetailScreen({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(dayEntriesProvider(date));
    return Scaffold(
      appBar: AppBar(title: Text('${date.day}/${date.month}/${date.year}')),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('No transactions on this day'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = list[i];
              final color = e.amount >= 0 ? Colors.blueAccent : Colors.redAccent;
              return ListTile(
                title: Text(e.label),
                trailing: Text(formatUgx(e.amount), style: TextStyle(color: color)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddTransactionScreen(editing: e)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}