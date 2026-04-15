import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'native_activity_service.dart';

/// Callback type for error recovery notifications
/// Called when foreground service encounters and recovers from errors
typedef ErrorRecoveryCallback = void Function(
  String errorMessage,
  bool gpsRequired,
  bool permissionRequired,
  int retryAttempt,
);

/// Service for managing background location tracking
/// Enables activity tracking even when app is in background/locked
/// Works in conjunction with Android foreground service for reliability
/// 
/// Error Recovery Architecture:
/// 1. Foreground Service detects error
/// 2. Service checks conditions (GPS enabled?, Permission granted?)
/// 3. If conditions not met, prompts for resolution
/// 4. If conditions met, restarts location stream
/// 5. ViewModel receives error state via callback
/// 6. notifyListeners() triggers UI banner update
class BackgroundLocationService {
  static const String _activeActivityKey = 'active_activity_id';
  static const String _locationHistoryKey = 'location_history_';
  static StreamSubscription<Position>? _locationStream;
  
  /// Callback for notifying ViewModel of errors and recovery attempts
  static ErrorRecoveryCallback? _onErrorRecovery;
  
  /// Error recovery state tracking
  static int _streamRetryAttempt = 0;
  static DateTime? _lastStreamError;
  static const Duration _retryDelay = Duration(seconds: 5);
  static bool _isRecovering = false;
  /// Set error recovery callback to notify ViewModel of tracking issues
  /// This should be called during app initialization
  static void setErrorRecoveryCallback(ErrorRecoveryCallback? callback) {
    _onErrorRecovery = callback;
    print('📱 Error recovery callback registered');
  }

  /// Initialize and start background location tracking service
  /// This method sets up the location stream and error recovery mechanisms
  static Future<void> initializeBackgroundTracking() async {
    try {
      print('📍 Initializing background location tracking service...');
      
      // Request background location permission
      final status = await Geolocator.requestPermission();
      if (status != LocationPermission.always) {
        print('⚠️ Background location permission not fully granted (status: $status)');
        print('   Please enable "Always" location permission for full background tracking');
      }

      // Start listening to location stream with error recovery
      await _startLocationStreamWithRecovery();

      print('✓ Background location tracking initialized and listening for updates');
    } catch (e) {
      print('✗ Error initializing background tracking: $e');
      _notifyErrorRecovery('Failed to initialize: $e', false, false, 0);
    }
  }

  /// Start location stream with comprehensive error recovery logic
  /// Implements: Error Detection → Condition Check → Stream Restart → ViewModel Notify
  static Future<void> _startLocationStreamWithRecovery() async {
    _streamRetryAttempt = 0;
    _lastStreamError = null;
    
    _attachLocationStreamWithErrorHandling();
  }

  /// Attach location stream with error handling and infinite retry
  /// Checks GPS enabled and permissions before restarting stream
  static void _attachLocationStreamWithErrorHandling() {
    if (_isRecovering && _streamRetryAttempt > 0) {
      print('⏳ Waiting ${_retryDelay.inSeconds}s before retry attempt #${_streamRetryAttempt + 1}...');
      Future.delayed(_retryDelay, () {
        if (_isRecovering || _streamRetryAttempt > 0) {
          _attachLocationStreamWithErrorHandling();
        }
      });
      return;
    }

    try {
      print('📡 Subscribing to location stream (5m update interval, attempt #${_streamRetryAttempt + 1})...');
      
      _locationStream?.cancel();
      
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Update every 5 meters
        timeLimit: Duration(minutes: 5), // Max wait time
      );

      _locationStream = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen(
        (Position position) async {
          // Reset error state on successful position update
          if (_streamRetryAttempt > 0) {
            print('✅ Location stream recovered on attempt #${_streamRetryAttempt + 1}!');
            _streamRetryAttempt = 0;
            _isRecovering = false;
          }
          
          print('📍 Background position: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');
          await _recordPosition(position);
        },
        onError: (dynamic error) async {
          if (_isRecovering) return; // Already in recovery mode
          
          _lastStreamError = DateTime.now();
          _streamRetryAttempt++;
          _isRecovering = true;
          
          print('❌ [STREAM ERROR] Location stream error (attempt #$_streamRetryAttempt): $error');
          
          // Diagnose and attempt recovery
          await _recoverFromLocationError(error);
        },
        cancelOnError: false, // Continue even on errors
      );

      print('✓ Location stream listener attached');
    } catch (e) {
      _streamRetryAttempt++;
      _isRecovering = true;
      _lastStreamError = DateTime.now();
      
      print('❌ [ATTACHMENT ERROR] Error attaching location stream (attempt #$_streamRetryAttempt): $e');
      _notifyErrorRecovery(
        'Failed to attach location stream: $e',
        false,
        false,
        _streamRetryAttempt,
      );
      
      // Retry after delay
      Future.delayed(_retryDelay, () {
        _attachLocationStreamWithErrorHandling();
      });
    }
  }

  /// Recover from location stream error with diagnostic checks
  /// Follows error recovery architecture:
  /// 1. Check GPS enabled?
  ///    - No → Notify user to enable GPS
  ///    - Yes → Proceed
  /// 2. Check permission granted?
  ///    - No → Request permission
  ///    - Yes → Proceed
  /// 3. Restart location stream
  static Future<void> _recoverFromLocationError(dynamic error) async {
    print('🔍 Diagnosing location stream error...');
    
    bool gpsRequired = false;
    bool permissionRequired = false;

    // Check GPS enabled
    print('📍 Checking GPS status...');
    final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      print('❌ GPS is disabled');
      gpsRequired = true;
      _notifyErrorRecovery(
        'GPS is disabled. Enable GPS to continue tracking.',
        gpsRequired,
        false,
        _streamRetryAttempt,
      );
      return; // Don't retry until GPS is enabled
    }
    print('✓ GPS is enabled');

    // Check permission granted
    print('🔐 Checking location permissions...');
    final permissionStatus = await Geolocator.checkPermission();
    final hasPermission = permissionStatus == LocationPermission.always ||
        permissionStatus == LocationPermission.whileInUse;
    
    if (!hasPermission) {
      print('❌ Location permission not granted (status: $permissionStatus)');
      permissionRequired = true;
      
      // Request permission
      print('📱 Requesting location permission...');
      final newStatus = await Geolocator.requestPermission();
      if (newStatus != LocationPermission.always &&
          newStatus != LocationPermission.whileInUse) {
        print('❌ Permission request failed (status: $newStatus)');
        _notifyErrorRecovery(
          'Location permission required. Please grant permission to continue tracking.',
          false,
          true,
          _streamRetryAttempt,
        );
        return; // Don't retry until permission is granted
      }
      print('✓ Permission granted');
    } else {
      print('✓ Location permission already granted');
    }

    // All conditions met, restart stream
    print('🔄 Conditions met. Restarting location stream...');
    _notifyErrorRecovery(
      'Attempting to restart location stream (attempt #${_streamRetryAttempt + 1})...',
      false,
      false,
      _streamRetryAttempt,
    );

    // Restart with delay
    Future.delayed(_retryDelay, () {
      print('🔄 Retrying location stream (attempt #${_streamRetryAttempt + 1})...');
      _attachLocationStreamWithErrorHandling();
    });
  }

  /// Notify ViewModel of error recovery attempt via callback
  /// This triggers the ViewModel to update error state and UI banner
  static void _notifyErrorRecovery(
    String errorMessage,
    bool gpsRequired,
    bool permissionRequired,
    int retryAttempt,
  ) {
    print('📢 Notifying ViewModel: $errorMessage');
    _onErrorRecovery?.call(
      errorMessage,
      gpsRequired,
      permissionRequired,
      retryAttempt,
    );
  }


  /// Start background tracking for an activity
  /// This also starts the native foreground service to keep the app alive
  static Future<void> startBackgroundTracking(String activityId) async {
    try {
      print('🚀 Starting background tracking for activity: $activityId');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeActivityKey, activityId);
      
      // Start native foreground service to keep app alive
      print('📱 Starting native foreground service...');
      await NativeActivityService.startTracking(activityId);
      
      print('✓ Background tracking started for activity: $activityId');
    } catch (e) {
      print('✗ Error starting background tracking: $e');
    }
  }

  /// Stop background tracking
  static Future<void> stopBackgroundTracking() async {
    try {
      print('⏹ Stopping background tracking...');
      
      _isRecovering = false;
      _streamRetryAttempt = 0;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeActivityKey);
      
      // Stop native foreground service
      print('📱 Stopping native foreground service...');
      await NativeActivityService.stopTracking();
      
      // Cancel location stream
      await _locationStream?.cancel();
      _locationStream = null;
      
      print('✓ Background tracking stopped');
    } catch (e) {
      print('✗ Error stopping background tracking: $e');
    }
  }

  /// Get currently active activity ID
  static Future<String?> getActiveActivityId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeActivityKey);
  }

  /// Record a position update in the background
  static Future<void> _recordPosition(Position position) async {
    try {
      final activeActivityId = await getActiveActivityId();
      if (activeActivityId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final historyKey = '$_locationHistoryKey$activeActivityId';
      
      // Get existing history
      final history = prefs.getStringList(historyKey) ?? [];

      // Create location record with proper JSON encoding
      final locationRecord = {
        'id': const Uuid().v4(),
        'lat': position.latitude,
        'lng': position.longitude,
        'alt': position.altitude,
        'acc': position.accuracy,
        'spd': position.speed,
        'bearing': position.heading,
        'ts': DateTime.now().toIso8601String(),
      };

      // Store JSON-encoded representation
      history.add(jsonEncode(locationRecord));

      // Store updated history (limit to latest 1000 entries for memory)
      if (history.length > 1000) {
        history.removeRange(0, history.length - 1000);
      }
      await prefs.setStringList(historyKey, history);

      print('📍 Background position recorded: (${position.latitude}, ${position.longitude})');
    } catch (e) {
      print('✗ Error recording position: $e');
    }
  }

  /// Get recorded background positions for an activity
  static Future<List<Map<String, dynamic>>> getRecordedPositions(String activityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = '$_locationHistoryKey$activityId';
      final history = prefs.getStringList(historyKey) ?? [];
      
      // Parse the recorded positions from JSON
      List<Map<String, dynamic>> positions = [];
      
      for (final record in history) {
        try {
          // Decode JSON record properly
          final decoded = jsonDecode(record) as Map<String, dynamic>;
          positions.add({
            'id': decoded['id'] ?? '',
            'latitude': (decoded['lat'] as num?)?.toDouble() ?? 0.0,
            'longitude': (decoded['lng'] as num?)?.toDouble() ?? 0.0,
            'altitude': (decoded['alt'] as num?)?.toDouble() ?? 0.0,
            'accuracy': (decoded['acc'] as num?)?.toDouble() ?? 0.0,
            'speed': (decoded['spd'] as num?)?.toDouble() ?? 0.0,
            'bearing': (decoded['bearing'] as num?)?.toDouble() ?? 0.0,
            'timestamp': decoded['ts'] ?? DateTime.now().toIso8601String(),
          });
        } catch (e) {
          print('⚠️ Could not parse location record: $e');
        }
      }
      
      return positions;
    } catch (e) {
      print('✗ Error retrieving positions: $e');
      return [];
    }
  }

  /// Clear recorded background positions for an activity
  static Future<void> clearRecordedPositions(String activityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = '$_locationHistoryKey$activityId';
      await prefs.remove(historyKey);
      print('✓ Cleared recorded positions for activity: $activityId');
    } catch (e) {
      print('✗ Error clearing positions: $e');
    }
  }

  /// Check if location services are available
  static Future<bool> isLocationServiceAvailable() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    return enabled;
  }
}
