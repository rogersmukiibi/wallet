// lib/providers/selected_month_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/month.dart';

final selectedMonthProvider = StateProvider<MonthKey>((ref) => MonthKey.fromDate(DateTime.now()));