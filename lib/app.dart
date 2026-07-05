import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/accounts/accounts_screen.dart';
import 'features/transactions/transaction_history_screen.dart';
import 'features/transactions/add_transaction_screen.dart';
import 'features/settings/manage_lists_screen.dart';

class RogersTrackerApp extends StatelessWidget {
  const RogersTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rogers Tracker',
      theme: appTheme,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    TransactionHistoryScreen(),
    AccountsScreen(),
    ManageListsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_add_transaction_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Trans.'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Accounts'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
