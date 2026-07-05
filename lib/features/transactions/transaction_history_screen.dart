import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/db_providers.dart';
import '../../providers/selected_month_provider.dart';
import '../../core/utils/currency.dart';

class _Entry {
  final DateTime date;
  final int amount;
  final String label;
  const _Entry(this.date, this.amount, this.label);
}

final _monthEntriesProvider = FutureProvider.autoDispose<List<_Entry>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final expenses = await ref.read(expenseRepositoryProvider).getForMonth(month.key);
  final incomes = await ref.read(incomeRepositoryProvider).getForMonth(month.key);
  final transfers = await ref.read(transferRepositoryProvider).getForMonth(month.key);

  final categories = {for (final c in await ref.read(categoryRepositoryProvider).getAll()) c.id: c.name};
  final sources = {for (final s in await ref.read(incomeSourceRepositoryProvider).getAll()) s.id: s.name};
  final accounts = {for (final a in await ref.read(accountRepositoryProvider).getAll()) a.id: a.name};

  final entries = <_Entry>[
    ...expenses.map((e) => _Entry(e.date, -e.amount,
        '${categories[e.categoryId] ?? '?'} · ${accounts[e.accountId] ?? '?'}')),
    ...incomes.map((i) => _Entry(i.date, i.amount,
        '${sources[i.sourceId] ?? '?'} · ${accounts[i.accountId] ?? '?'}')),
    ...transfers.map((t) => _Entry(t.date, -t.amount,
        '${accounts[t.fromAccountId] ?? '?'} → ${accounts[t.toAccountId] ?? '?'}')),
  ];
  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
});

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final entries = ref.watch(_monthEntriesProvider);

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
      ),
      body: entries.when(
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
              );
            },
          );
        },
      ),
    );
  }
}
