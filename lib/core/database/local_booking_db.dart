import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalBookingDatabase {
  static const String _dbName = 'booking_cache.db';
  static const String _tableName = 'bookings_cache';
  static const int _dbVersion = 3;

  static const String colBookingId = 'booking_id';
  static const String colUserId = 'user_id';
  static const String colPackageId = 'package_id';
  static const String colPackageName = 'package_name';
  static const String colSlotId = 'slot_id';
  static const String colSlotName = 'slot_name';
  static const String colSlotLocation = 'slot_location';
  static const String colSlotCoach = 'slot_coach';
  static const String colSlotStartTime = 'slot_start_time';
  static const String colBookingDate = 'booking_date';
  static const String colStatus = 'status';
  static const String colGymName = 'gym_name';
  static const String colGymAddress = 'gym_address';
  static const String colQrCodeData = 'qr_code_data';
  static const String colSessionNumber = 'session_number';
  static const String colTotalPaid = 'total_paid';
  static const String colCachedAt = 'cached_at';

  static Database? _database;

  static Future<Database> getDatabase() async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Logic for upgrading to version 2 if needed
    }
    if (oldVersion < 3) {
      // Add new columns for gym and package metadata
      await db.execute('ALTER TABLE $_tableName ADD COLUMN $colGymName TEXT');
      await db.execute('ALTER TABLE $_tableName ADD COLUMN $colGymAddress TEXT');
      await db.execute('ALTER TABLE $_tableName ADD COLUMN $colPackageName TEXT');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $colBookingId TEXT PRIMARY KEY,
        $colUserId TEXT NOT NULL,
        $colPackageId TEXT NOT NULL,
        $colPackageName TEXT,
        $colSlotId TEXT,
        $colSlotName TEXT,
        $colSlotLocation TEXT,
        $colSlotCoach TEXT,
        $colSlotStartTime TEXT,
        $colBookingDate TEXT NOT NULL,
        $colStatus TEXT NOT NULL,
        $colGymName TEXT,
        $colGymAddress TEXT,
        $colQrCodeData TEXT,
        $colSessionNumber INTEGER NOT NULL DEFAULT 1,
        $colTotalPaid REAL NOT NULL DEFAULT 0,
        $colCachedAt TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_bookings_user_date ON $_tableName($colUserId, $colBookingDate)',
    );
  }

  static Future<void> saveBookings({
    required String userId,
    required List<Map<String, dynamic>> bookings,
  }) async {
    final db = await getDatabase();
    final now = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      // Clear old cache for this user to ensure we have a fresh sync
      await txn.delete(
        _tableName,
        where: '$colUserId = ?',
        whereArgs: [userId],
      );

      for (final booking in bookings) {
        final row = {
          colBookingId: booking['id'] ?? booking[colBookingId],
          colUserId: userId,
          colPackageId: booking['package_id'] ?? booking[colPackageId],
          colPackageName: booking['package_name'] ?? booking[colPackageName],
          colSlotId: booking['slot_id'] ?? booking[colSlotId],
          colSlotName: booking['slot_name'] ?? booking[colSlotName],
          colSlotLocation: booking['slot_location'] ?? booking[colSlotLocation],
          colSlotCoach: booking['slot_coach'] ?? booking[colSlotCoach],
          colSlotStartTime: booking['slot_start_time'] ?? booking[colSlotStartTime],
          colBookingDate: booking['booking_date'] ?? booking[colBookingDate],
          colStatus: booking['status'] ?? booking[colStatus],
          colGymName: booking['gym_name'] ?? booking[colGymName],
          colGymAddress: booking['gym_address'] ?? booking[colGymAddress],
          colQrCodeData: booking['qr_code_data'] ?? booking[colQrCodeData],
          colSessionNumber: booking['session_number'] ?? booking[colSessionNumber] ?? 1,
          colTotalPaid: booking['total_paid'] ?? booking[colTotalPaid] ?? 0,
          colCachedAt: now,
        };
        await txn.insert(
          _tableName,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getCachedBookings(
    String userId,
  ) async {
    final db = await getDatabase();
    return db.query(
      _tableName,
      where: '$colUserId = ?',
      whereArgs: [userId],
      orderBy: '$colBookingDate DESC',
    );
  }

  static Future<void> updateCachedBookingStatus(
    String bookingId,
    String status,
  ) async {
    final db = await getDatabase();
    await db.update(
      _tableName,
      {colStatus: status},
      where: '$colBookingId = ?',
      whereArgs: [bookingId],
    );
  }
}
