import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/activity_model.dart';
import '../models/activity_location_point.dart';
import '../repositories/activity_repository.dart';
import '../../../core/service/location_tracking_service.dart';
import '../../../core/service/permission_service.dart';
import '../../../core/service/background_location_service.dart';

/// ViewModel for live activity tracking feature
/// Handles real-time location tracking, metrics calculation, and state management
class ActivityTrackingViewModel extends ChangeNotifier {
  final ActivityRepository _repository;
  
  // Current activity being tracked
  late ActivityModel _currentActivity;
  
  // State variables
  bool _isTracking = false;
  bool _isPaused = false;
  String? _errorMessage;
  bool _isLoading = false;
  
  // Real-time metrics
  double _currentDistance = 0.0;
  double _currentPace = 0.0;
  double _maxSpeed = 0.0;
  double _estimatedCalories = 0.0;
  Duration _elapsedTime = Duration.zero;
  
  // Location tracking
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription? _timerSubscription;
  StreamSubscription? _connectivitySubscription;
  ActivityLocationPoint? _lastLocationPoint;
  int _locationUpdateCount = 0;
  List<ActivityLocationPoint> _routePoints = [];
  bool _isRecording = false;  // Flag to track whether to save data to DB
  
  // Error recovery tracking
  int _locationRetryCount = 0;
  DateTime? _lastLocationError;
  Duration _retryDelay = const Duration(seconds: 5);
  
  // User data for metrics calculation
  double _userBodyWeight = 70.0; // Default weight in kg

  // Getters for UI
  ActivityModel get currentActivity => _currentActivity;
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  
  double get currentDistance => _currentDistance;
  double get currentPace => _currentPace;
  double get maxSpeed => _maxSpeed;
  double get estimatedCalories => _estimatedCalories;
  Duration get elapsedTime => _elapsedTime;
  int get locationUpdateCount => _locationUpdateCount;
  List<ActivityLocationPoint> get routePoints => _routePoints;
  bool get hasInitialLocation => _lastLocationPoint != null;
  ActivityLocationPoint? get currentLocation => _lastLocationPoint;
  
  // Formatted strings for UI display
  String get formattedDistance =>
      '${_currentDistance.toStringAsFixed(2)} km';
  String get formattedPace =>
      '${_currentPace.toStringAsFixed(2)} km/h';
  String get formattedCalories =>
      '${_estimatedCalories.toStringAsFixed(0)} kcal';
  String get formattedElapsedTime {
    final hours = _elapsedTime.inHours;
    final minutes = _elapsedTime.inMinutes.remainder(60);
    final seconds = _elapsedTime.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  ActivityTrackingViewModel({ActivityRepository? repository})
      : _repository = repository ?? ActivityRepository(),
        _currentActivity = ActivityModel(
          id: '',
          userId: '',
          activityType: 'walk',
          startTime: DateTime.now(),
          createdAt: DateTime.now(),
        );

  /// Initialize ViewModel and request permissions
  Future<void> init(String userId, double? bodyWeight) async {
    _setLoading(true);
    _clearError();

    try {
      print('📱 ===== ACTIVITY TRACKING INITIALIZATION =====');
      
      // Register error recovery callback from background service
      // This receives notifications when foreground service encounters tracking errors
      BackgroundLocationService.setErrorRecoveryCallback(
        (errorMessage, gpsRequired, permissionRequired, retryAttempt) {
          print('📢 Error recovery notification: $errorMessage (GPS: $gpsRequired, Permission: $permissionRequired, Attempt: $retryAttempt)');
          
          if (gpsRequired) {
            _setError('🗺️ GPS is disabled. Please enable GPS to continue tracking.');
          } else if (permissionRequired) {
            _setError('🔐 Location permission required. Please grant permission to continue tracking.');
          } else {
            // Generic recovery message
            _setError(errorMessage);
          }
          
          notifyListeners(); // Trigger UI banner update
        },
      );
      
      // Set user body weight for calorie calculation
      if (bodyWeight != null && bodyWeight > 0) {
        _userBodyWeight = bodyWeight;
      }

      // Request required permissions
      print('🔐 Requesting location permissions...');
      final hasPermissions =
          await PermissionService.requestActivityTrackingPermissions();
      if (!hasPermissions) {
        _setError('Location permission required. Please enable in Settings > Apps > XFatHub > Permissions > Location');
        _setLoading(false);
        print('❌ Location permission denied');
        return;
      }
      print('✓ Permissions granted');

      // Check location services
      print('🗺️  Checking location services...');
      final isLocationEnabled =
          await LocationTrackingService.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        _setError('Location services disabled. Please enable Location in device settings');
        _setLoading(false);
        print('❌ Location services disabled');
        return;
      }
      print('✓ Location services enabled');

      // Test getting current location
      print('📍 Testing current location...');
      final testLocation = await LocationTrackingService.getCurrentLocation();
      if (testLocation == null) {
        _setError('Cannot get current location. Ensure GPS is enabled and you have clear sky view');
        _setLoading(false);
        print('❌ Cannot get current location');
        return;
      }
      print('✓ Current location: ${testLocation.latitude}, ${testLocation.longitude}');
      
      // Store location as reference point (for map display before recording starts)
      _lastLocationPoint = ActivityLocationPoint(
        id: 'ref_${DateTime.now().millisecondsSinceEpoch}',
        activityId: '',  // Not recording yet, so no activityId
        latitude: testLocation.latitude,
        longitude: testLocation.longitude,
        altitude: testLocation.altitude,
        accuracy: testLocation.accuracy,
        speed: testLocation.speed,
        timestamp: DateTime.now(),
        sequenceNumber: 0,
      );
      print('✓ Reference location obtained');

      // Start location tracking (continuous GPS updates, not recording to DB yet)
      print('🟢 Starting location tracking (preview mode)...');
      _isRecording = false;  // Not recording yet
      _startLocationTracking();
      print('✓ Location tracking started - ready for user to press Start');

      print('✅ Activity tracking initialized successfully');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Initialization error: $e');
      _setLoading(false);
      print('❌ Exception during initialization: $e');
    }
  }

  /// Start a new activity session
  Future<void> startActivity({
    required String userId,
    required String activityType,
    String? title,
    String? description,
  }) async {
    _clearError();

    try {
      print('🎬 Starting activity: $activityType');
      
      // Create activity in repository
      final activityId = await _repository.createActivity(
        userId: userId,
        activityType: activityType,
        title: title,
        description: description,
      );

      // Fetch the created activity
      final activity = await _repository.getActivityById(activityId);
      if (activity == null) {
        _setError('Failed to create activity');
        print('❌ Activity creation failed');
        return;
      }

      print('✓ Activity created: $activityId');

      _currentActivity = activity.copyWith(status: ActivityStatus.active);
      _isTracking = true;
      _isPaused = false;

      // Store current location as start location
      print('📍 Storing start location...');
      if (_lastLocationPoint != null) {
        _currentActivity = _currentActivity.copyWith(
          startLatitude: _lastLocationPoint!.latitude,
          startLongitude: _lastLocationPoint!.longitude,
        );
        print('✓ Start location: ${_lastLocationPoint!.latitude}, ${_lastLocationPoint!.longitude}');
      } else {
        print('⚠️  No location point available');
      }

      // Enable recording to database from this point onwards
      print('🔴 START RECORDING - enabling database storage...');
      _isRecording = true;
      _locationUpdateCount = 0;  // Reset counter for new activity
      _routePoints.clear();  // Clear any preview points

      // Enable background location tracking
      print('🔐 Enabling background location tracking...');
      try {
        await LocationTrackingService.requestBackgroundLocationPermission();
        await BackgroundLocationService.startBackgroundTracking(activityId);
        print('✓ Background tracking enabled for activity: $activityId');
      } catch (e) {
        print('⚠️ Could not enable background tracking: $e (will continue with foreground tracking)');
      }

      // Start elapsed time timer
      print('⏱️  Starting timer...');
      _startElapsedTimer();

      await _repository.updateActivityStatus(
        activityId,
        ActivityStatus.active,
      );

      print('✅ Activity started successfully: $activityId');
      notifyListeners();
    } catch (e) {
      _setError('Error starting activity: $e');
      _isTracking = false;
      print('❌ Failed to start activity: $e');
    }
  }

  /// Pause the current activity
  Future<void> pauseActivity() async {
    if (!_isTracking || _isPaused) return;

    try {
      _isPaused = true;
      _locationSubscription?.pause();
      _timerSubscription?.pause();

      await _repository.updateActivityStatus(
        _currentActivity.id,
        ActivityStatus.paused,
      );

      print('⏸ Activity paused');
      notifyListeners();
    } catch (e) {
      _setError('Error pausing activity: $e');
    }
  }

  /// Resume a paused activity
  Future<void> resumeActivity() async {
    if (!_isTracking || !_isPaused) return;

    try {
      _isPaused = false;
      _locationSubscription?.resume();
      _timerSubscription?.resume();

      await _repository.updateActivityStatus(
        _currentActivity.id,
        ActivityStatus.active,
      );

      print('▶ Activity resumed');
      notifyListeners();
    } catch (e) {
      _setError('Error resuming activity: $e');
    }
  }

  /// Complete and save the current activity
  Future<bool> completeActivity() async {
    if (!_isTracking) return false;

    try {
      print('🛑 Completing activity...');
      _isTracking = false;
      _isPaused = false;

      // Disable background tracking
      print('🔐 Disabling background tracking...');
      try {
        await BackgroundLocationService.stopBackgroundTracking();
        print('✓ Background tracking disabled');
      } catch (e) {
        print('⚠️ Error disabling background tracking: $e');
      }

      // Stop all tracking immediately
      print('⏹ Stopping location tracking...');
      await _stopLocationTracking();
      print('⏹ Stopping timer...');
      _stopElapsedTimer();

      // Update activity with final data
      _currentActivity = _currentActivity.copyWith(
        status: ActivityStatus.completed,
        endTime: DateTime.now(),
        totalDuration: _elapsedTime,
        distanceTraveled: _currentDistance,
        stepCount: 0,
        caloriesBurned: _estimatedCalories,
        averagePace: _calculateAveragePace(),
        maxSpeed: _maxSpeed,
        endLatitude: _lastLocationPoint?.latitude,
        endLongitude: _lastLocationPoint?.longitude,
      );

      // Save to repository
      print('💾 Saving activity to database...');
      await _repository.updateActivityStatus(
        _currentActivity.id,
        ActivityStatus.completed,
      );

      await _repository.updateActivityMetrics(
        activityId: _currentActivity.id,
        distanceTraveled: _currentDistance,
        stepCount: 0,
        caloriesBurned: _estimatedCalories,
        averagePace: _calculateAveragePace(),
        maxSpeed: _maxSpeed,
      );

      // Save the total duration
      await _repository.updateActivityDuration(
        activityId: _currentActivity.id,
        duration: _elapsedTime,
      );

      // Attempt to sync to server
      print('🔄 Syncing to server...');
      await _repository.syncActivityToServer(_currentActivity);

      // Clear all tracking data
      print('🧹 Clearing all tracking data...');
      _resetActivityState();
      _clearError();

      print('✅ Activity completed and data cleared: ${_currentActivity.id}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error completing activity: $e');
      print('❌ Error during activity completion: $e');
      return false;
    }
  }

  /// Discard the current activity (don't save)
  Future<void> discardActivity() async {
    try {
      print('🛑 Discarding activity...');
      _isTracking = false;
      _isPaused = false;

      // Disable background tracking
      print('🔐 Disabling background tracking...');
      try {
        await BackgroundLocationService.stopBackgroundTracking();
        print('✓ Background tracking disabled');
      } catch (e) {
        print('⚠️ Error disabling background tracking: $e');
      }

      // Stop all tracking immediately
      print('⏹ Stopping location tracking...');
      await _stopLocationTracking();
      print('⏹ Stopping timer...');
      _stopElapsedTimer();

      // Update status to discarded
      print('💾 Marking activity as discarded...');
      await _repository.updateActivityStatus(
        _currentActivity.id,
        ActivityStatus.discarded,
      );

      // Delete from database
      print('🗑️ Deleting activity from database...');
      await _repository.deleteActivity(_currentActivity.id);

      // Clear all tracking data
      print('🧹 Clearing all tracking data...');
      _resetActivityState();
      _clearError();

      // Reset current activity to empty state
      _currentActivity = ActivityModel(
        id: '',
        userId: '',
        activityType: 'walk',
        startTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      print('✅ Activity discarded and data cleared');
      notifyListeners();
    } catch (e) {
      _setError('Error discarding activity: $e');
      print('❌ Error during activity discard: $e');
    }
  }

  /// Start real-time location tracking with error recovery
  void _startLocationTracking() {
    _locationSubscription?.cancel();
    _locationRetryCount = 0;
    _lastLocationError = null;
    _clearError();

    _attachLocationListener();
    _startConnectivityMonitoring();
  }

  /// Attach location listener with automatic retry on error
  void _attachLocationListener() {
    try {
      print('📡 Subscribing to location stream (5m update interval, attempt #${_locationRetryCount + 1})...');
      _locationSubscription =
          LocationTrackingService.startLocationTracking(updateInterval: 5)
              .listen(
        (Position position) {
          if (!_isTracking) return; // Stop if tracking was stopped
          if (_locationRetryCount > 0) {
            print('✅ Location recovered on attempt #${_locationRetryCount + 1}!');
            _locationRetryCount = 0; // Reset retry count on successful update
          }
          print('📍 Location update received: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');
          _processLocationUpdate(position);
        },
        onError: (error) {
          if (!_isTracking) return; // Don't retry if user stopped tracking
          
          _lastLocationError = DateTime.now();
          _locationRetryCount++;
          print('⚠️ [LOCATION ERROR] Stream error (attempt #$_locationRetryCount): $error');
          print('🔄 Will retry in ${_retryDelay.inSeconds} seconds...');
          _setError('Location temporarily unavailable. Retrying in ${_retryDelay.inSeconds}s...');
          
          // Retry after fixed 5 second delay
          Future.delayed(_retryDelay, () {
            if (_isTracking) {
              print('🔄 Retrying location tracking (attempt #${_locationRetryCount + 1})...');
              _attachLocationListener();
            }
          });
        },
      );

      print('✓ Location tracking listener attached');
    } catch (e) {
      if (!_isTracking) return;
      
      _lastLocationError = DateTime.now();
      _locationRetryCount++;
      print('⚠️ [LOCATION ERROR] Error attaching listener (attempt #$_locationRetryCount): $e');
      print('🔄 Will retry in ${_retryDelay.inSeconds} seconds...');
      _setError('Failed to start tracking. Retrying in ${_retryDelay.inSeconds}s...');
      
      // Retry after fixed 5 second delay
      Future.delayed(_retryDelay, () {
        if (_isTracking) {
          print('🔄 Retrying location tracking attachment (attempt #${_locationRetryCount + 1})...');
          _attachLocationListener();
        }
      });
    }
  }

  /// Monitor connectivity and auto-recover when connection returns
  void _startConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (result) {
        if (!_isTracking || _isPaused) return;
        
        final hasConnection = result != ConnectivityResult.none;
        print('📡 Connectivity changed: $result (has connection: $hasConnection)');
        
        // If connection recovered and we had recent errors, retry location
        if (hasConnection && _lastLocationError != null) {
          final timeSinceError = DateTime.now().difference(_lastLocationError!);
          if (timeSinceError.inSeconds < 60) {
            print('🔄 Connection recovered! Attempting to restart location tracking...');
            _locationRetryCount = 0;
            _attachLocationListener();
          }
        }
      },
    );
  }

  /// Process location update with error handling
  Future<void> _processLocationUpdate(Position position) async {
    try {
      if (!_isTracking) return; // Stop if tracking was stopped
      
      print('🔄 Processing location: ${position.latitude}, ${position.longitude} (recording: $_isRecording)');
      
      // Update UI with current position (for map display)
      notifyListeners();

      // Only save to database and calculate metrics if recording
      if (!_isRecording) {
        print('📍 Preview mode - location shown on map, not saved to DB');
        
        // Update reference point for map display
        _lastLocationPoint = ActivityLocationPoint(
          id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
          activityId: '',
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          accuracy: position.accuracy,
          speed: position.speed,
          timestamp: DateTime.now(),
          sequenceNumber: -1,
        );
        return;
      }

      // Recording mode - calculate metrics and save to DB
      print('📍 Recording mode - saving to database...');

      // Calculate distance from last recorded point
      if (_lastLocationPoint != null && _lastLocationPoint!.activityId!.isNotEmpty) {
        final segmentDistance = LocationTrackingService.calculateDistance(
          _lastLocationPoint!.latitude,
          _lastLocationPoint!.longitude,
          position.latitude,
          position.longitude,
        );

        _currentDistance += segmentDistance;
        print('✓ Distance segment: ${segmentDistance.toStringAsFixed(3)}km | Total: ${_currentDistance.toStringAsFixed(3)}km');

        // Update max speed (convert m/s to km/h for consistency with pace display)
        final speedKmh = position.speed * 3.6; // Convert m/s to km/h
        if (speedKmh > _maxSpeed) {
          _maxSpeed = speedKmh;
          print('⚡ New max speed: ${_maxSpeed.toStringAsFixed(2)} km/h');
        }

        // Recalculate pace
        if (_elapsedTime.inSeconds > 0) {
          _currentPace =
              (_currentDistance / _elapsedTime.inSeconds) * 3600; // Convert to km/h
          print('📊 Current pace: ${_currentPace.toStringAsFixed(2)} km/h');
        }
      }

      // Create location point for this recorded update
      final locationPoint = ActivityLocationPoint(
        id: '${_currentActivity.id}_${DateTime.now().millisecondsSinceEpoch}',
        activityId: _currentActivity.id,
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        speed: position.speed,
        timestamp: DateTime.now(),
        sequenceNumber: _locationUpdateCount,
      );

      // Add to cached route points
      _routePoints.add(locationPoint);

      // Save to repository
      await _repository.addLocationPoint(
        activityId: _currentActivity.id,
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        speed: position.speed,
      );

      _lastLocationPoint = locationPoint;
      _locationUpdateCount++;
      print('📍 Location count: $_locationUpdateCount | Route points: ${_routePoints.length}');

      // Recalculate calories
      _recalculateCalories();

      // Update activity in repository
      await _repository.updateActivityMetrics(
        activityId: _currentActivity.id,
        distanceTraveled: _currentDistance,
        stepCount: 0,
        caloriesBurned: _estimatedCalories,
        averagePace: _currentPace,
        maxSpeed: _maxSpeed,
      );

      notifyListeners();
    } catch (e) {
      if (!_isTracking) return; // Silently return if tracking stopped
      
      print('⚠️ [LOCATION PROCESSING ERROR] Error processing location update: $e');
      // Continue tracking despite processing errors - don't stop
      // Show warning but keep tracking active
      _clearError(); // Clear previous error to avoid duplicate messages
    }
  }

  /// Stop location tracking
  Future<void> _stopLocationTracking() async {
    print('⏹ Stopping location tracking...');
    _locationRetryCount = 0;
    _lastLocationError = null;
    
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    
    print('✅ Location tracking stopped');
  }

  /// Start elapsed time timer
  void _startElapsedTimer() {
    print('⏱️ Starting elapsed time timer...');
    _timerSubscription?.cancel();
    _timerSubscription = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (!_isPaused) {
        _elapsedTime += const Duration(seconds: 1);

        // Recalculate pace
        if (_elapsedTime.inSeconds > 0) {
          _currentPace =
              (_currentDistance / _elapsedTime.inSeconds) * 3600; // km/h
        }

        notifyListeners();
      }
    });
    print('✅ Timer started');
  }

  /// Stop elapsed time timer
  void _stopElapsedTimer() {
    print('⏹ Stopping elapsed time timer...');
    _timerSubscription?.cancel();
    _timerSubscription = null;
    print('✅ Timer stopped');
  }

  /// Recalculate calories based on distance, body weight, and time
  void _recalculateCalories() {
    // Formula: Calories = Distance(km) × Body Weight(kg) × 0.75
    _estimatedCalories = _currentDistance * _userBodyWeight * 0.75;
  }

  /// Calculate average pace in km/h
  double _calculateAveragePace() {
    if (_elapsedTime.inSeconds == 0) return 0.0;
    return (_currentDistance / _elapsedTime.inSeconds) * 3600;
  }

  /// Reset activity state - clears all tracking data
  void _resetActivityState() {
    print('🔄 Resetting all activity state...');
    
    // Clear tracking state
    _isTracking = false;
    _isPaused = false;
    
    // Clear metrics
    _currentDistance = 0.0;
    _currentPace = 0.0;
    _maxSpeed = 0.0;
    _estimatedCalories = 0.0;
    _elapsedTime = Duration.zero;
    _locationUpdateCount = 0;
    
    // Clear route points but keep initial location for start button
    _routePoints.clear();
    
    // Clear user weight
    _userBodyWeight = 70.0;
    
    print('✅ All activity state cleared (initial location retained for Start button)');
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    print('❌ Error: $message');
  }

  /// Clear error
  void _clearError() {
    _errorMessage = null;
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Get current route points
  Future<List<ActivityLocationPoint>> getRoutePoints() async {
    return await _repository.getRoutePoints(_currentActivity.id);
  }

  /// Get activity summary
  Future<Map<String, dynamic>> getActivitySummary() async {
    return await _repository.getActivitySummary(_currentActivity.id);
  }

  @override
  void dispose() {
    print('🧹 ViewModel dispose called');
    
    // Stop all tracking if still running
    if (_isTracking) {
      print('⚠️ Activity still tracking during dispose - stopping...');
      _isTracking = false;
      _locationSubscription?.cancel();
      _timerSubscription?.cancel();
    }
    
    // Ensure all subscriptions are cancelled
    _locationSubscription?.cancel();
    _timerSubscription?.cancel();
    _locationSubscription = null;
    _timerSubscription = null;
    
    // Clear all state
    _resetActivityState();
    _clearError();
    
    print('✅ ViewModel disposed cleanup complete');
    super.dispose();
  }
}
