// lib/core/database/migrations.dart

/// Each migration is a numbered, additive step. Never edit an old migration
/// after it's shipped — add a new one. `db_provider.dart` runs these in
/// order based on the device's current schema version.

const List<String> migrationV1 = [
  '''
  CREATE TABLE account_groups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('debit', 'credit')),
    parent_group_id INTEGER REFERENCES account_groups(id),
    depth INTEGER NOT NULL CHECK(depth BETWEEN 1 AND 3),
    sort_order INTEGER NOT NULL DEFAULT 0
  )
  ''',
  '''
  CREATE TABLE accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL CHECK(type IN ('debit', 'credit')),
    group_id INTEGER REFERENCES account_groups(id),
    sort_order INTEGER NOT NULL DEFAULT 0,
    archived INTEGER NOT NULL DEFAULT 0
  )
  ''',
  '''
  CREATE TABLE account_rollovers (
    account_id INTEGER NOT NULL REFERENCES accounts(id),
    month TEXT NOT NULL,           -- "2026-02"
    rollover INTEGER NOT NULL,
    PRIMARY KEY (account_id, month)
  )
  ''',
  '''
  CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    archived INTEGER NOT NULL DEFAULT 0
  )
  ''',
  '''
  CREATE TABLE income_sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    archived INTEGER NOT NULL DEFAULT 0
  )
  ''',
  '''
  CREATE TABLE expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    amount INTEGER NOT NULL,
    note TEXT,
    category_id INTEGER NOT NULL REFERENCES categories(id),
    account_id INTEGER NOT NULL REFERENCES accounts(id)
  )
  ''',
  '''
  CREATE TABLE incomes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    amount INTEGER NOT NULL,
    note TEXT,
    source_id INTEGER NOT NULL REFERENCES income_sources(id),
    account_id INTEGER NOT NULL REFERENCES accounts(id)
  )
  ''',
  '''
  CREATE TABLE transfers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    amount INTEGER NOT NULL,
    fee INTEGER NOT NULL DEFAULT 0,
    note TEXT,
    from_account_id INTEGER NOT NULL REFERENCES accounts(id),
    to_account_id INTEGER NOT NULL REFERENCES accounts(id)
  )
  ''',
  // Indexes for the month-scoped queries every screen runs (dashboard,
  // account detail, summary). Without these, summary_repository gets
  // slow the moment there's a year of daily transactions.
  'CREATE INDEX idx_expenses_date ON expenses(date)',
  'CREATE INDEX idx_expenses_account ON expenses(account_id)',
  'CREATE INDEX idx_incomes_date ON incomes(date)',
  'CREATE INDEX idx_incomes_account ON incomes(account_id)',
  'CREATE INDEX idx_transfers_date ON transfers(date)',
  'CREATE INDEX idx_transfers_from ON transfers(from_account_id)',
  'CREATE INDEX idx_transfers_to ON transfers(to_account_id)',
  // Seed rows — Cash (debit) and Credit (credit) exist on first install.
  "INSERT INTO accounts (name, type, sort_order) VALUES ('Cash', 'debit', 0)",
  "INSERT INTO accounts (name, type, sort_order) VALUES ('Credit', 'credit', 0)",
  // Fees is seeded but the app must never expose a UI path to create an
  // expense with this category — enforced in expense_repository, not here.
  "INSERT INTO categories (name, sort_order) VALUES ('Fees', 0)",
];

/// Add migrationV2, migrationV3, etc. here as the schema evolves.
/// db_provider.dart concatenates whichever are newer than the stored version.
const Map<int, List<String>> migrations = {
  1: migrationV1,
};