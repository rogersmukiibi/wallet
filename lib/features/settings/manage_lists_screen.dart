import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/list_providers.dart';
import '../../providers/db_providers.dart';

class ManageListsScreen extends ConsumerWidget {
  const ManageListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('More'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Categories'),
            Tab(text: 'Income'),
          ]),
        ),
        body: TabBarView(children: [_CategoriesTab(), _IncomeSourcesTab()]),
      ),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              const Expanded(child: Text('Expense categories', style: TextStyle(color: Colors.grey))),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Add category',
                onPressed: () => _showAddDialog(context, ref),
              ),
            ],
          ),
        ),
        Expanded(
          child: categories.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (list) => ListView(
              children: list.map((c) => ListTile(
                    title: Text(c.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.archive_outlined),
                      tooltip: 'Archive',
                      onPressed: () async {
                        await ref.read(categoryRepositoryProvider).archive(c.id!);
                        ref.invalidate(categoriesProvider);
                      },
                    ),
                  )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await ref.read(categoryRepositoryProvider).create(controller.text.trim());
              ref.invalidate(categoriesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _IncomeSourcesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(incomeSourcesProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              const Expanded(child: Text('Income sources', style: TextStyle(color: Colors.grey))),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Add income source',
                onPressed: () => _showAddDialog(context, ref),
              ),
            ],
          ),
        ),
        Expanded(
          child: sources.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (list) => ListView(
              children: list.map((s) => ListTile(
                    title: Text(s.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.archive_outlined),
                      tooltip: 'Archive',
                      onPressed: () async {
                        await ref.read(incomeSourceRepositoryProvider).archive(s.id!);
                        ref.invalidate(incomeSourcesProvider);
                      },
                    ),
                  )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Income Source'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await ref.read(incomeSourceRepositoryProvider).create(controller.text.trim());
              ref.invalidate(incomeSourcesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
