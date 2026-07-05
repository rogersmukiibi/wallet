import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import 'db_providers.dart';
import 'selected_month_provider.dart';

final accountsProvider = FutureProvider<List<Account>>((ref) {
  return ref.read(accountRepositoryProvider).getAll();
});

final accountBalancesProvider = FutureProvider<List<AccountBalance>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  return ref.read(accountRepositoryProvider).getAllBalances(month);
});