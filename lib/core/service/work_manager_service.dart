import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pedometer_service.dart';
import '../../features/activity_health/repositories/step_tracker_repository.dart';

/// Service to handle WorkManager background tasks
/// Provides reliable daily step data sync:
/// - Once per day at 11:55 PM: Fetch and update final step count to Supabase
/// - Automatic retry up to 2 times if sync fails
/// - App launch: Quick one-time sync to ensure data is up-to-date
class WorkManagerService {
  static const String dailyFinalStepsSaveTaskId = 'daily_final_steps_save_task';

  /// Initialize WorkManager and schedule background tasks
  static Future<void> initWorkManager() async {
    try {
      // Initialize WorkManager with callback function
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

      print('✓ WorkManager initialized successfully');

      // Schedule daily final steps save task (at 11:55 PM)
      await scheduleDailyFinalStepsSaveTask();
    } catch (e) {
      print('✗ Error initializing WorkManager: $e');
    }
  }

  /// Schedule local save task: Every 30 minutes save steps to local DB
  /// Runs continuously throughout the day with more frequent saves
  static Future<void> scheduleLocalSaveStepsTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        localSaveStepsTaskId,
        'local_save_steps',
        frequency: const Duration(minutes: 30),
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

      print('✓ Local save steps task scheduled (every 30 minutes)');
    } catch (e) {
      print('✗ Error scheduling local save steps task: $e');
    }
  }

      final delayUntilNextRun = nextRun.difference(now);

      await Workmanager().registerPeriodicTask(
        dailyHydrationSyncTaskId,
        'daily_hydration_sync',
        frequency: const Duration(hours: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
      );

  /// Schedule periodic task to push unsynced records: Every 30 minutes
  /// More frequent retries ensure old records don't accumulate
  static Future<void> scheduleUnsyncedRecordsPushTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        unsyncedRecordsPushTaskId,
        'unsynced_records_push',
        frequency: const Duration(minutes: 30),
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
    } catch (e) {
      print('✗ Error scheduling task: $e');
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
/// Runs hourly - uploads current day data to remote database with retries
Future<void> _executeSupabaseSyncTask() async {
  try {
    // Check network connectivity
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print('📡 No network available. Skipping Supabase sync. Will retry in 1 hour.');
      return;
    }

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) {
      print('❌ [CRITICAL] No authenticated user for Supabase sync - user not logged in');
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
      print('ℹ️ No steps recorded today yet - skipping sync');
      return;
    }

    // Sync today's steps to Supabase with error handling
    try {
      await client.from('step_tracker_daily').upsert({
        'user_id': userId,
        'date': todayDate,
        'steps': todaySteps,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');

      print(
        '✓ [SUPABASE SYNC] Synced today\'s steps ($todaySteps steps on $todayDate) to Supabase',
      );
    } catch (e) {
      print('❌ Failed to sync today\'s steps to Supabase: $e');
      print('   Will retry in 1 hour');
      rethrow;
    }
  } catch (e) {
    print('❌ Error in Supabase sync task: $e');
    rethrow;
  }
}

/// Execute hydration sync task: Sync hydration data to Supabase
/// Runs hourly for more reliable sync
Future<void> _executeDailyHydrationSyncTask() async {
  try {
    // Check network connectivity
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print('📡 No network available. Skipping hydration sync. Will retry in 1 hour.');
      return;
    }

    try {
      final repository = HydrationRepository();
      await repository.syncToSupabase();
      print('✓ [HYDRATION SYNC] Synced hydration entries and goals to Supabase');
    } catch (e) {
      print('❌ Error syncing hydration data: $e');
      print('   Will retry in 1 hour');
      rethrow;
    }
  } catch (e) {
    print('❌ Error in hydration sync task: $e');
    rethrow;
  }
}

/// Execute periodic task: Push unsynced records
/// Runs every 30 minutes for more frequent retries
Future<void> _executeUnsyncedRecordsPushTask() async {
  try {
    // Check network connectivity
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print('📡 No network available. Skipping unsynced records push. Will retry in 30 minutes.');
      return;
    }

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) {
      print('❌ [CRITICAL] No authenticated user for unsynced records sync');
      return;
    }

    // Get all unsynced records
    final unsyncedRecords = await LocalStepDatabase.getUnsyncedRecords();

    if (unsyncedRecords.isEmpty) {
      print('ℹ️ No unsynced records to push - all data is synced');
      return;
    }

    print('📤 Attempting to sync ${unsyncedRecords.length} unsynced records...');

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
        print('❌ Failed to sync record: $e - will retry later');
      }
    }

    print(
      '✓ Unsynced records push complete: $uploadedCount uploaded, $failedCount will retry',
    );
  } catch (e) {
    print('❌ Error in unsynced records push task: $e');
    rethrow;
  }
}
