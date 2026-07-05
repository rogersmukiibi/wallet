import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/account.dart';
import '../../providers/account_providers.dart';
import '../../providers/db_providers.dart';
import '../../core/utils/currency.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(accountBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: balances.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final debit = list.where((b) => b.account.type == AccountType.debit).toList();
          final credit = list.where((b) => b.account.type == AccountType.credit).toList();
          final assetsTotal = debit.fold<int>(0, (s, b) => s + b.current);
          final liabilitiesTotal = credit.fold<int>(0, (s, b) => s + b.current);

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _Totals('Assets', assetsTotal, Colors.blueAccent),
                    _Totals('Liabilities', liabilitiesTotal, Colors.redAccent),
                    _Totals('Net', assetsTotal + liabilitiesTotal, Colors.white),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (debit.isEmpty && credit.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No accounts yet — tap + to add one')),
                ),
              ...debit.map((b) => ListTile(
                    title: Text(b.account.name),
                    trailing: Text(formatUgx(b.current)),
                  )),
              const Divider(height: 1),
              ...credit.map((b) => ListTile(
                    title: Text(b.account.name),
                    trailing: Text(formatUgx(b.current), style: const TextStyle(color: Colors.redAccent)),
                  )),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'accounts_add_fab',
        onPressed: () => _showAddAccountDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    AccountType type = AccountType.debit;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              SegmentedButton<AccountType>(
                segments: const [
                  ButtonSegment(value: AccountType.debit, label: Text('Debit')),
                  ButtonSegment(value: AccountType.credit, label: Text('Credit')),
                ],
                selected: {type},
                onSelectionChanged: (s) => setState(() => type = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                await ref.read(accountRepositoryProvider).create(
                      Account(name: controller.text.trim(), type: type),
                    );
                ref.invalidate(accountsProvider);
                ref.invalidate(accountBalancesProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Totals(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(formatUgx(value), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}
