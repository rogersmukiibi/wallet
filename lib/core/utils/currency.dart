// lib/core/utils/currency.dart
import 'package:intl/intl.dart'; // add intl to pubspec.yaml if not present

/// UGX has no minor unit in this app — every amount is a whole integer shilling.
/// This file is the single place that decides how numbers look on screen.

final _formatter = NumberFormat.decimalPattern('en_US');

/// "1234567" -> "1,234,567"
String formatAmount(int amount) => _formatter.format(amount);

/// "1234567" -> "UGX 1,234,567"  (negative -> "-UGX 1,234,567", not "UGX -1,234,567")
String formatUgx(int amount) {
  final sign = amount < 0 ? '-' : '';
  return '${sign}UGX ${_formatter.format(amount.abs())}';
}

/// Strips thousands separators typed by the user before parsing.
/// Returns null on empty/invalid input rather than throwing — callers
/// (form fields) treat null as "not yet a valid amount".
int? parseAmount(String input) {
  final cleaned = input.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return null;
  return int.tryParse(cleaned);
}