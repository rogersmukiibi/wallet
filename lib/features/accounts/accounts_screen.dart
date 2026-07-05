import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/account.dart';
import '../../providers/account_providers.dart';
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