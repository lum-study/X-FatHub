import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database for step tracking
/// Stores daily step count and goal steps locally
class LocalStepDatabase {
  static const String _dbName = 'step_tracker.db';
  static const String _tableName = 'daily_steps';
  static const String _goalsTableName = 'step_goals';
  static const int _dbVersion = 1;

  // Column names for daily_steps table
  static const String colId = 'id';
  static const String colDate = 'date'; // Format: YYYY-MM-DD
  static const String colSteps = 'steps';
  static const String colSynced = 'synced'; // 0 = not synced, 1 = synced
  static const String colCreatedAt = 'created_at';

  // Column names for step_goals table
  static const String colGoalId = 'id';
  static const String colGoalSteps = 'goal_steps';
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
    // Create daily_steps table
    await db.execute('''
      CREATE TABLE $_tableName (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colDate TEXT UNIQUE NOT NULL,
        $colSteps INTEGER NOT NULL,
        $colSynced INTEGER DEFAULT 0,
        $colCreatedAt TEXT NOT NULL
      )
    ''');

    // Create step_goals table
    await db.execute('''
      CREATE TABLE $_goalsTableName (
        $colGoalId INTEGER PRIMARY KEY,
        $colGoalSteps INTEGER NOT NULL,
        $colGoalUpdatedAt TEXT NOT NULL
      )
    ''');
    
    // Insert default goal
    await db.insert(
      _goalsTableName,
      {
        colGoalId: 1,
        colGoalSteps: 10000,
        colGoalUpdatedAt: DateTime.now().toIso8601String(),
      },
    );

    print('✓ LocalStepDatabase created');
  }

  /// Ensure the step_goals table exists (for existing databases that don't have it)
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
        print('ℹ️ Creating missing step_goals table...');
        await db.execute('''
          CREATE TABLE $_goalsTableName (
            $colGoalId INTEGER PRIMARY KEY,
            $colGoalSteps INTEGER NOT NULL,
            $colGoalUpdatedAt TEXT NOT NULL
          )
        ''');
        
        // Insert default goal
        await db.insert(
          _goalsTableName,
          {
            colGoalId: 1,
            colGoalSteps: 10000,
            colGoalUpdatedAt: DateTime.now().toIso8601String(),
          },
        );
        print('✓ step_goals table created successfully');
      }
    } catch (e) {
      print('Error ensuring goals table exists: $e');
    }
  }

  /// Save today's steps to local database
  static Future<int> saveTodaySteps(int steps) async {
    final db = await getDatabase();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day).toIso8601String().split('T')[0];

    try {
      return await db.insert(
        _tableName,
        {
          colDate: todayDate,
          colSteps: steps,
          colSynced: 0,
          colCreatedAt: DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error saving today\'s steps: $e');
      return -1;
    }
  }

  /// Get today's steps from local database
  static Future<int?> getTodaySteps() async {
    final db = await getDatabase();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day).toIso8601String().split('T')[0];

    try {
      final result = await db.query(
        _tableName,
        where: '$colDate = ?',
        whereArgs: [todayDate],
      );

      if (result.isEmpty) {
        return null;
      }

      return result.first[colSteps] as int?;
    } catch (e) {
      print('Error getting today\'s steps: $e');
      return null;
    }
  }

  /// Get steps for a specific date
  static Future<int?> getStepsByDate(DateTime date) async {
    final db = await getDatabase();
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];

    try {
      final result = await db.query(
        _tableName,
        where: '$colDate = ?',
        whereArgs: [dateStr],
      );

      if (result.isEmpty) {
        return null;
      }

      return result.first[colSteps] as int?;
    } catch (e) {
      print('Error getting steps for date: $e');
      return null;
    }
  }

  /// Get last 7 days of steps
  static Future<List<int>> getSevenDaySteps() async {
    final db = await getDatabase();
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final sevenDaysAgoStr = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day)
        .toIso8601String()
        .split('T')[0];

    try {
      final result = await db.query(
        _tableName,
        where: '$colDate >= ?',
        whereArgs: [sevenDaysAgoStr],
        orderBy: '$colDate ASC',
      );

      // Fill missing days with 0
      final today = DateTime.now();
      final List<int> sevenDays = List.filled(7, 0);

      // Map results to days of week
      for (var entry in result) {
        final entryDate = DateTime.parse(entry[colDate] as String);
        final daysAgo = today.difference(entryDate).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          sevenDays[6 - daysAgo] = entry[colSteps] as int? ?? 0;
        }
      }

      return sevenDays;
    } catch (e) {
      print('Error getting 7-day steps: $e');
      return [0, 0, 0, 0, 0, 0, 0];
    }
  }

  /// Get all unsynced records (older than 7 days)
  static Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final db = await getDatabase();
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final sevenDaysAgoStr = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day)
        .toIso8601String()
        .split('T')[0];

    try {
      return await db.query(
        _tableName,
        where: '$colDate <= ? AND $colSynced = 0',
        whereArgs: [sevenDaysAgoStr],
        orderBy: '$colDate ASC',
      );
    } catch (e) {
      print('Error getting unsynced records: $e');
      return [];
    }
  }

  /// Mark record as synced
  static Future<int> markAsSynced(String date) async {
    final db = await getDatabase();

    try {
      return await db.update(
        _tableName,
        {colSynced: 1},
        where: '$colDate = ?',
        whereArgs: [date],
      );
    } catch (e) {
      print('Error marking record as synced: $e');
      return 0;
    }
  }

  /// Get all records in the database (for weekly sync)
  static Future<List<Map<String, dynamic>>> getAllRecords() async {
    final db = await getDatabase();

    try {
      return await db.query(
        _tableName,
        orderBy: '$colDate ASC',
      );
    } catch (e) {
      print('Error getting all records: $e');
      return [];
    }
  }

  /// Delete a specific record by date
  static Future<int> deleteRecordByDate(String date) async {
    final db = await getDatabase();

    try {
      return await db.delete(
        _tableName,
        where: '$colDate = ?',
        whereArgs: [date],
      );
    } catch (e) {
      print('Error deleting record by date: $e');
      return 0;
    }
  }

  /// Delete multiple records by dates
  static Future<int> deleteRecordsByDates(List<String> dates) async {
    final db = await getDatabase();

    try {
      int totalDeleted = 0;
      for (final date in dates) {
        totalDeleted += await deleteRecordByDate(date);
      }
      return totalDeleted;
    } catch (e) {
      print('Error deleting multiple records: $e');
      return 0;
    }
  }

  /// Delete old records (older than 30 days and synced)
  static Future<int> deleteOldRecords() async {
    final db = await getDatabase();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final thirtyDaysAgoStr = DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day)
        .toIso8601String()
        .split('T')[0];

    try {
      return await db.delete(
        _tableName,
        where: '$colDate < ? AND $colSynced = 1',
        whereArgs: [thirtyDaysAgoStr],
      );
    } catch (e) {
      print('Error deleting old records: $e');
      return 0;
    }
  }

  /// Close the database
  static Future<void> close() async {
    final db = await getDatabase();
    await db.close();
  }

  /// Get the user's daily step goal from local database
  /// Returns 10000 as default if not set
  static Future<int> getGoalSteps() async {
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
        const defaultGoal = 10000;
        await setGoalSteps(defaultGoal);
        return defaultGoal;
      }

      return result.first[colGoalSteps] as int? ?? 10000;
    } catch (e) {
      print('Error getting goal steps: $e');
      return 10000;
    }
  }

  /// Save the user's daily step goal to local database
  static Future<void> setGoalSteps(int goalSteps) async {
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
            colGoalSteps: goalSteps,
            colGoalUpdatedAt: DateTime.now().toIso8601String(),
          },
        );
        print('✓ Step goal saved to local database: $goalSteps');
      } else {
        // Update existing goal
        await db.update(
          _goalsTableName,
          {
            colGoalSteps: goalSteps,
            colGoalUpdatedAt: DateTime.now().toIso8601String(),
          },
          where: '$colGoalId = ?',
          whereArgs: [1],
        );
        print('✓ Step goal updated in local database: $goalSteps');
      }
    } catch (e) {
      print('Error saving goal steps: $e');
      rethrow;
    }
  }
}
