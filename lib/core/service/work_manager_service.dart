import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

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

  /// Schedule local save task: Every 1 hour save steps to local DB
  /// Runs continuously throughout the day
  static Future<void> scheduleLocalSaveStepsTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        localSaveStepsTaskId,
        'local_save_steps',
        frequency: const Duration(hours: 1),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
        initialDelay: const Duration(minutes: 5),
      );

      print('✓ Local save steps task scheduled (every 1 hour)');
    } catch (e) {
      print('✗ Error scheduling local save steps task: $e');
    }
  }

  /// Schedule Supabase sync task: Every 1 day sync to Supabase
  /// Uploads today's accumulated steps to remote database
  static Future<void> scheduleSupabaseSyncTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        supabaseSyncTaskId,
        'supabase_sync',
        frequency: const Duration(days: 1),
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

      print('✓ Supabase sync task scheduled (every 1 day)');
    } catch (e) {
      print('✗ Error scheduling Supabase sync task: $e');
    }
  }

/// Schedule daily task to sync hydration data to Supabase
  static Future<void> scheduleDailyHydrationSyncTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        dailyHydrationSyncTaskId,
        'daily_hydration_sync',
        frequency: const Duration(days: 1),
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
      
      print('✓ Daily hydration sync task scheduled (every 1 day)');
    } catch (e) {
      print('✗ Error scheduling daily hydration sync task: $e');
    }
  }

  /// Schedule periodic task to push unsynced records (older than 7 days)
  static Future<void> scheduleUnsyncedRecordsPushTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        unsyncedRecordsPushTaskId,
        'unsynced_records_push',
        frequency: const Duration(hours: 6),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 30),
        initialDelay: const Duration(minutes: 30),
      );

      print('✓ Unsynced records push task scheduled');
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

  /// Cancel a specific task by ID
  static Future<void> cancelTask(String taskId) async {
    try {
      await Workmanager().cancelByTag(taskId);
      print('✓ Task cancelled: $taskId');
    } catch (e) {
      print('✗ Error cancelling task $taskId: $e');
    }
  }

  /// Execute quick sync on app launch
  /// Immediately tries to sync any pending data when app starts
  static Future<void> executeQuickSyncOnAppLaunch() async {
    try {
      print('🚀 App launch detected - executing quick sync...');

      // Get today's current steps and save to local DB
      await PedometerService.initPedometer();
      final steps = await PedometerService.getTodaySteps();
      await LocalStepDatabase.saveTodaySteps(steps);
      print(
        '✓ [QUICK SYNC] Saved current steps ($steps) to local database on app launch',
      );

      // Try to sync to Supabase if network available
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult != ConnectivityResult.none) {
        print('📡 Network available - syncing to Supabase on app launch...');
        await _executeSupabaseSyncTask();
      } else {
        print('📡 No network on app launch - will retry later');
      }
    } catch (e) {
      print('✗ Error in quick sync on app launch: $e');
    }
  }
}

/// Callback dispatcher for background WorkManager tasks
/// Must be a top-level function called from main()
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      print('📱 WorkManager task started: $taskName');

      switch (taskName) {
        case 'local_save_steps':
          await _executeLocalSaveStepsTask();
          break;
        case 'supabase_sync':
          await _executeSupabaseSyncTask();
          break;
        case 'daily_hydration_sync':
          await _executeDailyHydrationSyncTask();
          break;
        case 'unsynced_records_push':
          await _executeUnsyncedRecordsPushTask();
          break;
        default:
          print('⚠️ Unknown task: $taskName');
          return Future.value(false);
      }

      print('✓ WorkManager task completed: $taskName');
      return Future.value(true);
    } catch (e) {
      print('✗ Error executing WorkManager task $taskName: $e');
      return Future.value(false);
    }
  });
}

/// Execute local save task: Save today's steps to local database
/// Runs every 15 minutes throughout the day
/// At 23:55-23:59: Performs final daily save and resets baseline
Future<void> _executeLocalSaveStepsTask() async {
  try {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    // Check if it's the final save time window (23:55-23:59)
    final isFinalSaveTime = hour == 23 && minute >= 55 && minute <= 59;

    // Initialize pedometer for background context
    await PedometerService.initPedometer();

    // Get today's steps
    final steps = await PedometerService.getTodaySteps();

    // Save to local database
    await LocalStepDatabase.saveTodaySteps(steps);

    if (isFinalSaveTime) {
      // Final save: Set baseline for next day
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'final_daily_save_time',
        DateTime.now().toIso8601String(),
      );
      print(
        '✓ [FINAL SAVE 23:55-23:59] Saved today\'s final steps ($steps) to local database + baseline reset prepared',
      );
    } else {
      print(
        '✓ [LOCAL SAVE] Saved current steps ($steps) to local database at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );
    }
  } catch (e) {
    print('✗ Error in local save steps task: $e');
    rethrow;
  }
}

/// Execute Supabase sync task: Sync today's steps to Supabase
/// Runs every 60 minutes - uploads current day data to remote database
Future<void> _executeSupabaseSyncTask() async {
  try {
    // Check network connectivity
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print('📡 No network available. Skipping Supabase sync.');
      return;
    }

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) {
      print('⚠️ No authenticated user for Supabase sync');
      return;
    }

    // Get today's steps from local database
    final today = DateTime.now();
    final todayDate = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String().split('T')[0];
    final todaySteps = await LocalStepDatabase.getStepsByDate(today);

    if (todaySteps == null) {
      print('ℹ️ No steps recorded today yet');
      return;
    }

    // Sync today's steps to Supabase
    try {
      await client.from('step_tracker_daily').upsert({
        'user_id': userId,
        'date': todayDate,
        'steps': todaySteps,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');

      print(
        '✓ [SUPABASE SYNC] Synced today\'s steps ($todaySteps) to Supabase',
      );
    } catch (e) {
      print('⚠️ Failed to sync today\'s steps to Supabase: $e');
      rethrow;
    }
  } catch (e) {
    print('✗ Error in Supabase sync task: $e');
    rethrow;
  }
}

/// Execute daily task: Sync hydration data to Supabase
Future<void> _executeDailyHydrationSyncTask() async {
  try {
    // Check network connectivity
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print('📡 No network available. Skipping hydration sync.');
      return;
    }

    final repository = HydrationRepository();
    await repository.syncToSupabase();
    print('✓ [DAILY HYDRATION SYNC] Synced hydration entries and goals to Supabase');
  } catch (e) {
    print('✗ Error in daily hydration sync task: $e');
    rethrow;
  }
}

/// Execute periodic task: Push unsynced records (older than 7 days)
Future<void> _executeUnsyncedRecordsPushTask() async {
  try {
    // Check network connectivity
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print('📡 No network available. Skipping unsynced records push.');
      return;
    }

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) {
      print('⚠️ No authenticated user for unsynced records sync');
      return;
    }

    // Get all unsynced records (older than 7 days)
    final unsyncedRecords = await LocalStepDatabase.getUnsyncedRecords();

    if (unsyncedRecords.isEmpty) {
      print('ℹ️ No unsynced records to push');
      return;
    }

    // Sync each record to Supabase
    int uploadedCount = 0;
    int failedCount = 0;

    for (var record in unsyncedRecords) {
      try {
        final date = record['date'] as String;
        final steps = record['steps'] as int;

        await client.from('step_tracker_daily').upsert({
          'user_id': userId,
          'date': date,
          'steps': steps,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,date');

        uploadedCount++;
        print('✓ Synced unsynced record: $date ($steps steps)');
      } catch (e) {
        failedCount++;
        print('⚠️ Failed to sync record: $e');
      }
    }

    print(
      '✓ Unsynced records push complete: $uploadedCount uploaded, $failedCount failed',
    );
  } catch (e) {
    print('✗ Error in unsynced records push task: $e');
    rethrow;
  }
}
