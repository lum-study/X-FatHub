import 'package:pedometer/pedometer.dart' show Pedometer, StepCount;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Service to access pedometer/step sensor data from device hardware
/// Handles baseline calculation to provide "today's steps"
/// Continues tracking even when app is closed via background service
class PedometerService {
  static late Stream<StepCount> _stepCountStream;
  static StreamSubscription<StepCount>? _stepCountSubscription;
  static bool _isInitialized = false;

  static const String _lastSensorValueKey = 'last_sensor_step_count';
  static const String _todayStepsKey = 'today_steps_accumulated';
  static const String _lastUpdateDateKey = 'last_step_update_date';

  /// Initialize the pedometer and set up persistent stream listener
  static Future<bool> initPedometer() async {
    try {
      if (_isInitialized) return true;

      _stepCountStream = Pedometer.stepCountStream;
      
      // Set up persistent stream listener for continuous tracking
      _stepCountSubscription?.cancel();
      _stepCountSubscription = _stepCountStream.listen(
        _handleStepUpdate,
        onError: (error) {
          print('Step stream error: $error');
        },
        cancelOnError: false,
      );

      // Initialize today's data if not already set
      await _initializeTodayData();
      
      _isInitialized = true;
      print('✓ Pedometer initialized successfully');
      return true;
    } catch (e) {
      print('✗ Error initializing pedometer: $e');
      return false;
    }
  }

  /// Initialize today's tracking data
  static Future<void> _initializeTodayData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}";
      final lastDate = prefs.getString(_lastUpdateDateKey) ?? "";

      if (lastDate != todayStr) {
        // New day - reset counters
        await prefs.setString(_lastUpdateDateKey, todayStr);
        await prefs.setInt(_todayStepsKey, 0);
        print('📅 New day detected - step counter reset');
      }
    } catch (e) {
      print('Error initializing today data: $e');
    }
  }

  /// Internal handler for raw sensor updates
  /// Manages:
  /// 1. Daily resets (new day starts at 0)
  /// 2. Device reboots (sensor resets to 0)
  /// 3. Continuous step accumulation
  static void _handleStepUpdate(StepCount event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}";
      
      final lastDate = prefs.getString(_lastUpdateDateKey) ?? "";
      final lastSensorValue = prefs.getInt(_lastSensorValueKey) ?? 0;
      var todaySteps = prefs.getInt(_todayStepsKey) ?? 0;

      // Check if it's a new day
      if (lastDate != todayStr) {
        todaySteps = 0;
        await prefs.setString(_lastUpdateDateKey, todayStr);
        print('📅 New day - steps reset to 0');
      }

      // Calculate difference since last update
      final diff = event.steps - lastSensorValue;
      
      // If positive difference, add to today's total
      // If negative, device likely rebooted - just update baseline
      if (diff > 0) {
        todaySteps += diff;
      }

      // Save current states
      await prefs.setInt(_lastSensorValueKey, event.steps);
      await prefs.setInt(_todayStepsKey, todaySteps);
      
      print('📊 Steps: sensor=${ event.steps}, today=$todaySteps, diff=$diff');
    } catch (e) {
      print('Error handling step update: $e');
    }
  }

  /// Get today's calculated step count
  static Future<int> getTodaySteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check for date reset in case stream hasn't fired yet
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}";
      final lastDate = prefs.getString(_lastUpdateDateKey) ?? "";
      
      if (lastDate != todayStr) {
        await prefs.setString(_lastUpdateDateKey, todayStr);
        await prefs.setInt(_todayStepsKey, 0);
        return 0;
      }
      
      return prefs.getInt(_todayStepsKey) ?? 0;
    } catch (e) {
      print('Error getting today steps: $e');
      return 0;
    }
  }

  /// Get the distance walked (estimated from today's steps)
  static Future<double> getDistance() async {
    try {
      final steps = await getTodaySteps();
      const double strideLength = 0.762; // average meters per step
      return (steps * strideLength) / 1000; // km
    } catch (e) {
      print('Error calculating distance: $e');
      return 0.0;
    }
  }

  /// Check if the step sensor is available
  static Future<bool> isSensorAvailable() async {
    try {
      await Pedometer.stepCountStream
          .first
          .timeout(const Duration(seconds: 2));
      return true;
    } catch (e) {
      print('✗ Step sensor not available: $e');
      return false;
    }
  }

  /// Get the step count stream for real-time updates
  /// Used by UI to listen for immediate step changes
  static Stream<StepCount> stepCountStream() {
    return Pedometer.stepCountStream;
  }

  /// Cleanup resources
  static void dispose() {
    _stepCountSubscription?.cancel();
    _isInitialized = false;
  }

  /// Reset the pedometer to force fresh initialization
  /// Used when user pulls to refresh to get fresh sensor readings
  static Future<void> resetPedometer() async {
    try {
      _stepCountSubscription?.cancel();
      _isInitialized = false;
      print('🔄 Pedometer reset - will reinitialize on next call');
    } catch (e) {
      print('Error resetting pedometer: $e');
    }
  }
}
