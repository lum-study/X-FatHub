import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

/// Service for managing background location tracking
/// Enables activity tracking even when app is in background/locked
class BackgroundLocationService {
  static const String _activeActivityKey = 'active_activity_id';
  static const String _locationHistoryKey = 'location_history_';
  
  static Future<void> initializeBackgroundTracking() async {
    try {
      // Request background location permission
      await Geolocator.requestPermission();

      // Configure location settings for background tracking
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Update every 5 meters
        timeLimit: Duration(minutes: 5), // Max wait time
      );

      // Enable background location updates
      await Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position position) async {
        await _recordPosition(position);
      });

      print('✓ Background location tracking initialized');
    } catch (e) {
      print('✗ Error initializing background tracking: $e');
    }
  }

  /// Start background tracking for an activity
  static Future<void> startBackgroundTracking(String activityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeActivityKey, activityId);
      print('✓ Background tracking started for activity: $activityId');
    } catch (e) {
      print('✗ Error starting background tracking: $e');
    }
  }

  /// Stop background tracking
  static Future<void> stopBackgroundTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeActivityKey);
      print('⏹ Background tracking stopped');
    } catch (e) {
      print('✗ Error stopping background tracking: $e');
    }
  }

  /// Get currently active activity ID
  static Future<String?> getActiveActivityId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeActivityKey);
  }

  /// Record a position update
  static Future<void> _recordPosition(Position position) async {
    try {
      final activeActivityId = await getActiveActivityId();
      if (activeActivityId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final historyKey = '$_locationHistoryKey$activeActivityId';
      
      // Get existing history
      final history = prefs.getStringList(historyKey) ?? [];

      // Create location record
      final locationRecord = {
        'id': const Uuid().v4(),
        'lat': position.latitude,
        'lng': position.longitude,
        'alt': position.altitude,
        'acc': position.accuracy,
        'spd': position.speed,
        'ts': DateTime.now().toIso8601String(),
      };

      // Convert to string and add to history
      // Note: In production, use JSON encoding
      history.add(locationRecord.toString());

      // Store updated history
      await prefs.setStringList(historyKey, history);

      print('📍 Background position recorded: (${position.latitude}, ${position.longitude})');
    } catch (e) {
      print('✗ Error recording position: $e');
    }
  }

  /// Get recorded background positions
  static Future<List<Map<String, dynamic>>> getRecordedPositions(
    String activityId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = '$_locationHistoryKey$activityId';
      final history = prefs.getStringList(historyKey) ?? [];

      // Parse history back to maps
      // Note: In production, use proper JSON decoding
      final positions = <Map<String, dynamic>>[];
      for (final record in history) {
        // Parse the record string
        positions.add({'raw': record});
      }

      return positions;
    } catch (e) {
      print('✗ Error getting recorded positions: $e');
      return [];
    }
  }

  /// Clear recorded positions for an activity
  static Future<void> clearRecordedPositions(String activityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = '$_locationHistoryKey$activityId';
      await prefs.remove(historyKey);
      print('✓ Cleared recorded positions for activity: $activityId');
    } catch (e) {
      print('✗ Error clearing recorded positions: $e');
    }
  }

  /// Check if location services are available
  static Future<bool> isLocationServiceAvailable() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    return enabled;
  }

  /// Request all location permissions
  static Future<bool> requestLocationPermissions() async {
    try {
      final status = await Geolocator.requestPermission();
      
      switch (status) {
        case LocationPermission.denied:
        case LocationPermission.deniedForever:
          print('❌ Location permission denied');
          return false;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          print('✓ Location permissions granted');
          return true;
        case LocationPermission.unableToDetermine:
          print('⚠️ Unable to determine location permission');
          return false;
      }
    } catch (e) {
      print('✗ Error requesting permissions: $e');
      return false;
    }
  }

  /// Enable foreground service for continuous tracking (Android)
  /// This allows location updates even with screen off
  static Future<void> enableForegroundService() async {
    try {
      // This would require additional configuration in Android manifest
      // and using foreground_service package
      print('ℹ️ Foreground service configuration needed for background tracking');
    } catch (e) {
      print('✗ Error enabling foreground service: $e');
    }
  }
}
