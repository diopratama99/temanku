import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Database get db {
    final d = _db;
    if (d == null) {
      throw StateError('Database not initialized');
    }
    return d;
  }

  Future<Database> init() async {
    if (_db != null) return _db!;

    // Desktop (Windows/macOS/Linux) requires sqflite_common_ffi initialization
    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'app.db');

    _db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrate(db, oldVersion, newVersion);
      },
    );

    // Ensure runtime tables/columns similar to Flask app
    await _ensureRuntimeSchema();

    return _db!;
  }

  Future<void> _createSchema(Database db) async {
    // Core schema adapted from schema.sql
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        google_sub TEXT,
        picture TEXT,
        currency TEXT DEFAULT 'IDR'
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT CHECK(type IN ('income','expense')) NOT NULL,
        name TEXT NOT NULL,
        emoji TEXT,
        UNIQUE(user_id, type, name),
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        type TEXT CHECK(type IN ('income','expense')) NOT NULL,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        source_or_payee TEXT,
        account TEXT,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_trx_user_date ON transactions(user_id, date);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_trx_user_type ON transactions(user_id, type);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        amount REAL NOT NULL,
        UNIQUE(user_id, category_id, month),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_auto_transfers (
        user_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (user_id, month),
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        achieved_at TEXT,
        archived_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_allocations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        goal_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (goal_id) REFERENCES savings_goals(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_manual_topups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        transaction_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_consumed (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    ''');

    // Runtime-created tables in Flask
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income','expense')),
        category_id INTEGER NOT NULL,
        amount REAL,
        account TEXT,
        source_or_payee TEXT,
        notes TEXT,
        UNIQUE(user_id, name)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS account_transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        from_account TEXT NOT NULL CHECK(from_account IN ('Transfer','Tunai','E-Wallet')),
        to_account   TEXT NOT NULL CHECK(to_account   IN ('Transfer','Tunai','E-Wallet')),
        amount REAL NOT NULL,
        note TEXT,
        fee_transaction_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    ''');
  }

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    // Basic forward-safe migrations
    // v1 -> v2: add google_sub, picture to users; archived_at to savings_goals; transaction_id to savings_manual_topups; fee_transaction_id to account_transfers
    await db
        .execute('ALTER TABLE users ADD COLUMN google_sub TEXT;')
        .catchError((_) {});
    await db
        .execute('ALTER TABLE users ADD COLUMN picture TEXT;')
        .catchError((_) {});
    await db
        .execute('ALTER TABLE users ADD COLUMN currency TEXT DEFAULT \'IDR\';')
        .catchError((_) {});
    await db
        .execute('ALTER TABLE savings_goals ADD COLUMN archived_at TEXT;')
        .catchError((_) {});
    await db
        .execute(
          'ALTER TABLE savings_manual_topups ADD COLUMN transaction_id INTEGER;',
        )
        .catchError((_) {});
    await db
        .execute(
          'ALTER TABLE account_transfers ADD COLUMN fee_transaction_id INTEGER;',
        )
        .catchError((_) {});
  }

  Future<void> _ensureRuntimeSchema() async {
    // No-op, tables created in _createSchema already
  }

  // Seed default categories for a new user
  static const Map<String, List<String>> _defaults = {
    'income': ['Gaji', 'Bonus', 'Investasi', 'Freelance'],
    'expense': [
      'Makan',
      'Transport',
      'Belanja',
      'Hiburan',
      'Kesehatan',
      'Tagihan',
      'Lainnya',
    ],
  };

  static const Map<String, String> _defaultEmoji = {
    'income:Gaji': '💼',
    'income:Bonus': '🎁',
    'income:Investasi': '📈',
    'income:Freelance': '🧑‍💻',
    'expense:Makan': '🍽️',
    'expense:Transport': '🚌',
    'expense:Belanja': '🛍️',
    'expense:Hiburan': '🎬',
    'expense:Kesehatan': '🩺',
    'expense:Tagihan': '🧾',
    'expense:Lainnya': '📦',
  };

  Future<void> seedDefaultCategories(int userId) async {
    await db.transaction((txn) async {
      final existing = await txn.rawQuery(
        'SELECT COUNT(*) as c FROM categories WHERE user_id=?',
        [userId],
      );
      final count = (existing.first['c'] as int?) ?? 0;
      if (count > 0) return;

      for (final entry in _defaults.entries) {
        final type = entry.key;
        for (final name in entry.value) {
          final emoji = _defaultEmoji['$type:$name'];
          await txn.insert('categories', {
            'user_id': userId,
            'type': type,
            'name': name,
            'emoji': emoji,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    });
  }

  // Helpers for accounts balance similar to Flask logic
  Future<List<Map<String, dynamic>>> accountBalancesAllTime(int userId) async {
    final base = {'Transfer': 0.0, 'Tunai': 0.0, 'E-Wallet': 0.0};

    final trxRows = await db.rawQuery(
      '''
      SELECT account AS acc,
             SUM(CASE WHEN type='income' THEN amount ELSE -amount END) AS saldo
      FROM transactions
      WHERE user_id=? AND account IN ('Transfer','Tunai','E-Wallet')
      GROUP BY account
    ''',
      [userId],
    );
    for (final r in trxRows) {
      final acc = r['acc'] as String?;
      final saldo = (r['saldo'] as num?)?.toDouble() ?? 0.0;
      if (acc != null && base.containsKey(acc)) base[acc] = saldo;
    }

    final incRows = await db.rawQuery(
      '''
      SELECT to_account AS acc, SUM(amount) AS s
      FROM account_transfers WHERE user_id=? GROUP BY to_account
    ''',
      [userId],
    );
    final outRows = await db.rawQuery(
      '''
      SELECT from_account AS acc, SUM(amount) AS s
      FROM account_transfers WHERE user_id=? GROUP BY from_account
    ''',
      [userId],
    );

    for (final r in incRows) {
      final acc = r['acc'] as String?;
      final s = (r['s'] as num?)?.toDouble() ?? 0.0;
      if (acc != null && base.containsKey(acc))
        base[acc] = (base[acc] ?? 0.0) + s;
    }
    for (final r in outRows) {
      final acc = r['acc'] as String?;
      final s = (r['s'] as num?)?.toDouble() ?? 0.0;
      if (acc != null && base.containsKey(acc))
        base[acc] = (base[acc] ?? 0.0) - s;
    }

    String label(String a) =>
        a == 'Transfer' ? 'Rekening' : (a == 'E-Wallet' ? 'E-Wallet' : 'Tunai');

    return base.entries
        .map((e) => {'acc': e.key, 'label': label(e.key), 'saldo': e.value})
        .toList();
  }

  Future<List<Map<String, dynamic>>> accountBalancesByMonth(
    int userId,
    String ym,
  ) async {
    final base = {'Transfer': 0.0, 'Tunai': 0.0, 'E-Wallet': 0.0};

    final trxRows = await db.rawQuery(
      '''
      SELECT account AS acc,
             SUM(CASE WHEN type='income' THEN amount ELSE -amount END) AS saldo
      FROM transactions
      WHERE user_id=? AND account IN ('Transfer','Tunai','E-Wallet')
        AND substr(date,1,7)=?
      GROUP BY account
    ''',
      [userId, ym],
    );
    for (final r in trxRows) {
      final acc = r['acc'] as String?;
      final saldo = (r['saldo'] as num?)?.toDouble() ?? 0.0;
      if (acc != null && base.containsKey(acc)) base[acc] = saldo;
    }

    final incRows = await db.rawQuery(
      '''
      SELECT to_account AS acc, SUM(amount) AS s
      FROM account_transfers WHERE user_id=? AND substr(date,1,7)=?
      GROUP BY to_account
    ''',
      [userId, ym],
    );
    final outRows = await db.rawQuery(
      '''
      SELECT from_account AS acc, SUM(amount) AS s
      FROM account_transfers WHERE user_id=? AND substr(date,1,7)=?
      GROUP BY from_account
    ''',
      [userId, ym],
    );

    for (final r in incRows) {
      final acc = r['acc'] as String?;
      final s = (r['s'] as num?)?.toDouble() ?? 0.0;
      if (acc != null && base.containsKey(acc))
        base[acc] = (base[acc] ?? 0.0) + s;
    }
    for (final r in outRows) {
      final acc = r['acc'] as String?;
      final s = (r['s'] as num?)?.toDouble() ?? 0.0;
      if (acc != null && base.containsKey(acc))
        base[acc] = (base[acc] ?? 0.0) - s;
    }

    String label(String a) =>
        a == 'Transfer' ? 'Rekening' : (a == 'E-Wallet' ? 'E-Wallet' : 'Tunai');

    return base.entries
        .map((e) => {'acc': e.key, 'label': label(e.key), 'saldo': e.value})
        .toList();
  }

  // Dashboard summary: income, expense between dates, top spend category and payee, budgets and latest transactions
  Future<Map<String, dynamic>> dashboardData(
    int userId,
    String startIso,
    String endIso,
  ) async {
    final totals = await db.rawQuery(
      '''
      SELECT
        SUM(CASE WHEN t.type='income'  THEN t.amount ELSE 0 END) AS income,
        SUM(CASE WHEN t.type='expense' THEN t.amount ELSE 0 END) AS expense
      FROM transactions t
      WHERE t.user_id=? AND t.date BETWEEN ? AND ?
    ''',
      [userId, startIso, endIso],
    );
    final t = totals.first;
    final income = (t['income'] as num?)?.toDouble() ?? 0;
    final expense = (t['expense'] as num?)?.toDouble() ?? 0;

    final spend = await db.rawQuery(
      '''
      SELECT c.name AS category, c.emoji, c.id AS category_id, SUM(t.amount) AS total
      FROM transactions t
      JOIN categories c ON c.id=t.category_id
      WHERE t.user_id=? AND t.type='expense' AND t.date BETWEEN ? AND ?
      GROUP BY c.id, c.name, c.emoji
      ORDER BY total DESC
    ''',
      [userId, startIso, endIso],
    );

    final topPayeeRows = await db.rawQuery(
      '''
      SELECT COALESCE(source_or_payee,'(Tidak diisi)') AS payee,
             SUM(amount) AS total, COUNT(*) AS cnt
      FROM transactions
      WHERE user_id=? AND type='expense' AND date BETWEEN ? AND ?
      GROUP BY COALESCE(source_or_payee,'(Tidak diisi)')
      ORDER BY total DESC LIMIT 1
    ''',
      [userId, startIso, endIso],
    );

    final month = startIso.substring(0, 7);
    final budgets = await db.rawQuery(
      '''
      SELECT b.id, c.name AS category, b.amount AS limit_amount,
             COALESCE( (SELECT SUM(amount) FROM transactions
                        WHERE user_id=b.user_id AND type='expense' AND category_id=b.category_id
                          AND substr(date,1,7)=b.month), 0) AS spent
      FROM budgets b
      JOIN categories c ON c.id=b.category_id
      WHERE b.user_id=? AND b.month=?
      ORDER BY c.name
    ''',
      [userId, month],
    );

    final latest = await db.rawQuery(
      '''
      SELECT t.*, COALESCE(c.name,'-') AS category, c.emoji AS category_emoji,
             t.source_or_payee AS keterangan, t.account AS payment_method
      FROM transactions t
      LEFT JOIN categories c ON c.id=t.category_id
      WHERE t.user_id=? AND t.date BETWEEN ? AND ?
      ORDER BY t.date DESC, t.id DESC
      LIMIT 10
    ''',
      [userId, startIso, endIso],
    );

    final goals = await db.rawQuery(
      '''
      SELECT g.id, g.name, g.target_amount,
             COALESCE(SUM(a.amount),0) AS allocated
      FROM savings_goals g
      LEFT JOIN savings_allocations a ON a.goal_id=g.id AND a.user_id=g.user_id
      WHERE g.user_id=? AND g.archived_at IS NULL
      GROUP BY g.id
      ORDER BY g.created_at DESC
      LIMIT 6
    ''',
      [userId],
    );

    return {
      'income': income,
      'expense': expense,
      'net': income - expense,
      'spend_by_cat': spend,
      'top_payee': topPayeeRows.isNotEmpty ? topPayeeRows.first : null,
      'budgets': budgets,
      'latest': latest,
      'active_goals': goals,
    };
  }

  Future<int?> _getExpenseCategoryId(int userId, String name) async {
    final rows = await db.query(
      'categories',
      where: 'user_id=? AND type=? AND name=?',
      whereArgs: [userId, 'expense', name],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return await db.insert('categories', {
      'user_id': userId,
      'type': 'expense',
      'name': name,
    });
  }

  Future<int> _getExpenseCategoryIdTx(
    DatabaseExecutor txn,
    int userId,
    String name,
  ) async {
    final rows = await txn.query(
      'categories',
      where: 'user_id=? AND type=? AND name=?',
      whereArgs: [userId, 'expense', name],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return await txn.insert('categories', {
      'user_id': userId,
      'type': 'expense',
      'name': name,
    });
  }

  Future<void> insertAccountTransferWithFee({
    required int userId,
    required String dateIso,
    required String fromAccount,
    required String toAccount,
    required double amount,
    String? note,
    double adminFee = 0,
  }) async {
    await db.transaction((txn) async {
      int? feeTrxId;
      if (adminFee > 0) {
        final catId = await _getExpenseCategoryIdTx(txn, userId, 'Lainnya');
        feeTrxId = await txn.insert('transactions', {
          'user_id': userId,
          'date': dateIso,
          'type': 'expense',
          'category_id': catId,
          'amount': adminFee,
          'source_or_payee': 'Admin Fee',
          'account': fromAccount,
          'notes': note,
        });
      }

      await txn.insert('account_transfers', {
        'user_id': userId,
        'date': dateIso,
        'from_account': fromAccount,
        'to_account': toAccount,
        'amount': amount,
        'note': note,
        'fee_transaction_id': feeTrxId,
      });
    });
  }
}
