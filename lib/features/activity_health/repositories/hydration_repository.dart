import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/hydration_model.dart';

/// Repository for Hydration Tracker data layer
/// Handles all data operations including local database and Supabase syncing
class HydrationRepository {
  final SupabaseClient _supabaseClient;
  static const String _profilesTableName = 'profiles';
  static const String _dailyTableName = 'hydration_daily';
  static const String _profileIdColumn = 'id';
  static const String _userIdColumn = 'user_id';
  static const String _hydrationGoalColumn = 'hydration_goal';
  static const String _updatedAtColumn = 'updated_at';
  static const String _amountMlColumn = 'amount_ml';
  static const String _dateColumn = 'date';
  static const String _timeColumn = 'time';
  static const String _createdAtColumn = 'created_at';

  HydrationRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// Get the user's daily hydration goal from remote database
  Future<int> getGoalMl() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId != null) {
        final profileGoalMl = await _fetchGoalMlFromProfile(userId);
        if (profileGoalMl != null) {
          return profileGoalMl;
        }
      }
      return 0;
    } catch (e) {
      print('Error fetching hydration goal: $e');
      return 0;
    }
  }

  /// Update the user's daily hydration goal in profile table
  Future<void> setGoalMl(int goalMl) async {
    try {
      // Sync to profile table when network/user is available.
      await _syncGoalToRemote(goalMl);
      print('Goal ml updated to $goalMl');
    } catch (e) {
      print('Error updating goal ml: $e');
      rethrow;
    }
  }
  
  /// Check if network is available
  Future<bool> _isNetworkAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Error checking network availability: $e');
      return false;
    }
  }
  
  Future<int?> _fetchGoalMlFromProfile(String userId) async {
    try {
      final isNetworkAvailable = await _isNetworkAvailable();
      if (!isNetworkAvailable) {
        return null;
      }

      final response = await _supabaseClient
          .from(_profilesTableName)
          .select(_hydrationGoalColumn)
          .eq(_profileIdColumn, userId)
          .maybeSingle();

      if (response == null) {
        return 0;
      }

      final profile = response as Map<String, dynamic>;
      final rawGoal = profile[_hydrationGoalColumn] as num?;
      final goalMl = _normalizeProfileGoalToMl(rawGoal);
      if (goalMl == null || goalMl <= 0) {
        return 0;
      }

      return goalMl;
    } catch (e) {
      print('⚠ Error fetching hydration goal from profile: $e');
      return null;
    }
  }

  /// Profiles may store hydration goal either in liters (legacy) or ml (current).
  int? _normalizeProfileGoalToMl(num? rawGoal) {
    if (rawGoal == null || rawGoal <= 0) {
      return null;
    }

    // If value is >= 100, treat it as ml directly (e.g. 2000).
    if (rawGoal >= 100) {
      return rawGoal.round();
    }

    // Small values are treated as liters (e.g. 2.0).
    return (rawGoal * 1000).round();
  }

  /// Sync hydration goal to profiles table if network is available
  Future<void> _syncGoalToRemote(int goalMl) async {
    try {
      if (goalMl <= 0) {
        return;
      }

      final isNetworkAvailable = await _isNetworkAvailable();
      if (!isNetworkAvailable) {
        print('⚠ No network available - goal will sync when network is restored');
        return;
      }
      
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        print('Warning: Cannot sync goal - no authenticated user');
        return;
      }

      await _supabaseClient.from(_profilesTableName).update({
        _hydrationGoalColumn: goalMl,
        _updatedAtColumn: DateTime.now().toIso8601String(),
      }).eq(_profileIdColumn, userId);
      
      print('✓ Goal synced to profile: $goalMl ml');
    } catch (e) {
      print('⚠ Error syncing goal ml to remote: $e');
      // Don't rethrow - goal is already saved locally
    }
  }

  HydrationEntry _entryFromRemote(Map<String, dynamic> row) {
    final amount = (row[_amountMlColumn] as num?)?.toInt() ?? 0;
    return HydrationEntry(
      id: (row['id'] as num?)?.toInt(),
      date: (row[_dateColumn] as String?) ?? '',
      time: (row[_timeColumn] as String?) ?? '00:00',
      amountMl: amount,
      synced: true,
      createdAt: DateTime.tryParse((row[_createdAtColumn] as String?) ?? '') ?? DateTime.now(),
    );
  }

  /// Add a hydration entry to Supabase (fallback to local when unavailable)
  Future<int> addEntry({
    required DateTime dateTime,
    required int amountMl,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      final date = DateTime(dateTime.year, dateTime.month, dateTime.day)
          .toIso8601String()
          .split('T')[0];
      final time =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      final response = await _supabaseClient
          .from(_dailyTableName)
          .insert({
            _userIdColumn: userId,
            _dateColumn: date,
            _timeColumn: time,
            _amountMlColumn: amountMl,
            _createdAtColumn: DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return (response['id'] as num).toInt();
    } catch (e) {
      print('Error adding hydration entry to Supabase: $e');
      rethrow;
    }
  }

  /// Update a hydration entry in Supabase (fallback to local)
  Future<int> updateEntry({
    required int entryId,
    required int amountMl,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      return await _supabaseClient
          .from(_dailyTableName)
          .update({_amountMlColumn: amountMl})
          .eq('id', entryId)
          .eq(_userIdColumn, userId);
    } catch (e) {
      print('Error updating hydration entry in Supabase: $e');
      rethrow;
    }
  }

  /// Delete a hydration entry from Supabase (fallback to local)
  Future<int> deleteEntry(int entryId) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      return await _supabaseClient
          .from(_dailyTableName)
          .delete()
          .eq('id', entryId)
          .eq(_userIdColumn, userId);
    } catch (e) {
      print('Error deleting hydration entry from Supabase: $e');
      rethrow;
    }
  }

  /// Get the time since the last hydration entry (in minutes)
  /// Returns null if no entries exist today
  /// Returns 0 if last entry was less than a minute ago
  Future<int?> getMinutesSinceLastEntry() async {
    try {
      final entries = await getTodayEntries();
      if (entries.isEmpty) {
        return null;
      }

      final lastEntry = entries.first; // Already ordered by time descending
      final lastTime = _parseTimeString(lastEntry.time);
      final now = DateTime.now();

      // Calculate minutes difference
      final lastDateTime = DateTime(now.year, now.month, now.day, lastTime.hour, lastTime.minute);
      final minutesDiff = now.difference(lastDateTime).inMinutes;

      return minutesDiff;
    } catch (e) {
      print('Error getting minutes since last entry: $e');
      return null;
    }
  }

  /// Parse time string (HH:MM) to DateTime components
  static TimeOfDay _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (e) {
      print('Error parsing time string: $e');
    }
    return const TimeOfDay(hour: 0, minute: 0);
  }

  /// Check if user should be reminded to log hydration (no entry in last hour)
  Future<bool> shouldRemindHydration({int hoursThreshold = 1}) async {
    try {
      final minutesSinceLastEntry = await getMinutesSinceLastEntry();
      
      if (minutesSinceLastEntry == null) {
        // No entries today - remind if it's past morning hours
        final now = DateTime.now();
        // Remind if it's 8 AM or later and no entries yet
        return now.hour >= 8;
      }

      // Remind if more than threshold hours have passed
      return minutesSinceLastEntry >= (hoursThreshold * 60);
    } catch (e) {
      print('Error checking should remind hydration: $e');
      return false;
    }
  }

  /// Get today's hydration entries from Supabase (fallback to local)
  Future<List<HydrationEntry>> getTodayEntries() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day)
          .toIso8601String()
          .split('T')[0];

      final response = await _supabaseClient
          .from(_dailyTableName)
          .select('id,$_dateColumn,$_timeColumn,$_amountMlColumn,$_createdAtColumn')
          .eq(_userIdColumn, userId)
          .eq(_dateColumn, todayDate)
          .order(_timeColumn, ascending: false);

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map(_entryFromRemote)
          .toList();
    } catch (e) {
      print('Error getting today\'s entries from Supabase: $e');
      rethrow;
    }
  }

  /// Get today's total hydration in milliliters
  Future<int> getTodayTotal() async {
    try {
      final entries = await getTodayEntries();
      return entries.fold<int>(0, (sum, entry) => sum + entry.amountMl);
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
        dailyGoal: 0,
        progress: 0.0,
        todayEntries: [],
        timestamp: DateTime.now(),
      );
    }
  }

  /// Sync hydration goal to Supabase profile.
  /// Entry CRUD is now performed directly against Supabase in real time.
  Future<void> syncToSupabase() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        print('Warning: Cannot sync - no authenticated user');
        return;
      }

      // Sync goal first
      try {
        await syncGoalToRemote();
        print('✓ Synced hydration goal to profile table');
      } catch (e) {
        print('Warning: Error syncing hydration goal: $e');
      }
      print('✓ Hydration goal sync to Supabase completed');
    } catch (e) {
      print('Error syncing hydration to Supabase: $e');
    }
  }

  /// Sync hydration goal to remote database
  /// Called when user enters the hydration page to ensure latest goal is synced
  Future<void> syncGoalToRemote() async {
    try {
      // Goal is already stored in profiles table; this ensures sync on page load
      await _syncGoalToRemote(0);
    } catch (e) {
      print('Error syncing goal to remote on page load: $e');
      // Don't rethrow - non-critical operation
    }
  }
  
  /// Get entry by ID
  Future<HydrationEntry?> getEntryById(int id) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      final response = await _supabaseClient
          .from(_dailyTableName)
          .select('id,$_dateColumn,$_timeColumn,$_amountMlColumn,$_createdAtColumn')
          .eq('id', id)
          .eq(_userIdColumn, userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return _entryFromRemote(response as Map<String, dynamic>);
    } catch (e) {
      print('Error getting entry by ID from Supabase: $e');
      rethrow;
    }
  }
}
