# rog_tracker

A new Flutter project.

## Project Structure

```text
lib/
├── main.dart
├── app.dart                          # MaterialApp, theme, initial route

├── core/
│   ├── theme/
│   │   └── app_theme.dart            # colors, IBM Plex-style text theme
│   ├── utils/
│   │   ├── currency.dart             # UGX formatting, integer-only parsing
│   │   └── month.dart                # "2026-02" key helpers, month math
│   └── database/
│       ├── db_provider.dart          # sqflite open/init singleton
│       └── migrations.dart           # versioned CREATE TABLE statements

├── models/
│   ├── account.dart                  # id, name, type (liquid/financial/credit)
│   ├── category.dart                 # expense categories (extensible list)
│   ├── income_source.dart            # income sources (extensible list)
│   ├── expense.dart                  # date, amount, description, categoryId, accountId
│   ├── income.dart                   # date, amount, description, sourceId, accountId
│   └── transfer.dart                 # date, amount, fee, description, fromId, toId

├── repositories/                     # all SQL lives here — nothing else touches the db directly
│   ├── account_repository.dart       # CRUD + balance queries
│   ├── category_repository.dart
│   ├── income_source_repository.dart
│   ├── expense_repository.dart
│   ├── income_repository.dart
│   ├── transfer_repository.dart
│   └── summary_repository.dart       # the aggregation logic: monthly totals,
│                                      # category actuals, Fees-from-transfers,
│                                      # rollover carry-forward

├── providers/                        # riverpod providers, one file per concern
│   ├── db_providers.dart
│   ├── selected_month_provider.dart
│   ├── account_providers.dart
│   ├── transaction_providers.dart
│   └── summary_providers.dart

├── features/
│   ├── dashboard/                    # your "Board" sheet, reimagined
│   │   ├── dashboard_screen.dart
│   │   └── widgets/
│   │       ├── month_picker.dart
│   │       ├── progress_bar_card.dart      # planned vs actual vs diff
│   │       └── distribution_pie_chart.dart
│   ├── accounts/
│   │   ├── accounts_screen.dart
│   │   └── account_detail_screen.dart      # rollover/earned/spent/current
│   ├── transactions/
│   │   ├── transaction_history_screen.dart
│   │   ├── add_expense_sheet.dart          # bottom sheet, not full screen
│   │   ├── add_income_sheet.dart
│   │   └── add_transfer_sheet.dart
│   ├── budget/
│   │   └── budget_screen.dart              # planned values per category/source
│   └── settings/
│       └── manage_lists_screen.dart        # add/edit accounts, categories, sources

└── widgets/                           # shared, dumb, reusable
	├── currency_text.dart
	└── account_badge.dart
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
