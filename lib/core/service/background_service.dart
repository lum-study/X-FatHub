import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'pedometer_service.dart';
import 'work_manager_service.dart';
import '../database/local_step_db.dart';
import '../database/local_hydration_db.dart';
import '../config/env_config.dart';
import '../../features/activity_health/repositories/hydration_repository.dart';

/// Service to handle background step tracking
/// Manages continuous step monitoring even when app is closed
/// Uses WorkManager for reliable scheduled synchronization tasks
class BackgroundService {
  static StreamSubscription? _connectivitySubscription;
  static int _syncRetryCount = 0;
  static const int _maxSyncRetries = 3;
  
  // Shared preferences keys for sync queue
  static const String _pendingWeeklySyncKey = 'pending_weekly_sync_step_count';
  static const String _lastWeeklySyncDateKey = 'last_weekly_sync_date';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: false,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    await service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    await PedometerService.initPedometer();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Initialize Pedometer for continuous background tracking
    // This ensures steps are continuously counted even when app is closed
    await PedometerService.initPedometer();
    print('✓ Background service started - Pedometer initialized for continuous monitoring');

    // Set up network connectivity listener for automatic retries on network restoration
    _setupConnectivityListener();

    // Listen to service stop events
    if (service is AndroidServiceInstance) {
      service.on('stopService').listen((event) {
        _connectivitySubscription?.cancel();
        print('✓ Background service stopped');
      });
    }
  }

  /// Set up listener for network connectivity changes
  /// Automatically retries pending syncs when network becomes available
  static void _setupConnectivityListener() {
    try {
      _connectivitySubscription?.cancel();
      
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        (result) async {
          // Check if just connected
          if (result != ConnectivityResult.none) {
            print('📡 Network connected: $result - Retrying pending syncs...');
            // Retry pending syncs when network is restored
            await _retryPendingSync();
          } else {
            print('📡 Network disconnected');
          }
        },
        onError: (e) {
          print('Connectivity listener error: $e');
        },
      );
      
      print('✓ Connectivity listener set up for automatic retry on network restoration');
    } catch (e) {
      print('Error setting up connectivity listener: $e');
    }
  }

  /// Retry pending syncs when network is restored
  static Future<void> _retryPendingSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPending = prefs.getBool(_pendingWeeklySyncKey) ?? false;
      
      if (!isPending) {
        return; // No pending sync
      }
      
      print('🔄 Retrying pending weekly sync now that network is restored...');
      await _performWeeklySyncToSupabase();
      
      // Clear the pending flag after successful retry
      await prefs.setBool(_pendingWeeklySyncKey, false);
      print('✅ Pending sync completed successfully');
    } catch (e) {
      print('❌ Error retrying pending sync: $e');
    }
  }

  /// Perform the actual weekly sync upload
  /// This is called when network is available (both on schedule and on network restoration)
  static Future<void> _performWeeklySyncToSupabase() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        print('⚠ No authenticated user for weekly sync');
        return;
      }

      // Get all records from local database
      final allRecords = await LocalStepDatabase.getAllRecords();
      
      if (allRecords.isEmpty) {
        print('ℹ No records to sync for weekly upload');
        return;
      }

      print('📤 Starting weekly sync: uploading ${allRecords.length} records to Supabase...');

      final List<String> successfulDates = [];
      int uploadedCount = 0;
      int failedCount = 0;

      // Upload each record to Supabase
      for (var record in allRecords) {
        try {
          final date = record['date'] as String;
          final steps = record['steps'] as int;

          await client.from('step_tracker_daily').upsert({
            'user_id': userId,
            'date': date,
            'steps': steps,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,date');

          successfulDates.add(date);
          uploadedCount++;
          print('✓ Uploaded weekly record: $date ($steps steps)');
        } catch (e) {
          failedCount++;
          print('⚠ Failed to upload record: $e');
        }
      }

      // Delete successfully uploaded records from local database
      if (successfulDates.isNotEmpty) {
        final deleted = await LocalStepDatabase.deleteRecordsByDates(successfulDates);
        print('🗑️ Weekly sync complete: $uploadedCount records uploaded, $deleted deleted from local DB, $failedCount failed');
      }

      if (failedCount == 0) {
        print('✅ Weekly sync successful: All records uploaded and cleared from local database');
      }
    } catch (e) {
      print('❌ Weekly sync error: $e');
    }
  }

  /// Sync unsynced records (older than 7 days) to Supabase
  /// This is called periodically by WorkManager
  static Future<void> _syncUnsyncedRecordsToSupabase() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        _syncRetryCount = 0;
        return;
      }

      // Get all unsynced records (older than 7 days)
      final unsyncedRecords = await LocalStepDatabase.getUnsyncedRecords();
      
      if (unsyncedRecords.isEmpty) {
        return; // No records to sync
      }

      // Sync each record to Supabase
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

          // Mark as synced in local database
          await LocalStepDatabase.markAsSynced(date);
          print('✓ Synced record $date ($steps steps) to Supabase');
        } catch (e) {
          print('⚠ Failed to sync record: $e');
          _syncRetryCount++;
        }
      }

      // Clean up old synced records (older than 30 days)
      final deleted = await LocalStepDatabase.deleteOldRecords();
      if (deleted > 0) {
        print('✓ Cleaned up $deleted old records');
      }

      _syncRetryCount = 0;
    } catch (e) {
      _syncRetryCount++;
      if (_syncRetryCount <= _maxSyncRetries) {
        print('⚠ Sync failed (attempt $_syncRetryCount): $e');
      }
    }
  }
}
