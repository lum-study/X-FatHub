import 'package:permission_handler/permission_handler.dart';

class PermissionService {
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
}