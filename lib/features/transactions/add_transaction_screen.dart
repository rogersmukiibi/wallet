// lib/features/transactions/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tx_type.dart';
import '../../providers/transaction_form_providers.dart';
import '../../providers/account_providers.dart';
import '../../providers/list_providers.dart';

class AddTransactionScreen extends ConsumerWidget {
  const AddTransactionScreen({super.key});

  static const _expenseColor = Color(0xFFFF6B5E);
  static const _incomeColor = Color(0xFF4E9BFF);

  Color _accentFor(TxType t) => switch (t) {
        TxType.expense => _expenseColor,
        TxType.income => _incomeColor,
        TxType.transfer => Colors.white,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(transactionFormProvider);
    final notifier = ref.read(transactionFormProvider.notifier);
    final accent = _accentFor(form.type);

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (form.type) {
          TxType.expense => 'Expense',
          TxType.income => 'Income',
          TxType.transfer => 'Transfer',
        }),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _TypeSelector(selected: form.type, onChanged: notifier.setType),
            const SizedBox(height: 8),
            _DateRow(dateTime: form.dateTime, onChanged: notifier.setDateTime),
            _AmountRow(
              amount: form.amount,
              accent: accent,
              onChanged: notifier.setAmount,
              trailing: form.type == TxType.transfer
                  ? TextButton(onPressed: notifier.toggleFee, child: const Text('Fees'))
                  : null,
            ),
            if (form.type == TxType.transfer && form.feeExpanded)
              _FeeRow(fee: form.fee, onChanged: notifier.setFee),
            if (form.type == TxType.expense)
              _PickerRow(
                label: 'Category',
                valueId: form.categoryId,
                nameLookup: (id) => ref.read(categoriesProvider).requireValue
                    .firstWhere((c) => c.id == id).name,
                onTap: () => _showCategoryPicker(context, ref, notifier),
              ),
            if (form.type == TxType.income)
              _PickerRow(
                label: 'Category',
                valueId: form.sourceId,
                nameLookup: (id) => ref.read(incomeSourcesProvider).requireValue
                    .firstWhere((s) => s.id == id).name,
                onTap: () => _showSourcePicker(context, ref, notifier),
              ),
            if (form.type != TxType.transfer)
              _PickerRow(
                label: 'Account',
                valueId: form.accountId,
                nameLookup: (id) => ref.read(accountsProvider).requireValue
                    .firstWhere((a) => a.id == id).name,
                onTap: () => _showAccountPicker(context, ref, (id) => notifier.setAccount(id)),
              ),
            if (form.type == TxType.transfer)
              _TransferAccountsRow(
                fromId: form.accountId,
                toId: form.toAccountId,
                onFromTap: () => _showAccountPicker(context, ref, (id) => notifier.setAccount(id)),
                onToTap: () => _showAccountPicker(context, ref, (id) => notifier.setToAccount(id)),
                onSwap: notifier.swapFromTo,
              ),
            _NoteRow(note: form.note, onChanged: notifier.setNote),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      onPressed: form.isValid
                          ? () async {
                              await notifier.save();
                              if (context.mounted) Navigator.pop(context);
                            }
                          : null,
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: form.isValid ? () => notifier.save() : null,
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountPicker(BuildContext context, WidgetRef ref, void Function(int id) onPicked) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final accounts = ref.watch(accountsProvider);
          return accounts.when(
            data: (list) => GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              children: list.map((a) => InkWell(
                onTap: () {
                  onPicked(a.id!);
                  Navigator.pop(context);
                },
                child: Center(child: Text(a.name)),
              )).toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
          );
        },
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, WidgetRef ref, TransactionFormNotifier notifier) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final categories = ref.watch(categoriesProvider);
          return categories.when(
            data: (list) => GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              children: list.map((c) => InkWell(
                onTap: () {
                  notifier.setCategory(c.id!);
                  Navigator.pop(context);
                },
                child: Center(child: Text(c.name)),
              )).toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
          );
        },
      ),
    );
  }

  void _showSourcePicker(BuildContext context, WidgetRef ref, TransactionFormNotifier notifier) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final sources = ref.watch(incomeSourcesProvider);
          return sources.when(
            data: (list) => GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              children: list.map((s) => InkWell(
                onTap: () {
                  notifier.setSource(s.id!);
                  Navigator.pop(context);
                },
                child: Center(child: Text(s.name)),
              )).toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
          );
        },
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final TxType selected;
  final void Function(TxType) onChanged;
  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: TxType.values.map((t) {
          final isSelected = t == selected;
          final color = switch (t) {
            TxType.income => const Color(0xFF4E9BFF),
            TxType.expense => const Color(0xFFFF6B5E),
            TxType.transfer => Colors.white,
          };
          final label = switch (t) {
            TxType.income => 'Income',
            TxType.expense => 'Expense',
            TxType.transfer => 'Transfer',
          };
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isSelected ? color : Colors.transparent),
                  foregroundColor: isSelected ? color : Colors.grey,
                ),
                onPressed: () => onChanged(t),
                child: Text(label),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final DateTime dateTime;
  final void Function(DateTime) onChanged;
  const _DateRow({required this.dateTime, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Date'),
      trailing: Text(
        '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}  '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: dateTime,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (date == null) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(dateTime),
        );
        onChanged(DateTime(
          date.year, date.month, date.day,
          time?.hour ?? dateTime.hour, time?.minute ?? dateTime.minute,
        ));
      },
    );
  }
}

class _AmountRow extends StatelessWidget {
  final int? amount;
  final Color accent;
  final void Function(int?) onChanged;
  final Widget? trailing;
  const _AmountRow({required this.amount, required this.accent, required this.onChanged, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Amount'),
      trailing: trailing,
      subtitle: TextFormField(
        initialValue: amount?.toString() ?? '',
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          prefixText: 'UGX ',
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent)),
        ),
        onChanged: (v) => onChanged(int.tryParse(v.replaceAll(',', ''))),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final int? fee;
  final void Function(int?) onChanged;
  const _FeeRow({required this.fee, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Fees'),
      subtitle: TextFormField(
        initialValue: fee?.toString() ?? '',
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(prefixText: 'UGX '),
        onChanged: (v) => onChanged(int.tryParse(v.replaceAll(',', ''))),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String label;
  final int? valueId;
  final String Function(int) nameLookup;
  final VoidCallback onTap;
  const _PickerRow({required this.label, required this.valueId, required this.nameLookup, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(valueId != null ? nameLookup(valueId!) : ''),
      onTap: onTap,
    );
  }
}

class _TransferAccountsRow extends StatelessWidget {
  final int? fromId;
  final int? toId;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onSwap;
  const _TransferAccountsRow({
    required this.fromId, required this.toId,
    required this.onFromTap, required this.onToTap, required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('From'),
          trailing: IconButton(icon: const Icon(Icons.swap_vert), onPressed: onSwap),
          onTap: onFromTap,
        ),
        ListTile(title: const Text('To'), onTap: onToTap),
      ],
    );
  }
}

class _NoteRow extends StatelessWidget {
  final String note;
  final void Function(String) onChanged;
  const _NoteRow({required this.note, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        initialValue: note,
        decoration: const InputDecoration(hintText: 'Description'),
        onChanged: onChanged,
      ),
    );
  }
}
