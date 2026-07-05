import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database/db_provider.dart';
import '../repositories/account_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/income_source_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/income_repository.dart';
import '../repositories/transfer_repository.dart';

final databaseProvider = FutureProvider<Database>((ref) => DbProvider.instance());

final accountRepositoryProvider = Provider((ref) => AccountRepository(ref));
final categoryRepositoryProvider = Provider((ref) => CategoryRepository(ref));
final incomeSourceRepositoryProvider = Provider((ref) => IncomeSourceRepository(ref));
final expenseRepositoryProvider = Provider((ref) => ExpenseRepository(ref));
final incomeRepositoryProvider = Provider((ref) => IncomeRepository(ref));
final transferRepositoryProvider = Provider((ref) => TransferRepository(ref));