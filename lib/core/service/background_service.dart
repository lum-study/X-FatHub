import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pedometer_service.dart';
import '../database/local_step_db.dart';
import '../config/env_config.dart';

/// Service to handle background step tracking
/// Manages continuous step monitoring even when app is closed
class BackgroundService {
  static const Duration _syncInterval = Duration(minutes: 5);
  
  static Timer? _syncTimer;
  static DateTime? _lastSyncTime;
  static int _syncRetryCount = 0;
  static const int _maxSyncRetries = 3;

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

    // Initialize Pedometer for background tracking
    await PedometerService.initPedometer();

    // Periodic sync to database
    _syncTimer = Timer.periodic(_syncInterval, (timer) async {
      try {
        // Save steps at 11:59 PM
        await _saveDailyStepsAtNight();
        
        // Weekly sync: Upload all records to Supabase every Saturday at 11:59 PM
        await _syncWeeklyToSupabase();
        
        // Sync unsynced records (older than 7 days) to Supabase
        await _syncUnsyncedRecordsToSupabase();
      } catch (e) {
        print('Background sync error: $e');
      }
    });

    // Listen to service stop events
    if (service is AndroidServiceInstance) {
      service.on('stopService').listen((event) {
        _syncTimer?.cancel();
      });
    }
  }

  /// Save today's steps to local database at 11:59 PM
  static Future<void> _saveDailyStepsAtNight() async {
    final now = DateTime.now();
    final nightTime = DateTime(now.year, now.month, now.day, 23, 59, 0);
    
    // Check if it's close to 11:59 PM (within 5-minute window)
    if (now.isAfter(nightTime) || now.isAfter(nightTime.subtract(const Duration(minutes: 5)))) {
      // Save steps to local database
      final steps = await PedometerService.getTodaySteps();
      await LocalStepDatabase.saveTodaySteps(steps);
      print('✓ Saved today\'s steps ($steps) to local database at night');
    }
  }

  /// Weekly sync: Upload all local records to Supabase every Saturday at 11:59 PM
  /// Deletes records from local database if upload is successful
  static Future<void> _syncWeeklyToSupabase() async {
    try {
      final now = DateTime.now();
      
      // Check if it's Saturday (weekday 6 = Saturday)
      if (now.weekday != 6) {
        return; // Not Saturday
      }
      
      // Check if it's close to 11:59 PM (within 5-minute window)
      final nightTime = DateTime(now.year, now.month, now.day, 23, 59, 0);
      if (!now.isAfter(nightTime.subtract(const Duration(minutes: 5))) && !now.isAfter(nightTime)) {
        return; // Not the right time
      }

      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id ?? '5734d344-0bee-4bf6-bfcd-553e0dd5db68';

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
          });

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
  static Future<void> _syncUnsyncedRecordsToSupabase() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id ?? '5734d344-0bee-4bf6-bfcd-553e0dd5db68';

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
          });

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
