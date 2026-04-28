import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';
import 'supabase_service.dart';
import 'pedometer_service.dart';
import 'notification_service.dart';
import '../../features/activity_health/repositories/step_tracker_repository.dart';

class WorkManagerService {
  static const String dailySyncTaskId = 'daily_final_steps_save_task';
  static const String scheduleDateKey = 'last_schedule_date';

  /// Call this once at app startup (after WidgetsFlutterBinding.ensureInitialized)
  static Future<void> initWorkManager() async {
    await Workmanager().initialize(callbackDispatcher);
    await scheduleNextDailySync();
    print('✓ WorkManager initialized & next sync scheduled');
  }

  /// Schedules the next one‑off task to run exactly at today's target time,
  /// or tomorrow if today's time has already passed.
  static Future<void> scheduleNextDailySync() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final targetTime = DateTime(now.year, now.month, now.day, 23, 45);

    DateTime nextRun;
    if (targetTime.isAfter(now)) {
      nextRun = targetTime;
    } else {
      nextRun = targetTime.add(Duration(days: 1));
    }

    final delay = nextRun.difference(now);

    await Workmanager().registerOneOffTask(
      dailySyncTaskId,
      dailySyncTaskId,
      initialDelay: delay,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace, // ensures only one pending
    );

    await prefs.setString(scheduleDateKey,
        DateTime(now.year, now.month, now.day).toIso8601String());
    print('✓ Scheduled daily sync for ${nextRun.toLocal()} (in ${delay.inHours}h ${delay.inMinutes % 60}m)');
  }

  /// Cancel any pending sync (useful on logout).
  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Essential for any plugin that uses Flutter channels
    WidgetsFlutterBinding.ensureInitialized();

    // Do NOT call Workmanager().initialize again here – it's already done in main.

    try {
      await EnvConfig.init();
      await SupabaseService.init();

      print('\n🚀 [WORKMANAGER] Executing: $taskName');

      if (taskName == WorkManagerService.dailySyncTaskId) {
        await _executeDailyFinalStepsSaveTask();
      } else {
        print('⚠️ Unknown task: $taskName');
        return false;
      }

      // Reschedule the next day's sync (after successful execution)
      await WorkManagerService.scheduleNextDailySync();
      print('✅ Next daily sync scheduled');

      return true;
    } catch (e, stack) {
      print('❌ [WORKMANAGER ERROR] $e\n$stack');
      // Even on error, try to reschedule (to avoid missing future syncs)
      try {
        await WorkManagerService.scheduleNextDailySync();
      } catch (_) {}
      return false;
    }
  });
}

/// Core sync logic – uses stored values to handle midnight roll‑over correctly.
Future<void> _executeDailyFinalStepsSaveTask() async {
  // Network check
  final connectivity = await Connectivity().checkConnectivity();
  if (connectivity == ConnectivityResult.none) {
    print('❌ [SYNC] No network – skipping, will retry tomorrow');
    return; // Task will still finish, and next day's sync is already scheduled
  }

  // Auth check
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    print('❌ [SYNC] No authenticated user – skipping');
    return;
  }

  final prefs = await SharedPreferences.getInstance();

  final storedDateStr = prefs.getString('last_step_update_date') ?? '';
  final todaySteps = prefs.getInt('today_steps_accumulated') ?? 0;

  DateTime now = DateTime.now();
  String dateToSave;
  int stepsToSave;

  // Parse stored date
  DateTime? storedDate;
  if (storedDateStr.isNotEmpty) {
    final parts = storedDateStr.split('-');
    if (parts.length == 3) {
      storedDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }
  }

  // Case 1: Stored date is today → normal sync
  if (storedDate != null &&
      storedDate.year == now.year &&
      storedDate.month == now.month &&
      storedDate.day == now.day) {
    stepsToSave = todaySteps;
    dateToSave = storedDateStr;
    print('📊 Normal sync: $stepsToSave steps for $dateToSave');
  }
  // Case 2: Stored date is yesterday (midnight roll‑over)
  else if (storedDate != null &&
      storedDate.year == now.year &&
      storedDate.month == now.month &&
      storedDate.day == now.day - 1) {
    stepsToSave = todaySteps; // still holds yesterday's steps
    dateToSave = storedDateStr;
    print('📆 Midnight roll‑over – saving $stepsToSave steps for $dateToSave');
  }
  // Case 3: Fallback – fresh sensor read
  else {
    await PedometerService.initPedometer();
    stepsToSave = await PedometerService.getTodayStepsCalculated(refreshFromSensor: true);
    dateToSave = now.toIso8601String().split('T')[0];
    print('⚠️ No stored date – fresh read: $stepsToSave for $dateToSave');
  }

  if (stepsToSave <= 0) {
    print('ℹ️ [SYNC] No steps recorded for $dateToSave');
    return;
  }

  final repository = StepTrackerRepository();
  await repository.saveTodaySteps(stepsToSave);
  print('✅ [SYNC SUCCESS] Saved $stepsToSave steps for $dateToSave');

  // Show notification about today's steps
  try {
    await NotificationService.showStepsNotification(stepsToSave);
    print('✅ Step notification sent: $stepsToSave steps');
  } catch (e) {
    print('⚠️ Failed to send step notification: $e');
  }

  await PedometerService.resetTodaySteps();
}