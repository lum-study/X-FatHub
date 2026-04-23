import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'pedometer_service.dart';
import 'work_manager_service.dart';
import '../config/env_config.dart';
import '../../features/activity_health/repositories/hydration_repository.dart';

/// Service to handle background step tracking
/// Manages continuous step monitoring even when app is closed
/// Uses WorkManager for reliable scheduled synchronization tasks
@pragma('vm:entry-point')
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
  /// Note: With Supabase-first architecture, all step data is synced in real-time via the repository.
  /// This method is now simplified and serves as a verification/health check.
  static Future<void> _performWeeklySyncToSupabase() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        print('⚠ No authenticated user for weekly sync verification');
        return;
      }

      // Query recent records from Supabase to verify sync is working
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final startDate = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day)
          .toIso8601String()
          .split('T')[0];

      final response = await client
          .from('step_tracker_daily')
          .select('date,steps')
          .eq('user_id', userId)
          .gte('date', startDate)
          .order('date', ascending: false);

      final recordCount = (response as List).length;
      print('✅ Weekly sync verification: Found $recordCount records in Supabase (last 7 days)');
      print('ℹ All step data is synced in real-time via the repository layer');
    } catch (e) {
      print('❌ Weekly sync verification error: $e');
    }
  }

  /// Verify step data sync to Supabase
  /// With Supabase-first architecture, all step updates are synced immediately via the repository.
  /// This method serves as a health check to ensure Supabase connectivity.
  static Future<void> _syncUnsyncedRecordsToSupabase() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        _syncRetryCount = 0;
        print('⚠ No authenticated user for sync verification');
        return;
      }

      // Query today's step record to verify Supabase connectivity
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day)
          .toIso8601String()
          .split('T')[0];

      final response = await client
          .from('step_tracker_daily')
          .select('steps')
          .eq('user_id', userId)
          .eq('date', todayDate)
          .maybeSingle();

      if (response != null) {
        final steps = response['steps'] as int;
        print('✓ Supabase sync verified: Today\'s steps ($steps) successfully synced');
      } else {
        print('ℹ No step data synced yet for today');
      }

      _syncRetryCount = 0;
    } catch (e) {
      _syncRetryCount++;
      if (_syncRetryCount <= _maxSyncRetries) {
        print('⚠ Sync verification failed (attempt $_syncRetryCount): $e');
      }
    }
  }
}
