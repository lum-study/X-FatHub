import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';
import 'supabase_service.dart';
import 'pedometer_service.dart';
import '../database/local_step_db.dart';
import '../database/local_hydration_db.dart';
import '../../features/activity_health/repositories/hydration_repository.dart';

/// Service to handle WorkManager background tasks
/// Provides reliable scheduling for step data sync:
/// - Every 15 min: Save steps to local DB
/// - Every 60 min: Sync to Supabase
/// - 23:55-23:59: Final daily save + baseline reset
/// - App launch: Quick sync
class WorkManagerService {
  static const String localSaveStepsTaskId = 'local_save_steps_task';
  static const String supabaseSyncTaskId = 'supabase_sync_task';
  static const String dailyHydrationSyncTaskId = 'daily_hydration_sync_task';
  static const String unsyncedRecordsPushTaskId = 'unsynced_records_push_task';

  /// Initialize WorkManager and schedule background tasks
  static Future<void> initWorkManager() async {
    try {
      // Initialize WorkManager with callback function
      // Set isInDebugMode to true during development to see logs and notifications
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

      print('✓ WorkManager initialized successfully');

      // Schedule all background tasks
      await scheduleLocalSaveStepsTask();
      await scheduleSupabaseSyncTask();
      await scheduleDailyHydrationSyncTask();
      await scheduleUnsyncedRecordsPushTask();
    } catch (e) {
      print('✗ Error initializing WorkManager: $e');
    }
  }

  /// Schedule daily final steps save task: Every day at 11:55 PM to record final step count
  static Future<void> scheduleDailyFinalStepsSaveTask() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastScheduledDate = prefs.getString('last_wm_schedule_date') ?? '';
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      // Only reschedule if not done today to prevent task reset
      if (lastScheduledDate == todayStr) {
        print('ℹ️ Daily sync task already scheduled for today, skipping re-registration');
        return;
      }

      // Calculate delay to next 11:55 PM (23:55)
      final now = DateTime.now();
      final targetTime = DateTime(now.year, now.month, now.day, 23, 55);

      final nextRun = targetTime.isBefore(now)
          ? targetTime.add(const Duration(days: 1))
          : targetTime;

  /// Schedule Supabase sync task: Every 1 hour sync to Supabase
  /// Uploads today's accumulated steps to remote database with hourly retry
  static Future<void> scheduleSupabaseSyncTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        supabaseSyncTaskId,
        'supabase_sync',
        frequency: const Duration(hours: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 10),
        initialDelay: const Duration(minutes: 10),
      );

      print('✓ Supabase sync task scheduled (every 1 hour)');
    } catch (e) {
      print('✗ Error scheduling Supabase sync task: $e');
    }
  }

/// Schedule hydration sync task: Every 1 hour to sync hydration data to Supabase
/// Increased frequency for more reliable data sync
  static Future<void> scheduleDailyHydrationSyncTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        dailyFinalStepsSaveTaskId,
        'daily_final_steps_save',
        frequency: const Duration(hours: 24),
        initialDelay: delayUntilNextRun,
        constraints: Constraints(networkType: NetworkType.connected),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 10),
        initialDelay: const Duration(minutes: 10),
      );
      
      print('✓ Hydration sync task scheduled (every 1 hour)');
    } catch (e) {
      print('✗ Error scheduling hydration sync task: $e');
    }
  }

      await prefs.setString('last_wm_schedule_date', todayStr);

      print(
        '✓ Daily task scheduled for 11:55 PM (first run in ${delayUntilNextRun.inHours}h ${delayUntilNextRun.inMinutes % 60}m)',
      );

      print('✓ Unsynced records push task scheduled (every 30 minutes)');
    } catch (e) {
      print('✗ Error scheduling unsynced records push task: $e');
    }
  }

  /// Cancel all scheduled background tasks
  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      print('✓ All WorkManager tasks cancelled');
    } catch (e) {
      print('✗ Error cancelling WorkManager tasks: $e');
    }
  }

  /// One-time sync triggered on app launch
  static Future<void> executeQuickSyncOnAppLaunch() async {
    print('🔄 [LAUNCH SYNC] Triggering quick step sync to Supabase...');
    try {
      await _executeDailyFinalStepsSaveTask();
    } catch (e) {
      print('⚠️ [LAUNCH SYNC] Background sync failed or skipped: $e');
    }
  }
}

/// Callback dispatcher for background WorkManager tasks
/// Must be a top-level function called from main()
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // IMPORTANT: Initialize background isolate services
      // Background isolates don't share memory with the main app isolate
      await EnvConfig.init();
      await SupabaseService.init();
      
      print('\n🚀 [WORKMANAGER] Executing task: $taskName');

      switch (taskName) {
        case 'daily_final_steps_save':
        case 'local_save_steps':
          await _executeDailyFinalStepsSaveTask();
          break;
        default:
          print('⚠️ Unknown task: $taskName');
          return Future.value(false);
      }

      return Future.value(true);
    } catch (e) {
      print('❌ [WORKMANAGER ERROR] Task failed in background isolate: $e');
      return Future.value(false);
    }
  });
}

/// Execute daily final steps save task: Sync today's final step count to Supabase
Future<void> _executeDailyFinalStepsSaveTask() async {
  try {
    // 🌐 NETWORK CHECK
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('❌ [SYNC] No network - skipping sync');
      return;
    }

    // 🔐 AUTH CHECK
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ [SYNC] No authenticated user');
      return;
    }

    // 📊 GET STEP COUNT
    await PedometerService.initPedometer();
    final finalSteps = await PedometerService.getTodayStepsCalculated(
      refreshFromSensor: true,
    );

    if (finalSteps <= 0) {
      print('ℹ️ [SYNC] No steps recorded for today');
      return;
    }

    // 📤 SUPABASE SYNC
    final repository = StepTrackerRepository();
    await repository.saveTodaySteps(finalSteps);
    print('✅ [SYNC SUCCESS] Saved $finalSteps steps for user: $userId');
    
  } catch (e) {
    print('❌ [SYNC ERROR] $e');
    rethrow;
  }
}
