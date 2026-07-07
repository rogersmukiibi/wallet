# Rogers Tracker

A personal finance tracker for tracking expenses, income, transfers, and account
balances in Ugandan Shillings (UGX). Built to replace a hand-maintained Excel
workbook, as a lightweight Flutter app that works on both phone and PC without
needing an always-on server.

## Why this exists

The original workbook tracked money across mobile money, bank, and investment
accounts, with a strong focus on details most trackers ignore: transfer fees,
loan/credit direction, and rollover balances month to month. This app rebuilds
that logic as a proper data model instead of spreadsheet formulas.

The project went through a few architectural pivots before landing here:
1. FastAPI + SQLite + Docker Compose, synced via Syncthing
2. Cloudflare Pages + Pages Functions + D1, as a PWA
3. **Current**: Flutter (Android + Linux desktop for dev), with local SQLite
   storage — chosen for phone access without needing a server running anywhere.

## Tech stack

- **Framework**: Flutter (Dart)
- **State management**: Riverpod (plain providers/`StateNotifierProvider`, no codegen)
- **Database**: `sqflite` (Android/iOS) + `sqflite_common_ffi` (Linux/Windows/macOS dev)
- **Dev environment**: WSL2 (Ubuntu), VS Code, wireless ADB to a physical Android device

## Data model

### Accounts
Every account is a money bucket with a fixed **type**: `debit` or `credit`.
This is the only hardcoded enum in the schema — it's the one place the balance
math actually diverges in meaning (not formula).

- **debit** — normal balance; positive = money you have.
- **credit** — same formula, but balance direction carries meaning: negative =
  money you owe, positive = money owed to you. No special "loan" fields —
  direction of an ordinary transfer implies borrowing vs. lending vs. repayment.

Accounts can be organized into **groups**, up to 3 levels deep (e.g.
`debit → Banks → ABSA`), purely for dashboard rollups — groups carry no
weight in any formula.

Seeded on first install: `Cash` (debit) and `Credit` (credit).

### Categories & Income Sources
Flat, user-managed lists (add/archive via the UI, no hardcoded values besides
the protected `Fees` category).

`Fees` is seeded but **never directly enterable** — its value is always the
sum of transfer fees for a period, enforced at the repository layer
(`CategoryRepository.getSelectable()` excludes it from anywhere a user can
pick a category).

### Transactions
Three kinds, each its own table:
- **Expense** — date, amount, category, account
- **Income** — date, amount, source, account
- **Transfer** — date, amount, fee, from-account, to-account

### Balance formula
```

current_balance = rollover + earned − spent

earned = income into this account this month
       + transfers INTO this account this month

spent  = expenses from this account this month
       + transfers OUT of this account this month
       + fees on outgoing transfers from this account

```

`rollover` is stored per account per month (`account_rollovers` table) rather
than purely computed, so it can be manually corrected without being silently
overwritten by a recalculation. `AccountRepository.carryForward()` writes next
month's rollover from this month's closing balance as an explicit action.

## Project structure

```

lib/
├── app.dart                  # MaterialApp + bottom-nav shell
├── main.dart                 # entrypoint
├── core/
│   ├── database/             # migrations + db_provider (sqflite/FFI init)
│   ├── theme/
│   └── utils/                 # currency formatting, MonthKey helpers
├── models/                   # plain data classes, fromMap/toMap
├── repositories/              # all SQL lives here — nothing else touches the db
├── providers/                 # riverpod wiring (db, accounts, lists, form state)
├── features/
│   ├── accounts/               # balances overview + manage sheet
│   ├── transactions/            # unified add screen (Income/Expense/Transfer tabs)
│   │                             # + monthly history list
│   └── settings/                # manage categories / income sources
└── widgets/                    # shared small widgets

```

## Detailed Project Structure
```
lib/
├── main.dart
│   Entrypoint. Wraps the app in ProviderScope (Riverpod's root) and calls runApp.
│
├── app.dart
│   MaterialApp + HomeShell: the bottom-nav shell (Trans./Accounts/More) and
│   the single global FAB that opens AddTransactionScreen. Only FAB in the app.
│
├── core/
│   ├── database/
│   │   ├── db_provider.dart
│   │   │   Opens the sqflite database. Initializes the FFI backend on
│   │   │   Linux/Windows/macOS (desktop dev), throws a clear error on web
│   │   │   (unsupported). Runs migrations in order on first open or version bump.
│   │   │
│   │   └── migrations.dart
│   │       Numbered, additive CREATE TABLE / CREATE INDEX statements plus seed
│   │       rows (Cash, Credit accounts; Fees category). Never edit an old
│   │       migration — add a new one.
│   │
│   ├── theme/
│   │   └── app_theme.dart
│   │       Single ThemeData — dark mode, color seed, AppBar styling.
│   │
│   └── utils/
│       ├── currency.dart
│       │   formatAmount/formatUgx/parseAmount — the only place that decides
│       │   how UGX numbers are displayed or parsed from user input.
│       │
│       └── month.dart
│           MonthKey class — canonical "2026-02" month identity used
│           everywhere a query is scoped to a month.
│
├── models/
│   ├── account.dart
│   │   Account + AccountGroup + AccountBalance (computed:
│   │   rollover+earned-spent). AccountType enum (debit/credit).
│   │
│   ├── category.dart
│   │   Expense category — id, name, sortOrder, archived.
│   │
│   ├── income_source.dart
│   │   Same shape as Category, separate class for income sources.
│   │
│   ├── expense.dart
│   │   date, amount, categoryId, accountId, note.
│   │
│   ├── income.dart
│   │   date, amount, sourceId, accountId, note.
│   │
│   ├── transfer.dart
│   │   date, amount, fee, fromAccountId, toAccountId.
│   │
│   └── tx_type.dart
│       enum TxType { income, expense, transfer } — drives the unified
│       Add Transaction form.
│
├── repositories/
│   ├── account_repository.dart
│   │   CRUD for accounts. getBalance() computes rollover+earned-spent for one
│   │   account/month; getAllBalances() does it for every account.
│   │   carryForward() writes next month's rollover from this month's closing
│   │   balance as an explicit write.
│   │
│   ├── category_repository.dart
│   │   CRUD for categories. getSelectable() excludes "Fees" — the enforcement
│   │   point for "Fees is never directly enterable."
│   │
│   ├── income_source_repository.dart
│   │   CRUD for income sources.
│   │
│   ├── expense_repository.dart
│   │   create/getForMonth/delete for expenses.
│   │
│   ├── income_repository.dart
│   │   create/getForMonth/delete for income.
│   │
│   └── transfer_repository.dart
│       create/getForMonth/delete for transfers. Source of Fees totals
│       (transfer.fee column).
│
├── providers/
│   ├── db_providers.dart
│   │   databaseProvider (the open db) + a Provider for every repository.
│   │
│   ├── account_providers.dart
│   │   accountsProvider (list) and accountBalancesProvider (balances for the
│   │   selected month).
│   │
│   ├── list_providers.dart
│   │   categoriesProvider (uses getSelectable, so Fees never appears in a
│   │   picker) and incomeSourcesProvider.
│   │
│   ├── selected_month_provider.dart
│   │   StateProvider<MonthKey> — source of truth for which month is
│   │   currently being viewed.
│   │
│   └── transaction_form_providers.dart
│       TransactionFormState (draft data) + TransactionFormNotifier (setters,
│       validation via isValid, and save() which routes to the correct
│       repository based on TxType). autoDispose — draft resets when the Add
│       screen is left.
│
├── features/
│   ├── accounts/
│   │   └── accounts_screen.dart
│   │       Assets/Liabilities/Net totals + flat lists of debit/credit account
│   │       balances. Pencil icon opens a bottom sheet to archive or add
│   │       accounts.
│   │
│   ├── settings/
│   │   └── manage_lists_screen.dart
│   │       Two-tab screen (Categories / Income) for adding and archiving
│   │       those flat lists.
│   │
│   └── transactions/
│       ├── add_transaction_screen.dart
│       │   Unified Income/Expense/Transfer form with segmented type selector
│       │   and conditional fields. Reads/writes transactionFormProvider.
│       │
│       └── transaction_history_screen.dart
│           Month-scoped merged list of expenses/incomes/transfers, sorted by
│           date, with prev/next month navigation.
│
└── widgets/
    └── currency_text.dart
        Reusable Text wrapper that applies formatUgx.
```

## Development setup (WSL2 + Android)

Known-tricky bits, resolved once and documented so they don't get re-debugged:

- **Java**: needs OpenJDK 17 (`JAVA_HOME` set explicitly).
- **Android SDK**: use a standalone `~/Android/cmdline-tools` install, not the
  Ubuntu system package at `/usr/lib/android-sdk` — having both installed
  causes Gradle and `flutter doctor` to disagree about which SDK is active.
  `android/local.properties` (`sdk.dir=...`) is what Gradle actually reads,
  regardless of your shell's `ANDROID_HOME`.
- **PATH ordering**: prepend `$ANDROID_HOME/cmdline-tools/latest/bin` rather
  than appending — Ubuntu ships an unrelated Python package also called
  `sdkmanager`, which wins if Android's tools come later in `PATH`.
- **sqflite on desktop/web**: plain `sqflite` only has a real implementation
  on Android/iOS. Desktop needs `sqflite_common_ffi`; web isn't supported at
  all without a separate WASM package (out of scope — phone is the real
  target).
- **Wireless ADB**: Android 11+ pairs over Wi-Fi with no cable
  (`adb pair`/`adb connect`). WSL2 needs mirrored networking mode
  (`networkingMode=mirrored` in `.wslconfig`, Windows 11 22H2+) to reach a
  phone on the same LAN.

### Running

```

flutter run -d <device-id>      # pick the Pixel 8 (or other) from `flutter devices`

```

Hot reload (`r`) works for most UI changes. Use hot **restart** (`R`) after
changing widget tree structure (adding/removing a `FloatingActionButton`,
changing provider wiring) — hot reload doesn't always re-bind closures
correctly across structural changes.

## Current status: MVP

Working end-to-end:
- Add/archive accounts (debit or credit), see live balances
- Add/archive categories and income sources
- Log expenses, income, and transfers via one unified form
- Monthly transaction history list
- Balances update correctly from logged transactions

Deliberately deferred (removed from the file tree until the core loop was
proven, to be rebuilt incrementally):
- Dashboard (planned vs. actual, pie charts, progress bars)
- Budget screen
- Account grouping UI (schema supports it; no UI yet)
- Account detail screen (drill into a single account's history)
- Rollover carry-forward UI (repository method exists, no button yet)

## Known gotchas for future work

- Every `FloatingActionButton` needs an explicit, unique `heroTag` — Flutter's
  default tag collides if two are ever mounted at once (e.g. adjacent tabs in
  a `TabBarView`, which builds neighboring tabs eagerly).
- Bottom sheets and dialogs opened from within another bottom sheet need to
  carry the **calling screen's** `context`/`ref` through for anything that
  runs after the sheet closes — the sheet's own `context`/`ref` becomes
  invalid the instant it's popped.
- Import paths are relative to each file's own location — a file two folders
  under `lib/` needs `../../` to reach `lib/models/`, not `../`.