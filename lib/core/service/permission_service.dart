import 'package:permission_handler/permission_handler.dart';
import 'location_tracking_service.dart';

class PermissionService {
  /// Request notification permission for Android 13+
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();

    if (status.isDenied) {
      print('⚠️ Notification permission denied');
      return false;
    } else if (status.isPermanentlyDenied) {
      print('🔔 Notification permission permanently denied. Opening app settings...');
      openAppSettings();
      return false;
    }

    print('✓ Notification permission granted');
    return true;
  }

  /// Check if notification permission is already granted
  static Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request activity recognition permission for step counting
  static Future<bool> requestActivityPermission() async {
    final status = await Permission.activityRecognition.request();

    if (status.isDenied) {
      print('Activity recognition permission denied');
      return false;
    } else if (status.isPermanentlyDenied) {
      print('Activity recognition permission permanently denied. Opening app settings...');
      openAppSettings();
      return false;
    }

    print('Activity recognition permission granted');
    return true;
  }

  /// Check if activity recognition permission is already granted
  static Future<bool> hasActivityPermission() async {
    final status = await Permission.activityRecognition.status;
    return status.isGranted;
  }

  /// Request all required permissions for step tracking
  static Future<bool> requestStepTrackerPermissions() async {
    final isGranted = await requestActivityPermission();
    return isGranted;
  }

  /// Request location permission for activity tracking
  static Future<bool> requestActivityTrackingPermissions() async {
    final hasLocationPermission = await LocationTrackingService.requestLocationPermissions();
    if (!hasLocationPermission) {
      print('Location permission required for activity tracking');
      return false;
    }

    // Also request activity recognition if available
    await requestActivityPermission();
    
    return true;
  }

  /// Check if all activity tracking permissions are granted
  static Future<bool> hasActivityTrackingPermissions() async {
    final hasLocation = await LocationTrackingService.hasLocationPermission();
    return hasLocation;
  }
}