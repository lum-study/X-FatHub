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

  /// Schedule daily final steps save task: Every day at 11:55 PM to record final step count
  /// Uses periodic task to ensure it runs reliably every day without manual rescheduling
  /// This ensures a final daily record is saved to Supabase even when app is not open
  static Future<void> scheduleDailyFinalStepsSaveTask() async {
    try {
      // Calculate delay to next 11:55 PM
      final now = DateTime.now();
      final targetTime = DateTime(now.year, now.month, now.day, 23, 55);

      // If 11:55 PM has already passed today, target tomorrow's 11:55 PM
      final nextRun = targetTime.isBefore(now)
          ? targetTime.add(const Duration(days: 1))
          : targetTime;

      final delayUntilNextRun = nextRun.difference(now);

      await Workmanager().registerPeriodicTask(
        dailyFinalStepsSaveTaskId,
        'daily_final_steps_save',
        frequency: const Duration(hours: 24),
        initialDelay: delayUntilNextRun,
        // ← First run at 11:55 PM
        constraints: Constraints(networkType: NetworkType.connected),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
      );

      print(
        '✓ Daily task scheduled for 11:55 PM (first run in ${delayUntilNextRun.inHours}h ${delayUntilNextRun.inMinutes % 60}m)',
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

  /// Execute quick sync on app launch
  /// Gets current step count from pedometer and ensures it's synced to Supabase
  /// This runs BEFORE the UI is displayed to ensure profile has fresh step data
  static Future<void> executeQuickSyncOnAppLaunch() async {
    try {
      print('🚀 App launch detected - executing quick sync...');

      // Get today's current steps from pedometer
      await PedometerService.initPedometer();

      // Wait a bit for pedometer to receive fresh sensor data
      // This ensures we get accurate step count instead of stale data
      await Future.delayed(const Duration(seconds: 1));

      final steps = await PedometerService.getTodayStepsCalculated(
        refreshFromSensor: true,
      );
      print('✓ [QUICK SYNC] Got current steps ($steps) from pedometer');

      // Try to sync to Supabase if network available via repository
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult != ConnectivityResult.none) {
        print('📡 Network available - syncing to Supabase on app launch...');
        try {
          final repository = StepTrackerRepository();
          await repository.saveTodaySteps(steps);
          print('✓ [QUICK SYNC] Synced steps to Supabase');
        } catch (e) {
          print('📡 Sync to Supabase deferred (will retry later): $e');
        }
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
  print('🔴 [DEBUG] callbackDispatcher called!');
  Workmanager().executeTask((taskName, inputData) async {
    try {
      print('\n════════════════════════════════════════════════');
      print('🚀 [CALLBACK DISPATCHER] WorkManager task initiated');
      print('   Task Name: $taskName');
      print('   Expected: daily_final_steps_save');
      print('   Time: ${DateTime.now()}');
      print('════════════════════════════════════════════════\n');

      switch (taskName) {
        case 'daily_final_steps_save':
        case 'local_save_steps': // Handle legacy task name
          await _executeDailyFinalStepsSaveTask();
          break;
        default:
          print('⚠️ Unknown task: $taskName');
          return Future.value(false);
      }

      print('\n════════════════════════════════════════════════');
      print('✓ [CALLBACK DISPATCHER] WorkManager task completed: $taskName');
      print('════════════════════════════════════════════════\n');
      return Future.value(true);
    } catch (e) {
      print('\n════════════════════════════════════════════════');
      print('❌ [CALLBACK DISPATCHER ERROR] WorkManager task failed');
      print('   Task: $taskName');
      print('   Error: $e');
      print('════════════════════════════════════════════════\n');
      return Future.value(false);
    }
  });
}

/// Execute daily final steps save task: Sync today's final step count to Supabase
/// Runs periodically every 24 hours
Future<void> _executeDailyFinalStepsSaveTask() async {
  try {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    print('\n════════════════════════════════════════════════');
    print('🔔 [CALLBACK FIRED] Daily step sync task executed at $timeStr');
    print('════════════════════════════════════════════════\n');

    final prefs = await SharedPreferences.getInstance();

    // 🌐 NETWORK CHECK - Trace point 2
    print('🌐 Checking network connectivity...');
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print('❌ [NETWORK ERROR] No network available - WorkManager will retry');
      throw Exception('No network available - WorkManager will retry');
    }
    print('✓ Network connected\n');

    // 🔐 AUTH CHECK - Trace point 3
    print('🔐 Checking authentication...');
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) {
      print('❌ [AUTH ERROR] No authenticated user');
      throw Exception('No authenticated user for step sync');
    }
    print('✓ User authenticated: $userId\n');

    // 📊 GET STEP COUNT - Trace point 4
    print('📊 Initializing pedometer...');
    await PedometerService.initPedometer();

    print('📊 Fetching step count...');
    final finalSteps = await PedometerService.getTodayStepsCalculated(
      refreshFromSensor: true,
    );
    print('✓ Step count retrieved: $finalSteps steps\n');

    if (finalSteps <= 0) {
      print('ℹ️ No steps recorded for the day - marking as synced');
      return;
    }

    // 📤 SUPABASE SYNC - Trace point 5
    print('📤 Syncing to Supabase...');
    try {
      final repository = StepTrackerRepository();
      await repository.saveTodaySteps(finalSteps);

      // ✅ SUCCESS NOTIFICATION
      print('\n════════════════════════════════════════════════');
      print(
        '✅ [SYNC SUCCESS] Successfully saved $finalSteps steps to Supabase',
      );
      print('   Time: $timeStr');
      print('════════════════════════════════════════════════\n');

      // Sync completed successfully
    } catch (e) {
      print('\n════════════════════════════════════════════════');
      print('❌ [SUPABASE ERROR] Failed to save steps to Supabase');
      print('   Error: $e');
      print('   WorkManager will retry (up to 2 times)');
      print('════════════════════════════════════════════════\n');
      rethrow; // Let WorkManager retry
    }
  } catch (e) {
    print('\n════════════════════════════════════════════════');
    print('❌ [JOB FAILED] Error in daily final steps save task');
    print('   Error: $e');
    print('════════════════════════════════════════════════\n');
    rethrow; // Let WorkManager handle with retry logic
  }
}
