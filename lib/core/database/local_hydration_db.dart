import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database for hydration tracking
/// Stores daily hydration entries and syncs to Supabase at 11:59 PM
class LocalHydrationDatabase {
  static const String _dbName = 'hydration_tracker.db';
  static const String _tableName = 'hydration_entries';
  static const int _dbVersion = 1;

  // Column names
  static const String colId = 'id';
  static const String colDate = 'date'; // Format: YYYY-MM-DD
  static const String colTime = 'time'; // Format: HH:mm
  static const String colAmount = 'amount'; // in milliliters
  static const String colSynced = 'synced'; // 0 = not synced, 1 = synced
  static const String colCreatedAt = 'created_at';

  static Database? _database;

  /// Get or initialize the database
  static Future<Database> getDatabase() async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colDate TEXT NOT NULL,
        $colTime TEXT NOT NULL,
        $colAmount INTEGER NOT NULL,
        $colSynced INTEGER DEFAULT 0,
        $colCreatedAt TEXT NOT NULL
      )
    ''');
    print('✓ LocalHydrationDatabase created');
  }

  /// Add a hydration entry
  static Future<int> addEntry({
    required DateTime dateTime,
    required int amountMl,
  }) async {
    final db = await getDatabase();
    final date = dateTime.toIso8601String().split('T')[0];
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    try {
      return await db.insert(
        _tableName,
        {
          colDate: date,
          colTime: time,
          colAmount: amountMl,
          colSynced: 0,
          colCreatedAt: DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error adding hydration entry: $e');
      return -1;
    }
  }

  /// Get today's hydration entries
  static Future<List<Map<String, dynamic>>> getTodayEntries() async {
    final db = await getDatabase();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day).toIso8601String().split('T')[0];

    try {
      final result = await db.query(
        _tableName,
        where: '$colDate = ?',
        whereArgs: [todayDate],
        orderBy: '$colTime DESC',
      );
      return result;
    } catch (e) {
      print('Error getting today\'s entries: $e');
      return [];
    }
  }

  /// Get total hydration for today in milliliters
  static Future<int> getTodayTotal() async {
    final db = await getDatabase();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day).toIso8601String().split('T')[0];

    try {
      final result = await db.rawQuery(
        'SELECT SUM($colAmount) as total FROM $_tableName WHERE $colDate = ?',
        [todayDate],
      );
      
      if (result.isEmpty || result[0]['total'] == null) {
        return 0;
      }
      return (result[0]['total'] as int?) ?? 0;
    } catch (e) {
      print('Error getting today\'s total: $e');
      return 0;
    }
  }

  /// Update an entry
  static Future<int> updateEntry({
    required int id,
    required int amountMl,
  }) async {
    final db = await getDatabase();

    try {
      return await db.update(
        _tableName,
        {colAmount: amountMl},
        where: '$colId = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error updating hydration entry: $e');
      return -1;
    }
  }

  /// Delete an entry
  static Future<int> deleteEntry(int id) async {
    final db = await getDatabase();

    try {
      return await db.delete(
        _tableName,
        where: '$colId = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting hydration entry: $e');
      return -1;
    }
  }

  /// Get entry by ID
  static Future<Map<String, dynamic>?> getEntryById(int id) async {
    final db = await getDatabase();

    try {
      final result = await db.query(
        _tableName,
        where: '$colId = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        return null;
      }
      return result.first;
    } catch (e) {
      print('Error getting entry by ID: $e');
      return null;
    }
  }

  /// Get all unsynced entries
  static Future<List<Map<String, dynamic>>> getUnsyncedEntries() async {
    final db = await getDatabase();

    try {
      final result = await db.query(
        _tableName,
        where: '$colSynced = ?',
        whereArgs: [0],
      );
      return result;
    } catch (e) {
      print('Error getting unsynced entries: $e');
      return [];
    }
  }

  /// Mark entry as synced
  static Future<int> markAsSynced(int id) async {
    final db = await getDatabase();

    try {
      return await db.update(
        _tableName,
        {colSynced: 1},
        where: '$colId = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error marking entry as synced: $e');
      return -1;
    }
  }

  /// Get hydration data for a specific date
  static Future<List<Map<String, dynamic>>> getEntriesByDate(DateTime date) async {
    final db = await getDatabase();
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];

    try {
      final result = await db.query(
        _tableName,
        where: '$colDate = ?',
        whereArgs: [dateStr],
        orderBy: '$colTime DESC',
      );
      return result;
    } catch (e) {
      print('Error getting entries by date: $e');
      return [];
    }
  }
}
