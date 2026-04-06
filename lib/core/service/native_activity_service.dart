import 'package:flutter/services.dart';

/// Service to communicate with native Android foreground service
/// Enables background activity tracking when screen is locked
class NativeActivityService {
  static const String _channel = 'com.example.xfathub/activity_tracking';
  static const platform = MethodChannel(_channel);

  /// Start the foreground service for activity tracking
  /// This keeps the location updates alive even when the screen is locked
  static Future<bool> startTracking(String activityId) async {
    try {
      final result = await platform.invokeMethod<bool>(
        'startActivityTracking',
        {'activityId': activityId},
      );
      print('✓ Native foreground service started for activity: $activityId');
      return result ?? false;
    } catch (e) {
      print('⚠️ Could not start native foreground service: $e');
      return false;
    }
  }

  /// Stop the foreground service
  static Future<bool> stopTracking() async {
    try {
      final result = await platform.invokeMethod<bool>(
        'stopActivityTracking',
      );
      print('✓ Native foreground service stopped');
      return result ?? false;
    } catch (e) {
      print('⚠️ Could not stop native foreground service: $e');
      return false;
    }
  }
}
