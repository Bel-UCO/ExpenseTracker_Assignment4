import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';

class TransactionDatabase {
  static final TransactionDatabase instance = TransactionDatabase._init();
  static Database? _database;

  TransactionDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabel kategori
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // Tabel user
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // Tabel transaksi
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories(id),
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    // Tambah kategori default
    await db.insert('categories', {'name': 'Salary'});
    await db.insert('categories', {'name': 'Shopping'});
    await db.insert('categories', {'name': 'Transportation'});
  }

  // ========================
  // CATEGORY OPERATIONS
  // ========================

  Future<int> createCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================
  // USER OPERATIONS
  // ========================

  Future<int> createUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<List<UserModel>> readAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    return result.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<int> updateUser(UserModel user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================
  // TRANSACTION OPERATIONS
  // ========================

  // Tambah transaksi
  Future<int> createTransaction(TransactionModel txn) async {
    final db = await instance.database;
    return await db.insert('transactions', txn.toMap());
  }

  Future<Map<String, double>> getSummaryByUser(int userId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
    SELECT 
      SUM(CASE WHEN type = 'Income' THEN amount ELSE 0 END) AS totalIncome,
      SUM(CASE WHEN type = 'Expense' THEN amount ELSE 0 END) AS totalExpense
    FROM transactions
    WHERE userId = ?
  ''', [userId]);

    final row = result.first;

    final income = (row['totalIncome'] ?? 0);
    final expense = (row['totalExpense'] ?? 0);

    // Konversi aman ke double
    return {
      'income': income is int ? income.toDouble() : income as double,
      'expense': expense is int ? expense.toDouble() : expense as double,
    };
  }

  // Ambil semua transaksi milik user tertentu
  Future<List<TransactionModel>> readTransactionsByUser(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<int> updateTransaction(TransactionModel txn) async {
    final db = await instance.database;
    return db.update(
      'transactions',
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================
  // CLOSE DATABASE
  // ========================

  Future<void> debugPrintAllTransactions() async {
    final db = await instance.database;
    final rows = await db.query('transactions');
    print("=== ALL TRANSACTIONS ===");
    for (var row in rows) {
      print(row);
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
