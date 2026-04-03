import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database for live activity tracking
/// Stores activities, route points, and session data
class LocalActivityDatabase {
  static const String _dbName = 'activity_tracker.db';
  static const String _activitiesTableName = 'activities';
  static const String _routePointsTableName = 'route_points';
  static const int _dbVersion = 1;

  // Activities table columns
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colActivityType = 'activity_type'; // 'walk', 'run', 'hike'
  static const String colTitle = 'title';
  static const String colDescription = 'description';
  static const String colStartTime = 'start_time';
  static const String colEndTime = 'end_time';
  static const String colTotalDurationSeconds = 'total_duration_seconds';
  static const String colDistanceTraveled = 'distance_traveled'; // in km
  static const String colStartLatitude = 'start_latitude';
  static const String colStartLongitude = 'start_longitude';
  static const String colEndLatitude = 'end_latitude';
  static const String colEndLongitude = 'end_longitude';
  static const String colStepCount = 'step_count';
  static const String colCaloriesBurned = 'calories_burned';
  static const String colAveragePace = 'average_pace'; // km/h
  static const String colMaxSpeed = 'max_speed'; // km/h
  static const String colElevationGain = 'elevation_gain'; // meters
  static const String colStatus = 'status'; // 'active', 'paused', 'completed', 'discarded'
  static const String colSyncedToServer = 'is_synced_to_server';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  // Route points table columns
  static const String colPointId = 'id';
  static const String colActivityId = 'activity_id';
  static const String colLatitude = 'latitude';
  static const String colLongitude = 'longitude';
  static const String colAltitude = 'altitude'; // meters, nullable
  static const String colAccuracy = 'accuracy'; // meters, nullable
  static const String colSpeed = 'speed'; // m/s, nullable
  static const String colPointTimestamp = 'timestamp';
  static const String colSequenceNumber = 'sequence_number';

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
    // Create activities table
    await db.execute('''
      CREATE TABLE $_activitiesTableName (
        $colId TEXT PRIMARY KEY,
        $colUserId TEXT NOT NULL,
        $colActivityType TEXT NOT NULL,
        $colTitle TEXT,
        $colDescription TEXT,
        $colStartTime TEXT NOT NULL,
        $colEndTime TEXT,
        $colTotalDurationSeconds INTEGER,
        $colDistanceTraveled REAL NOT NULL DEFAULT 0.0,
        $colStartLatitude REAL,
        $colStartLongitude REAL,
        $colEndLatitude REAL,
        $colEndLongitude REAL,
        $colStepCount INTEGER NOT NULL DEFAULT 0,
        $colCaloriesBurned REAL NOT NULL DEFAULT 0.0,
        $colAveragePace REAL NOT NULL DEFAULT 0.0,
        $colMaxSpeed REAL,
        $colElevationGain REAL,
        $colStatus TEXT NOT NULL DEFAULT 'notStarted',
        $colSyncedToServer INTEGER DEFAULT 0,
        $colCreatedAt TEXT NOT NULL,
        $colUpdatedAt TEXT
      )
    ''');

    // Create route_points table
    await db.execute('''
      CREATE TABLE $_routePointsTableName (
        $colPointId TEXT PRIMARY KEY,
        $colActivityId TEXT NOT NULL,
        $colLatitude REAL NOT NULL,
        $colLongitude REAL NOT NULL,
        $colAltitude REAL,
        $colAccuracy REAL,
        $colSpeed REAL,
        $colPointTimestamp TEXT NOT NULL,
        $colSequenceNumber INTEGER NOT NULL,
        FOREIGN KEY ($colActivityId) REFERENCES $_activitiesTableName ($colId) ON DELETE CASCADE
      )
    ''');

    // Create index for faster queries
    await db.execute(
        'CREATE INDEX idx_activity_user ON $_activitiesTableName($colUserId)');
    await db.execute(
        'CREATE INDEX idx_route_activity ON $_routePointsTableName($colActivityId)');

    print('✓ LocalActivityDatabase created');
  }

  /// Insert a new activity
  static Future<void> insertActivity(Map<String, dynamic> activityData) async {
    final db = await getDatabase();
    await db.insert(_activitiesTableName, activityData);
  }

  /// Update an activity
  static Future<void> updateActivity(
      String activityId, Map<String, dynamic> updates) async {
    final db = await getDatabase();
    await db.update(
      _activitiesTableName,
      updates,
      where: '$colId = ?',
      whereArgs: [activityId],
    );
  }

  /// Get activity by ID
  static Future<Map<String, dynamic>?> getActivityById(String activityId) async {
    final db = await getDatabase();
    final results = await db.query(
      _activitiesTableName,
      where: '$colId = ?',
      whereArgs: [activityId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get all activities for a user
  static Future<List<Map<String, dynamic>>> getActivitiesByUser(
      String userId) async {
    final db = await getDatabase();
    return await db.query(
      _activitiesTableName,
      where: '$colUserId = ?',
      whereArgs: [userId],
      orderBy: '$colCreatedAt DESC',
    );
  }

  /// Get recent activities (for dashboard/summary)
  static Future<List<Map<String, dynamic>>> getRecentActivities(
      String userId, int limit) async {
    final db = await getDatabase();
    return await db.query(
      _activitiesTableName,
      where: '$colUserId = ? AND $colStatus = ?',
      whereArgs: [userId, 'completed'],
      orderBy: '$colCreatedAt DESC',
      limit: limit,
    );
  }

  /// Delete an activity
  static Future<void> deleteActivity(String activityId) async {
    final db = await getDatabase();
    // Route points will be cascade deleted
    await db.delete(
      _activitiesTableName,
      where: '$colId = ?',
      whereArgs: [activityId],
    );
  }

  /// Insert a route point
  static Future<void> insertRoutePoint(Map<String, dynamic> pointData) async {
    final db = await getDatabase();
    await db.insert(_routePointsTableName, pointData);
  }

  /// Get all route points for an activity
  static Future<List<Map<String, dynamic>>> getRoutePointsByActivity(
      String activityId) async {
    final db = await getDatabase();
    return await db.query(
      _routePointsTableName,
      where: '$colActivityId = ?',
      whereArgs: [activityId],
      orderBy: '$colSequenceNumber ASC',
    );
  }

  /// Get latest route point for an activity (for real-time tracking)
  static Future<Map<String, dynamic>?> getLatestRoutePoint(
      String activityId) async {
    final db = await getDatabase();
    final results = await db.query(
      _routePointsTableName,
      where: '$colActivityId = ?',
      whereArgs: [activityId],
      orderBy: '$colSequenceNumber DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get count of route points (to determine sequence number)
  static Future<int> getRoutePointCount(String activityId) async {
    final db = await getDatabase();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_routePointsTableName WHERE $colActivityId = ?',
      [activityId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete all route points for an activity
  static Future<void> deleteRoutePointsForActivity(String activityId) async {
    final db = await getDatabase();
    await db.delete(
      _routePointsTableName,
      where: '$colActivityId = ?',
      whereArgs: [activityId],
    );
  }

  /// Get unsync activities (for background sync)
  static Future<List<Map<String, dynamic>>> getUnsyncActivities() async {
    final db = await getDatabase();
    return await db.query(
      _activitiesTableName,
      where: '$colSyncedToServer = ?',
      whereArgs: [0],
      orderBy: '$colCreatedAt DESC',
    );
  }

  /// Close the database
  static Future<void> close() async {
    _database?.close();
    _database = null;
  }
}
