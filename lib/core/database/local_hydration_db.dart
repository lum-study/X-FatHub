import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database for hydration tracking
/// Stores daily hydration entries and goals locally
class LocalHydrationDatabase {
  static const String _dbName = 'hydration_tracker.db';
  static const String _tableName = 'hydration_entries';
  static const String _goalsTableName = 'hydration_goals';
  static const int _dbVersion = 1;

  // Column names for hydration_entries table
  static const String colId = 'id';
  static const String colDate = 'date'; // Format: YYYY-MM-DD
  static const String colTime = 'time'; // Format: HH:mm
  static const String colAmount = 'amount'; // in milliliters
  static const String colSynced = 'synced'; // 0 = not synced, 1 = synced
  static const String colCreatedAt = 'created_at';

  // Column names for hydration_goals table
  static const String colGoalId = 'id';
  static const String colGoalMl = 'goal_ml';
  static const String colGoalUpdatedAt = 'updated_at';

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
    // Create hydration_entries table
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

    // Create hydration_goals table
    await db.execute('''
      CREATE TABLE $_goalsTableName (
        $colGoalId INTEGER PRIMARY KEY,
        $colGoalMl INTEGER NOT NULL,
        $colGoalUpdatedAt TEXT NOT NULL
      )
    ''');
    
    // Insert default goal (2000 ml = 2 liters)
    await db.insert(
      _goalsTableName,
      {
        colGoalId: 1,
        colGoalMl: 2000,
        colGoalUpdatedAt: DateTime.now().toIso8601String(),
      },
    );

    print('✓ LocalHydrationDatabase created');
  }

  /// Ensure the hydration_goals table exists (for existing databases that don't have it)
  /// This safely creates the table if it doesn't exist
  static Future<void> _ensureGoalsTableExists() async {
    final db = await getDatabase();
    
    try {
      // Try to get tables list
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_goalsTableName'"
      );
      
      // Table doesn't exist, create it
      if (tables.isEmpty) {
        print('ℹ️ Creating missing hydration_goals table...');
        await db.execute('''
          CREATE TABLE $_goalsTableName (
            $colGoalId INTEGER PRIMARY KEY,
            $colGoalMl INTEGER NOT NULL,
            $colGoalUpdatedAt TEXT NOT NULL
          )
        ''');
        
        // Insert default goal (2000 ml)
        await db.insert(
          _goalsTableName,
          {
            colGoalId: 1,
            colGoalMl: 2000,
            colGoalUpdatedAt: DateTime.now().toIso8601String(),
          },
        );
        print('✓ hydration_goals table created successfully');
      }
    } catch (e) {
      print('Error ensuring goals table exists: $e');
    }
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

  /// Get the user's daily hydration goal from local database
  /// Returns 2000 ml as default if not set
  static Future<int> getGoalMl() async {
    // Ensure the table exists (for existing databases that don't have it)
    await _ensureGoalsTableExists();
    
    final db = await getDatabase();

    try {
      final result = await db.query(
        _goalsTableName,
        where: '$colGoalId = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (result.isEmpty) {
        // Goal not found, return default and save it
        const defaultGoal = 2000;
        await setGoalMl(defaultGoal);
        return defaultGoal;
      }

      return result.first[colGoalMl] as int? ?? 2000;
    } catch (e) {
      print('Error getting goal ml: $e');
      return 2000;
    }
  }

  /// Save the user's daily hydration goal to local database
  static Future<void> setGoalMl(int goalMl) async {
    // Ensure the table exists (for existing databases that don't have it)
    await _ensureGoalsTableExists();
    
    final db = await getDatabase();

    try {
      // Check if goal exists
      final result = await db.query(
        _goalsTableName,
        where: '$colGoalId = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (result.isEmpty) {
        // Insert new goal
        await db.insert(
          _goalsTableName,
          {
            colGoalId: 1,
            colGoalMl: goalMl,
            colGoalUpdatedAt: DateTime.now().toIso8601String(),
          },
        );
        print('✓ Hydration goal saved to local database: $goalMl ml');
      } else {
        // Update existing goal
        await db.update(
          _goalsTableName,
          {
            colGoalMl: goalMl,
            colGoalUpdatedAt: DateTime.now().toIso8601String(),
          },
          where: '$colGoalId = ?',
          whereArgs: [1],
        );
        print('✓ Hydration goal updated in local database: $goalMl ml');
      }
    } catch (e) {
      print('Error saving goal ml: $e');
      rethrow;
    }
  }
}
