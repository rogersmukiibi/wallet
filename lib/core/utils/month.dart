// lib/core/utils/month.dart

/// Canonical month identity used everywhere a query is scoped to "this month":
/// dashboard totals, account earned/spent, rollover lookups, budget planning.
/// Always derive this key rather than formatting dates ad hoc, or a screen
/// that builds "2026-2" instead of "2026-02" will silently miss rows.
class MonthKey {
  final int year;
  final int month; // 1-12

  const MonthKey(this.year, this.month);

  factory MonthKey.fromDate(DateTime date) => MonthKey(date.year, date.month);

  factory MonthKey.parse(String key) {
    final parts = key.split('-');
    return MonthKey(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// "2026-02" — stable, sortable, used as the DB key and route argument.
  String get key => '$year-${month.toString().padLeft(2, '0')}';

  DateTime get start => DateTime(year, month, 1);
  DateTime get end => DateTime(year, month + 1, 1).subtract(const Duration(days: 1));

  MonthKey get previous => month == 1 ? MonthKey(year - 1, 12) : MonthKey(year, month - 1);
  MonthKey get next => month == 12 ? MonthKey(year + 1, 1) : MonthKey(year, month + 1);

  /// "Feb 2026" — for headers/pickers.
  String get label {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${names[month - 1]} $year';
  }

  @override
  bool operator ==(Object other) => other is MonthKey && other.year == year && other.month == month;
  @override
  int get hashCode => Object.hash(year, month);
  @override
  String toString() => key;
}