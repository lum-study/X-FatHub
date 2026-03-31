import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/step_tracker_model.dart';
import '../../../core/service/pedometer_service.dart';
import '../../../core/database/local_step_db.dart';

/// Repository for Step Tracker data layer
/// Handles all data operations including Supabase and hardware sensors
class StepTrackerRepository {
  final SupabaseClient _supabaseClient;
  static const String _goalsTableName = 'step_tracker_goals';
  static const String _dailyTableName = 'step_tracker_daily';
  static const String _userIdColumn = 'user_id';
  static const String _goalStepsColumn = 'goal_steps';
  static const String _updatedAtColumn = 'updated_at';
  static const String _stepsColumn = 'steps';
  static const String _dateColumn = 'date';
  static const int _defaultGoalSteps = 10000;

  StepTrackerRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// Get the user's daily step goal from local database
  /// Returns [_defaultGoalSteps] (10000) if no goal is set in the database
  Future<int> getGoalSteps() async {
    try {
      return await LocalStepDatabase.getGoalSteps();
    } catch (e) {
      print('Error fetching goal steps from local database: $e');
      return _defaultGoalSteps;
    }
  }

  /// Update the user's daily step goal in local database
  Future<void> setGoalSteps(int goalSteps) async {
    try {
      await LocalStepDatabase.setGoalSteps(goalSteps);
      print('Goal steps updated to $goalSteps in local database');
    } catch (e) {
      print('Error updating goal steps: $e');
      rethrow;
    }
  }

  /// Get current step count from device hardware
  Future<int> getStepCount() async {
    try {
      return await PedometerService.getTodaySteps();
    } catch (e) {
      print('Error getting step count from hardware: $e');
      return 0;
    }
  }

  /// Get today's step count directly from device sensor
  /// Returns the actual number of steps walked today
  Future<int> getTodaySteps() async {
    try {
      return await PedometerService.getTodaySteps();
    } catch (e) {
      print('Error getting today\'s steps: $e');
      return 0;
    }
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
      var dailySteps = await LocalStepDatabase.getSevenDaySteps();
      
      // Validate that we're getting daily values, not cumulative
      // Typical daily steps should be < 100,000 (unrealistic to exceed this in one day)
      for (int i = 0; i < dailySteps.length - 1; i++) { // Check all except today
        if (dailySteps[i] > 100000) {
          print('⚠️ Warning: Suspiciously high step count detected (${dailySteps[i]} on day $i)');
          print('   This may indicate cumulative data. Please verify database integrity.');
        }
      }
      
      // Replace today's data (index 6) with live pedometer data
      final todayStepsLive = await getTodaySteps();
      dailySteps[6] = todayStepsLive;
      
      return dailySteps;
    } catch (e) {
      print('Error fetching 7-day steps: $e');
      return [0, 0, 0, 0, 0, 0, 0];
    }
  }

  /// Save today's steps to local database
  Future<void> saveTodaySteps(int steps) async {
    try {
      await LocalStepDatabase.saveTodaySteps(steps);
      print('Today\'s steps ($steps) saved to local database');
    } catch (e) {
      print('Error saving today\'s steps: $e');
      rethrow;
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
  /// - Background service saves today's final steps to SQLite only at 11:59 PM
  Future<StepTrackerModel> getStepTrackerData() async {
    try {
      // Get today's steps using baseline calculation (real-time from pedometer, not DB)
      final steps = await getTodaySteps();
      final goalSteps = await getGoalSteps();
      final distance = await getDistance();
      final kcal = await calculateKcal(distance);
      final dailySteps = await getSevenDaySteps(); // Last element is today's live data

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
        goalSteps: _defaultGoalSteps,
        distance: 0.0,
        progress: 0.0,
        kcal: 0.0,
        timestamp: DateTime.now(),
        dailySteps: [0, 0, 0, 0, 0, 0, 0],
      );
    }
  }
}
