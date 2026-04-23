import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/step_tracker_model.dart';
import '../../../core/service/pedometer_service.dart';

/// Repository for Step Tracker data layer
/// Handles all data operations including Supabase and hardware sensors
class StepTrackerRepository {
  final SupabaseClient _supabaseClient;
  static const String _profilesTableName = 'profiles';
  static const String _dailyTableName = 'step_tracker_daily';
  static const String _profileIdColumn = 'id';
  static const String _userIdColumn = 'user_id';
  static const String _stepGoalColumn = 'step_goal';
  static const String _updatedAtColumn = 'updated_at';
  static const String _stepsColumn = 'steps';
  static const String _dateColumn = 'date';
  static const String _createdAtColumn = 'created_at';
  DateTime? _lastRemoteTodaySyncAt;

  StepTrackerRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// Get the user's daily step goal from remote database
  Future<int> getGoalSteps() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId != null) {
        final profileGoal = await _fetchGoalStepsFromProfile(userId);
        if (profileGoal != null) {
          return profileGoal;
        }
      }
      return 0;
    } catch (e) {
      print('Error fetching goal steps: $e');
      return 0;
    }
  }

  /// Update the user's daily step goal
  Future<void> setGoalSteps(int goalSteps) async {
    try {
      // Try to sync to remote if network is available
      await _syncGoalToRemote(goalSteps);
      print('Goal steps updated to $goalSteps');
    } catch (e) {
      print('Error updating goal steps: $e');
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

  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  Future<void> _upsertTodayStepsRemote({
    required String userId,
    required String date,
    required int steps,
  }) async {
    // First, check if record already exists
    final existingRecord = await _supabaseClient
        .from(_dailyTableName)
        .select(_createdAtColumn)
        .eq(_userIdColumn, userId)
        .eq(_dateColumn, date)
        .maybeSingle();

    final now = DateTime.now().toIso8601String();
    
    if (existingRecord != null) {
      // Record exists - only update steps and updated_at, preserve created_at
      await _supabaseClient.from(_dailyTableName).update({
        _stepsColumn: steps,
        _updatedAtColumn: now,
      }).eq(_userIdColumn, userId).eq(_dateColumn, date);
    } else {
      // New record - set both created_at and updated_at
      await _supabaseClient.from(_dailyTableName).insert({
        _userIdColumn: userId,
        _dateColumn: date,
        _stepsColumn: steps,
        _createdAtColumn: now,
        _updatedAtColumn: now,
      });
    }
  }

  Future<void> _syncTodayStepsIfNeeded(int steps) async {
    if (steps < 0) {
      return;
    }

    final now = DateTime.now();
    if (_lastRemoteTodaySyncAt != null &&
        now.difference(_lastRemoteTodaySyncAt!).inSeconds < 30) {
      return;
    }

    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    final isNetworkAvailable = await _isNetworkAvailable();
    if (!isNetworkAvailable) {
      return;
    }

    final todayDate =
        DateTime(now.year, now.month, now.day).toIso8601String().split('T')[0];
    await _upsertTodayStepsRemote(userId: userId, date: todayDate, steps: steps);
    _lastRemoteTodaySyncAt = now;
  }
  
  Future<int?> _fetchGoalStepsFromProfile(String userId) async {
    try {
      final isNetworkAvailable = await _isNetworkAvailable();
      if (!isNetworkAvailable) {
        return null;
      }

      final response = await _supabaseClient
          .from(_profilesTableName)
          .select(_stepGoalColumn)
          .eq(_profileIdColumn, userId)
          .maybeSingle();

      if (response == null) {
        return 0;
      }

      final profile = response as Map<String, dynamic>;
      return (profile[_stepGoalColumn] as num?)?.round() ?? 0;
    } catch (e) {
      print('⚠ Error fetching step goal from profile: $e');
      return null;
    }
  }

  /// Sync step goal to profiles table if network is available
  Future<void> _syncGoalToRemote(int goalSteps) async {
    try {
      if (goalSteps <= 0) {
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
        _stepGoalColumn: goalSteps,
        _updatedAtColumn: DateTime.now().toIso8601String(),
      }).eq(_profileIdColumn, userId);
      
      print('✓ Goal steps synced to profile: $goalSteps steps');
    } catch (e) {
      print('⚠ Error syncing goal steps to remote: $e');
      // Don't rethrow - goal is already saved locally
    }
  }

  /// Get current step count from device hardware
  Future<int> getStepCount() async {
    try {
      return await PedometerService.getTodayStepsCalculated(
        refreshFromSensor: false,
      );
    } catch (e) {
      print('Error getting step count from hardware: $e');
      return 0;
    }
  }

  /// Get today's step count: Try Supabase first (remote source of truth), then fall back to pedometer
  /// This ensures we always have data even before pedometer is initialized
  Future<int> getTodaySteps() async {
    try {
      // Try to get today's steps from Supabase first
      final remoteSteps = await getTodayStepsFromRemote();
      if (remoteSteps > 0) {
        return remoteSteps;
      }
      
      // Fall back to pedometer if Supabase doesn't have data or network unavailable
      return await PedometerService.getTodayStepsCalculated(
        refreshFromSensor: false,
      );
    } catch (e) {
      print('Error getting today\'s steps: $e');
      return 0;
    }
  }

  /// Get today's steps directly from Supabase
  Future<int> getTodayStepsFromRemote() async {
    try {
      final userId = _currentUserId;
      if (userId != null) {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day)
            .toIso8601String()
            .split('T')[0];
        
        final response = await _supabaseClient
            .from(_dailyTableName)
            .select(_stepsColumn)
            .eq(_userIdColumn, userId)
            .eq(_dateColumn, todayDate)
            .maybeSingle();
        
        if (response != null) {
          return (response[_stepsColumn] as num?)?.toInt() ?? 0;
        }
      }
    } catch (e) {
      print('⚠ Error fetching today\'s steps from Supabase: $e');
    }
    return 0;
  }

  /// Get distance walked in kilometers
  Future<double> getDistance() async {
    try {
      return await PedometerService.getDistance();
    } catch (e) {
      print('Error getting distance from hardware: $e');
      return 0.0;
    }
  }

  /// Get user's body weight from Supabase user metadata
  /// Returns default 50kg if unable to retrieve from Supabase
  Future<double> getBodyWeight() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user?.userMetadata == null) {
        print('Warning: No user metadata found. Using default body weight: 50kg');
        return 50.0;
      }

      // Try to get body weight from user metadata
      final bodyWeight = user?.userMetadata?['body_weight'];
      if (bodyWeight != null) {
        return (bodyWeight is int) ? bodyWeight.toDouble() : bodyWeight as double;
      }

      print('No body weight in metadata. Using default: 50kg');
      return 50.0;
    } catch (e) {
      print('Error fetching body weight: $e. Using default: 50kg');
      return 50.0;
    }
  }

  /// Calculate kcal burned based on distance and body weight
  /// Formula: kcal = distance(km) × bodyWeight(kg) × 0.75
  Future<double> calculateKcal(double distance) async {
    try {
      final bodyWeight = await getBodyWeight();
      final kcal = distance * bodyWeight * 0.75;
      return kcal;
    } catch (e) {
      print('Error calculating kcal: $e');
      return 0.0;
    }
  }

  /// Check if step sensor is available on device
  Future<bool> isSensorAvailable() async {
    try {
      return await PedometerService.isSensorAvailable();
    } catch (e) {
      print('Error checking sensor availability: $e');
      return false;
    }
  }

  /// Get daily steps for the last 7 days from local database
  /// Returns a list of 7 integers representing steps for each day
  /// Last element (today) is replaced with live pedometer data instead of database
  Future<List<int>> getSevenDaySteps() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startDate = today.subtract(const Duration(days: 6));
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final todayDateStr = today.toIso8601String().split('T')[0];

      final response = await _supabaseClient
          .from(_dailyTableName)
          .select('$_dateColumn,$_stepsColumn')
          .eq(_userIdColumn, userId)
          .gte(_dateColumn, startDateStr)
          .lte(_dateColumn, todayDateStr)
          .order(_dateColumn, ascending: true);

      final sevenDays = List<int>.filled(7, 0);
      for (final row in (response as List).cast<Map<String, dynamic>>()) {
        final dateString = row[_dateColumn] as String?;
        if (dateString == null) {
          continue;
        }

        final date = DateTime.tryParse(dateString);
        if (date == null) {
          continue;
        }

        final index = date.difference(startDate).inDays;
        if (index >= 0 && index < 7) {
          sevenDays[index] = (row[_stepsColumn] as num?)?.toInt() ?? 0;
        }
      }

      return sevenDays;
    } catch (e) {
      print('Error fetching 7-day steps from Supabase: $e');
      rethrow;
    }
  }

  /// Save today's steps to local database
  Future<void> saveTodaySteps(int steps) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day)
          .toIso8601String()
          .split('T')[0];

      await _upsertTodayStepsRemote(userId: userId, date: todayDate, steps: steps);
      print('Today\'s steps ($steps) saved to Supabase');
    } catch (e) {
      print('Error saving today\'s steps: $e');
      rethrow;
    }
  }

  /// Delete a step record by date from Supabase (fallback to local)
  Future<int> deleteStepRecordByDate(DateTime date) async {
    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];

    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      return await _supabaseClient
          .from(_dailyTableName)
          .delete()
          .eq(_userIdColumn, userId)
          .eq(_dateColumn, dateStr);
    } catch (e) {
      print('Error deleting step record from Supabase: $e');
      rethrow;
    }
  }

  /// Delete ALL step records for the current user from Supabase
  /// This is called when user resets all step data
  Future<void> deleteAllStepRecords() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      await _supabaseClient
          .from(_dailyTableName)
          .delete()
          .eq(_userIdColumn, userId);
      
      print('✓ All step records deleted for user: $userId');
    } catch (e) {
      print('Error deleting all step records from Supabase: $e');
      rethrow;
    }
  }

  /// Sync step goal to remote database
  /// Called when user enters the step tracker page to ensure latest goal is synced
  Future<void> syncGoalToRemote() async {
    try {
      // Goal is already stored in profiles table; this ensures sync on page load
      await _syncGoalToRemote(0);
    } catch (e) {
      print('Error syncing goal to remote on page load: $e');
      // Don't rethrow - non-critical operation
    }
  }
  
  /// Build a complete StepTrackerModel with current data
  /// Combines hardware sensor data with user's goal from Supabase and historical data
  /// 
  /// Key behavior:
  /// - Retrieves TODAY'S STEPS from device using baseline calculation (real-time, not from DB)
  /// - Fetches user's step goal from Supabase
  /// - Gets distance from device sensor
  /// - Calculates kcal burned: distance(km) × bodyWeight(kg) × 0.75
  /// - Retrieves last 6 days from local SQLite + today's live data from pedometer
  /// - Background service saves today's final steps to SQLite only at 8:20 AM
  Future<StepTrackerModel> getStepTrackerData() async {
    try {
      // Get today's steps using baseline calculation (real-time from pedometer, not DB)
      final steps = await getTodaySteps();
      await _syncTodayStepsIfNeeded(steps);
      final goalSteps = await getGoalSteps();
      final distance = await getDistance();
      final kcal = await calculateKcal(distance);
      final dailySteps = await getSevenDaySteps(); // Last element is today's live data

      // Keep today's graph point aligned to latest live sensor value.
      dailySteps[6] = steps;

      // Calculate progress as a percentage (0.0 to 1.0)
      final progress = goalSteps > 0 ? (steps / goalSteps).clamp(0.0, 1.0) : 0.0;

      return StepTrackerModel(
        steps: steps,
        goalSteps: goalSteps,
        distance: distance,
        progress: progress,
        kcal: kcal,
        timestamp: DateTime.now(),
        dailySteps: dailySteps,
      );
    } catch (e) {
      print('Error getting step tracker data: $e');
      // Return a default model with zeros
      return StepTrackerModel(
        steps: 0,
        goalSteps: 0,
        distance: 0.0,
        progress: 0.0,
        kcal: 0.0,
        timestamp: DateTime.now(),
        dailySteps: [0, 0, 0, 0, 0, 0, 0],
      );
    }
  }
}
