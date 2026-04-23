import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalBookingDatabase {
  static const String _dbName = 'booking_cache.db';
  static const String _tableName = 'bookings_cache';
  static const int _dbVersion = 2;

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

    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
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

  static Future<void> replaceUpcomingBookings({
    required String userId,
    required List<Map<String, dynamic>> rows,
  }) async {
    final db = await getDatabase();

    await db.transaction((txn) async {
      await txn.delete(
        _tableName,
        where: '$colUserId = ?',
        whereArgs: [userId],
      );

      for (final row in rows) {
        await txn.insert(
          _tableName,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getUpcomingBookingsByUser(
    String userId,
  ) async {
    final db = await getDatabase();
    return db.query(
      _tableName,
      where: '$colUserId = ?',
      whereArgs: [userId],
      orderBy: '$colBookingDate ASC',
    );
  }

  static Future<void> cacheBookings({
    required String userId,
    required List<Map<String, dynamic>> bookings,
  }) async {
    final db = await getDatabase();
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        _tableName,
        where: '$colUserId = ?',
        whereArgs: [userId],
      );

      for (final booking in bookings) {
        final row = {
          colBookingId: booking['id'],
          colUserId: booking['user_id'],
          colPackageId: booking['package_id'],
          colPackageName: booking['package_name'],
          colSlotId: booking['slot_id'],
          colSlotName: booking['slot_name'],
          colSlotLocation: booking['slot_location'],
          colSlotCoach: booking['slot_coach'],
          colSlotStartTime: booking['slot_start_time'],
          colBookingDate: booking['booking_date'],
          colStatus: booking['status'],
          colQrCodeData: booking['qr_code_data'],
          colSessionNumber: booking['session_number'] ?? 1,
          colTotalPaid: booking['total_paid'] ?? 0,
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

  static Future<Map<String, dynamic>?> getCachedBookingById(
    String bookingId,
  ) async {
    final db = await getDatabase();
    final results = await db.query(
      _tableName,
      where: '$colBookingId = ?',
      whereArgs: [bookingId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
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
