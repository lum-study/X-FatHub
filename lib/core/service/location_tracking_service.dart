import 'package:geolocator/geolocator.dart';
import 'dart:async';

/// Service for handling real-time GPS location tracking
class LocationTrackingService {
  static StreamSubscription<Position>? _positionStream;
  static bool _isTracking = false;

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permissions
  /// For activity tracking, we need "always" permission to track in background
  static Future<bool> requestLocationPermissions() async {
    final status = await Geolocator.requestPermission();
    
    switch (status) {
      case LocationPermission.denied:
        print('❌ Location permission denied');
        return false;
      case LocationPermission.deniedForever:
        print('❌ Location permission permanently denied');
        return false;
      case LocationPermission.whileInUse:
        print('⚠️ Location permission granted (while in use only) - background tracking limited');
        // Still return true to allow tracking, but note the limitation
        return true;
      case LocationPermission.always:
        print('✓ Location permission granted (always) - full background tracking enabled');
        return true;
      case LocationPermission.unableToDetermine:
        print('⚠️ Unable to determine location permission');
        return false;
    }
  }

  /// Request background location permission explicitly
  /// This is required for continuous tracking when app is in background
  static Future<bool> requestBackgroundLocationPermission() async {
    final status = await Geolocator.requestPermission();
    
    print('📍 Requesting background location permission...');
    if (status == LocationPermission.always) {
      print('✓ Background location permission granted (always)');
      return true;
    } else if (status == LocationPermission.whileInUse) {
      print('⚠️ Only while-in-use permission granted. Background tracking will be limited.');
      return true;
    } else {
      print('❌ Location permission not granted: $status');
      return false;
    }
  }

  /// Check if location permission is already granted
  static Future<bool> hasLocationPermission() async {
    final status = await Geolocator.checkPermission();
    return status == LocationPermission.whileInUse ||
        status == LocationPermission.always;
  }

  /// Get current permission status for diagnostics
  static Future<LocationPermission> getPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission with detailed error handling
  /// Returns the permission status after request
  static Future<LocationPermission> requestLocationPermissionWithStatus() async {
    final status = await Geolocator.requestPermission();
    return status;
  }


  /// Get current location (one-time fetch)
  static Future<Position?> getCurrentLocation() async {
    try {
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        print('❌ Location services are disabled');
        return null;
      }

      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        print('❌ Location permission not granted');
        return null;
      }

      // Get position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  /// Returns a stream of Position updates
  /// [updateInterval] - minimum distance in meters to trigger update (default: 5m)
  /// [accuracy] - desired accuracy level (default: best)
  static Stream<Position> startLocationTracking({
    int updateInterval = 5,
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) {
    print('📍 Starting location tracking (update interval: ${updateInterval}m)');
    _isTracking = true;

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: updateInterval, // Minimum distance in meters
      ),
    ).handleError((error) {
      print('❌ Location tracking error: $error');
      _isTracking = false;
      // Error is re-thrown to allow callers to handle recovery
      throw error;
    });
  }

  /// Stop location tracking
  static Future<void> stopLocationTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    print('⏹ Location tracking stopped');
  }

  /// Check if currently tracking
  static bool get isTracking => _isTracking;

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) /
        1000; // Convert meters to km
  }

  /// Calculate bearing (direction) between two points in degrees
  static double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  /// Get location accuracy description
  static String getAccuracyDescription(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.lowest:
        return 'Lowest (~5000m)';
      case LocationAccuracy.low:
        return 'Low (~500m)';
      case LocationAccuracy.medium:
        return 'Medium (~100m)';
      case LocationAccuracy.high:
        return 'High (~10m)';
      case LocationAccuracy.best:
        return 'Best (~0-5m)';
      case LocationAccuracy.bestForNavigation:
        return 'Best for Navigation (~0-5m)';
      case LocationAccuracy.reduced:
        return 'Reduced (~10-100m)';
    }
  }
}
