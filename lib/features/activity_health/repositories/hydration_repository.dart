import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hydration_model.dart';
import '../../../core/database/local_hydration_db.dart';

/// Repository for Hydration Tracker data layer
/// Handles all data operations including local database and Supabase syncing
class HydrationRepository {
  final SupabaseClient _supabaseClient;
  static const String _goalsTableName = 'hydration_goals';
  static const String _dailyTableName = 'hydration_daily';
  static const String _userIdColumn = 'user_id';
  static const String _goalMlColumn = 'goal_ml';
  static const String _updatedAtColumn = 'updated_at';
  static const String _amountMlColumn = 'amount_ml';
  static const String _dateColumn = 'date';
  static const int _defaultGoalMl = 2000; // 2 liters

  HydrationRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// Get the user's daily hydration goal from local database
  /// Returns [_defaultGoalMl] (2000ml) if no goal is set
  Future<int> getGoalMl() async {
    try {
      return await LocalHydrationDatabase.getGoalMl();
    } catch (e) {
      print('Error fetching goal ml from local database: $e');
      return _defaultGoalMl;
    }
  }

  /// Update the user's daily hydration goal in local database
  Future<void> setGoalMl(int goalMl) async {
    try {
      await LocalHydrationDatabase.setGoalMl(goalMl);
      print('Goal ml updated to $goalMl in local database');
    } catch (e) {
      print('Error updating goal ml: $e');
      rethrow;
    }
  }

  /// Add a hydration entry to local database
  Future<int> addEntry({
    required DateTime dateTime,
    required int amountMl,
  }) async {
    try {
      return await LocalHydrationDatabase.addEntry(dateTime: dateTime, amountMl: amountMl);
    } catch (e) {
      print('Error adding hydration entry: $e');
      rethrow;
    }
  }

  /// Update a hydration entry
  Future<int> updateEntry({
    required int entryId,
    required int amountMl,
  }) async {
    try {
      return await LocalHydrationDatabase.updateEntry(id: entryId, amountMl: amountMl);
    } catch (e) {
      print('Error updating hydration entry: $e');
      rethrow;
    }
  }

  /// Delete a hydration entry from local database
  Future<int> deleteEntry(int entryId) async {
    try {
      return await LocalHydrationDatabase.deleteEntry(entryId);
    } catch (e) {
      print('Error deleting hydration entry: $e');
      rethrow;
    }
  }

  /// Get today's hydration entries from local database
  Future<List<HydrationEntry>> getTodayEntries() async {
    try {
      final entries = await LocalHydrationDatabase.getTodayEntries();
      return entries.map((e) => HydrationEntry.fromDb(e)).toList();
    } catch (e) {
      print('Error getting today\'s entries: $e');
      return [];
    }
  }

  /// Get today's total hydration in milliliters
  Future<int> getTodayTotal() async {
    try {
      return await LocalHydrationDatabase.getTodayTotal();
    } catch (e) {
      print('Error getting today\'s total: $e');
      return 0;
    }
  }

  /// Get complete hydration tracker data for today
  Future<HydrationTrackerModel> getHydrationTrackerData() async {
    try {
      final goalMl = await getGoalMl();
      final todayEntries = await getTodayEntries();
      final todayTotal = await getTodayTotal();
      
      final progress = goalMl > 0 ? (todayTotal / goalMl).clamp(0.0, 1.0) : 0.0;

      return HydrationTrackerModel(
        todayConsumption: todayTotal,
        dailyGoal: goalMl,
        progress: progress,
        todayEntries: todayEntries,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error getting hydration tracker data: $e');
      return HydrationTrackerModel(
        todayConsumption: 0,
        dailyGoal: _defaultGoalMl,
        progress: 0.0,
        todayEntries: [],
        timestamp: DateTime.now(),
      );
    }
  }

  /// Sync hydration data to Supabase
  /// Syncs both unsynced entries and the current goal
  Future<void> syncToSupabase() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        print('Warning: Cannot sync - no authenticated user');
        return;
      }

      // Sync goal first
      try {
        final goalMl = await LocalHydrationDatabase.getGoalMl();
        await _supabaseClient.from(_goalsTableName).upsert({
          _userIdColumn: userId,
          _goalMlColumn: goalMl,
          _updatedAtColumn: DateTime.now().toIso8601String(),
        }, onConflict: _userIdColumn);
        print('✓ Synced hydration goal to Supabase: $goalMl ml');
      } catch (e) {
        print('Warning: Error syncing hydration goal: $e');
      }

      // Then sync entries
      final unsyncedEntries = await LocalHydrationDatabase.getUnsyncedEntries();
      
      if (unsyncedEntries.isEmpty) {
        print('ℹ️ No unsynced hydration entries to sync');
        return;
      }

      for (final entry in unsyncedEntries) {
        try {
          await _supabaseClient.from(_dailyTableName).insert({
            _userIdColumn: userId,
            'date': entry['date'],
            'time': entry['time'],
            _amountMlColumn: entry['amount'],
            'created_at': entry['created_at'],
          });

          await LocalHydrationDatabase.markAsSynced(entry['id'] as int);
          print('✓ Synced hydration entry to Supabase');
        } catch (e) {
          print('Error syncing individual entry: $e');
        }
      }

      print('✓ Hydration sync to Supabase completed');
    } catch (e) {
      print('Error syncing hydration to Supabase: $e');
    }
  }

  /// Get entry by ID
  Future<HydrationEntry?> getEntryById(int id) async {
    try {
      final entry = await LocalHydrationDatabase.getEntryById(id);
      return entry != null ? HydrationEntry.fromDb(entry) : null;
    } catch (e) {
      print('Error getting entry by ID: $e');
      return null;
    }
  }
}
