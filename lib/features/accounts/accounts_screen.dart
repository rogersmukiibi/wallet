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
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Manage accounts',
            // Pass THIS screen's context/ref through — these stay alive
            // for as long as AccountsScreen itself is on screen.
            onPressed: () => _showManageSheet(context, ref),
          ),
        ],
      ),
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
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first account'),
                      onPressed: () => _showManageSheet(context, ref),
                    ),
                  ),
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
    );
  }

  // screenContext/screenRef = AccountsScreen's own — safe to use even
  // after the bottom sheet below has been popped and disposed.
  void _showManageSheet(BuildContext screenContext, WidgetRef screenRef) {
    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (consumerContext, consumerRef, _) {
          final accounts = consumerRef.watch(accountsProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Manage accounts', style: Theme.of(consumerContext).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  accounts.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (list) => Column(
                      children: list.map((a) => ListTile(
                            title: Text(a.name),
                            subtitle: Text(a.type.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.archive_outlined),
                              tooltip: 'Archive',
                              // Safe: sheet is still open, consumerRef is alive here.
                              onPressed: () async {
                                await consumerRef.read(accountRepositoryProvider).archive(a.id!);
                                consumerRef.invalidate(accountsProvider);
                                consumerRef.invalidate(accountBalancesProvider);
                              },
                            ),
                          )).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add account'),
                    onPressed: () {
                      Navigator.pop(sheetContext); // close using the SHEET's own context
                      _showAddAccountDialog(screenContext, screenRef); // reopen using the SCREEN's
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    AccountType type = AccountType.debit;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
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
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                await ref.read(accountRepositoryProvider).create(
                      Account(name: controller.text.trim(), type: type),
                    );
                ref.invalidate(accountsProvider);
                ref.invalidate(accountBalancesProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
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
