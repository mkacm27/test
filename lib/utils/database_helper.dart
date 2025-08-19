import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

import '../models/transaction.dart';

class DatabaseHelper {
  static const _databaseName = "PrintingTransactions.db";
  static const _databaseVersion = 1;

  static const table = 'transactions_table';

  // Column names
  static const columnId = 'id';
  static const columnTransactionDate = 'transactionDate';
  static const columnClassName = 'className';
  static const columnInstructorName = 'instructorName';
  static const columnPaperCopies = 'paperCopies';
  static const columnPrintingType = 'printingType';
  static const columnTotalCost = 'totalCost';
  static const columnPaidAmount = 'paidAmount';
  static const columnPaymentStatus = 'paymentStatus';

  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  // This opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnTransactionDate TEXT NOT NULL,
            $columnClassName TEXT NOT NULL,
            $columnInstructorName TEXT NOT NULL,
            $columnPaperCopies INTEGER NOT NULL,
            $columnPrintingType TEXT NOT NULL,
            $columnTotalCost REAL NOT NULL,
            $columnPaidAmount REAL NOT NULL,
            $columnPaymentStatus TEXT NOT NULL
          )
          ''');
  }

  // --- CRUD Methods ---

  Future<int> insert(Transaction transaction) async {
    Database db = await instance.database;
    // `toMap()` is a method on the Transaction model to convert it to a map
    return await db.insert(table, transaction.toMap());
  }

  Future<List<Transaction>> getAllTransactions() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: '$columnTransactionDate DESC');
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<int> update(Transaction transaction) async {
    Database db = await instance.database;
    int id = transaction.id!;
    return await db.update(table, transaction.toMap(),
        where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  // --- Query and Filter Methods ---

  Future<List<Transaction>> queryTransactions({
    String keyword = '',
    String? instructor,
    String? className,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Database db = await instance.database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (keyword.isNotEmpty) {
      // Search by instructor, class, or even ID if it's a number
      String numericKeyword = keyword.replaceAll(RegExp(r'[^0-9]'), '');
      if (numericKeyword.isNotEmpty) {
         whereClauses.add('($columnInstructorName LIKE ? OR $columnClassName LIKE ? OR $columnId = ?)');
         whereArgs.addAll(['%$keyword%', '%$keyword%', int.parse(numericKeyword)]);
      } else {
         whereClauses.add('($columnInstructorName LIKE ? OR $columnClassName LIKE ?)');
         whereArgs.addAll(['%$keyword%', '%$keyword%']);
      }
    }
    if (instructor != null && instructor.isNotEmpty) {
      whereClauses.add('$columnInstructorName = ?');
      whereArgs.add(instructor);
    }
    if (className != null && className.isNotEmpty) {
      whereClauses.add('$columnClassName = ?');
      whereArgs.add(className);
    }
    if (startDate != null) {
      whereClauses.add('$columnTransactionDate >= ?');
      whereArgs.add(startDate.toIso8601String().split('T').first); // Use yyyy-MM-dd format
    }
    if (endDate != null) {
      // Add one day to the end date to include all transactions on that day
      DateTime inclusiveEndDate = DateTime(endDate.year, endDate.month, endDate.day + 1);
      whereClauses.add('$columnTransactionDate < ?');
      whereArgs.add(inclusiveEndDate.toIso8601String().split('T').first);
    }

    String? whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: '$columnTransactionDate DESC',
    );

    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }
}
