import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/income_source.dart';
import 'db_providers.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.read(categoryRepositoryProvider).getSelectable();
});

final incomeSourcesProvider = FutureProvider<List<IncomeSource>>((ref) {
  return ref.read(incomeSourceRepositoryProvider).getAll();
});