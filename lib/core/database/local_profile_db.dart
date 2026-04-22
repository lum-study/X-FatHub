import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalProfileDatabase {
  static const String _dbName = 'profile.db';
  static const String _tableName = 'profiles';
  static const int _dbVersion = 1;

  static const String colId = 'id';
  static const String colEmail = 'email';
  static const String colName = 'name';
  static const String colBio = 'bio';
  static const String colProfilePictureUrl = 'profile_picture_url';
  static const String colAge = 'age';
  static const String colHeight = 'height';
  static const String colCurrentWeight = 'current_weight';
  static const String colInitialWeight = 'initial_weight';
  static const String colWeightGoal = 'weight_goal';
  static const String colStepsGoal = 'step_goal';
  static const String colHydrationGoal = 'hydration_goal';
  static const String colSynced = 'synced';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  static Database? _database;

  static Future<Database> getDatabase() async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $colId TEXT PRIMARY KEY,
        $colEmail TEXT NOT NULL,
        $colName TEXT,
        $colBio TEXT,
        $colProfilePictureUrl TEXT,
        $colAge INTEGER,
        $colHeight REAL,
        $colCurrentWeight REAL,
        $colInitialWeight REAL,
        $colWeightGoal REAL,
        $colStepsGoal INTEGER,
        $colHydrationGoal REAL,
        $colSynced INTEGER DEFAULT 1,
        $colCreatedAt TEXT,
        $colUpdatedAt TEXT
      )
    ''');
  }

  static Future<void> saveProfile(Map<String, dynamic> profile, {bool synced = true}) async {
    final db = await getDatabase();
    final data = Map<String, dynamic>.from(profile);
    data[colSynced] = synced ? 1 : 0;
    data[colUpdatedAt] = DateTime.now().toIso8601String();
    
    await db.insert(
      _tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    final db = await getDatabase();
    final results = await db.query(
      _tableName,
      where: '$colId = ?',
      whereArgs: [userId],
    );
    
    if (results.isEmpty) return null;
    return results.first;
  }

  static Future<void> updateSyncStatus(String userId, bool synced) async {
    final db = await getDatabase();
    await db.update(
      _tableName,
      {colSynced: synced ? 1 : 0},
      where: '$colId = ?',
      whereArgs: [userId],
    );
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedProfiles() async {
    final db = await getDatabase();
    return await db.query(
      _tableName,
      where: '$colSynced = ?',
      whereArgs: [0],
    );
  }

  static Future<void> deleteProfile(String userId) async {
    final db = await getDatabase();
    await db.delete(
      _tableName,
      where: '$colId = ?',
      whereArgs: [userId],
    );
  }
}