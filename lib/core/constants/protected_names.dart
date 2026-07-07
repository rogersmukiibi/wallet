// lib/core/constants/protected_names.dart

/// Central registry of system-managed category/income-source names that
/// must never be manually created, archived, or exposed in a picker.
///
/// Anywhere the app needs to check "is this name protected?", it checks
/// against this file — never a locally re-typed string literal. Adding a
/// new protected row (e.g. a future auto-computed category) means adding
/// one line here, not hunting through every repository.
class ProtectedNames {
  ProtectedNames._();

  /// Protected expense categories — auto-computed, never directly enterable.
  static const Set<String> categories = {
    'Fees',
    'Balance Adjustment',
  };

  /// Protected income sources — auto-computed, never directly enterable.
  static const Set<String> incomeSources = {
    'Balance Adjustment',
  };

  static bool isProtectedCategory(String name) =>
      categories.any((p) => p.toLowerCase() == name.trim().toLowerCase());

  static bool isProtectedIncomeSource(String name) =>
      incomeSources.any((p) => p.toLowerCase() == name.trim().toLowerCase());
}