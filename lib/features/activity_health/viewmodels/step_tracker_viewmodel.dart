import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/step_tracker_model.dart';
import '../repositories/step_tracker_repository.dart';
import '../../../core/service/permission_service.dart';
import '../../../core/service/pedometer_service.dart';
import '../../../core/database/local_step_db.dart';

/// ViewModel for Step Tracker feature
/// Handles business logic, state management, and data flow between Model and View
class StepTrackerViewModel extends ChangeNotifier {
  final StepTrackerRepository _repository;
  StreamSubscription? _stepCountStreamSubscription;

  // State variables
  late StepTrackerModel _stepTrackerData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _sensorAvailable = false;
  late int _previousStepCount = 0;
  late DateTime _lastActivityTime = DateTime.now();
  bool _showInactivityReminder = false;
  bool _isFirstLoadComplete = false; // Flag to show UI only after initial load

  // Getters for exposing state to UI
  StepTrackerModel get stepTrackerData => _stepTrackerData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get sensorAvailable => _sensorAvailable;
  bool get hasError => _errorMessage != null;
  bool get showInactivityReminder => _showInactivityReminder;
  bool get isFirstLoadComplete => _isFirstLoadComplete;

  // Convenience getters for common values
  int get steps => _stepTrackerData.steps;
  int get goalSteps => _stepTrackerData.goalSteps;
  double get distance => _stepTrackerData.distance;
  double get progress => _stepTrackerData.progress;
  double get kcal => _stepTrackerData.kcal;

  // Constructor
  StepTrackerViewModel({StepTrackerRepository? repository})
      : _repository = repository ?? StepTrackerRepository(),
        _stepTrackerData = StepTrackerModel(
          steps: 0,
          goalSteps: 10000,
          distance: 0.0,
          progress: 0.0,
          kcal: 0.0,
          timestamp: DateTime.now(),
        );

  /// Initialize the ViewModel by requesting permissions and loading initial data
  /// This should be called once when the step tracker feature is first accessed
  Future<void> init() async {
    _setLoading(true);
    _isFirstLoadComplete = false; // Mark as not complete until done
    
    // Request activity recognition permission first
    final hasPermission = await PermissionService.requestStepTrackerPermissions();
    if (!hasPermission) {
      _setError('Activity recognition permission is required for step tracking');
      _setLoading(false);
      return;
    }

    // Initialize pedometer and set up real-time listening
    final pedometerInitialized = await PedometerService.initPedometer();
    if (pedometerInitialized) {
      // Give pedometer enough time to receive the first sensor event
      // This ensures step count data is available when we load
      await Future.delayed(const Duration(seconds: 2));
      _setupStepCountListener();
    }

    // Check if sensor is available
    await _checkSensorAvailability();
    
    // Load step tracker data (pedometer should have data by now)
    await loadStepTrackerData();
    
    // Sync goal to remote on page load
    await _repository.syncGoalToRemote();
    
    // Mark initial load as complete - UI can now be displayed
    _isFirstLoadComplete = true;
    _setLoading(false);
    notifyListeners();
  }

  /// Set up listener for real-time step count updates
  void _setupStepCountListener() {
    try {
      _stepCountStreamSubscription?.cancel();
      _stepCountStreamSubscription = PedometerService.stepCountStream().listen(
        (stepCount) {
          print('Real-time steps updated: ${stepCount.steps}');
          // Update last activity time when steps increase
          if (stepCount.steps > _previousStepCount) {
            _lastActivityTime = DateTime.now();
            _previousStepCount = stepCount.steps;
          }
          // Reload data silently when step count changes to avoid UI flicker
          loadStepTrackerData(silent: true);
        },
        onError: (error) {
          print('Error in step count stream: $error');
          _setError('Error tracking steps: $error');
        },
      );
      print('Step count listener set up successfully');
    } catch (e) {
      print('Error setting up step count listener: $e');
    }
  }

  /// Load step tracker data from repository
  /// [silent] if true, won't trigger the loading state (used for real-time updates)
  Future<void> loadStepTrackerData({bool silent = false}) async {
    if (!silent) _setLoading(true);
    _clearError();

    try {
      _stepTrackerData = await _repository.getStepTrackerData();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load step tracker data: $e');
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  /// Update the user's daily step goal
  /// Persists the new goal to Supabase
  Future<void> updateGoalSteps(int newGoalSteps) async {
    if (newGoalSteps <= 0) {
      _setError('Goal steps must be greater than 0');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _repository.setGoalSteps(newGoalSteps);

      // Recalculate progress with the new goal
      final newProgress = _stepTrackerData.steps / newGoalSteps;

      _stepTrackerData = _stepTrackerData.copyWith(
        goalSteps: newGoalSteps,
        progress: newProgress.clamp(0.0, 1.0),
      );

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update goal: $e');
      _setLoading(false);
    }
  }

  /// Refresh step tracker data from sensors and database
  /// Returns a Future that completes when refresh is done
  /// This will:
  /// - Reset and reinitialize pedometer (like app startup)
  /// - Give pedometer time to read fresh sensor data
  /// - Fetch fresh data from pedometer
  /// - Save to local SQLite database
  /// - Update UI with new values
  Future<void> refreshData() async {
    try {
      _clearError();
      _setLoading(true);
      
      // Reset pedometer and reinitialize it (fresh sensor read)
      await PedometerService.resetPedometer();
      
      final pedometerInitialized = await PedometerService.initPedometer();
      if (pedometerInitialized) {
        // Give pedometer time to receive fresh sensor events
        await Future.delayed(const Duration(seconds: 2));
        
        // Reset activity tracking for fresh data
        _previousStepCount = await PedometerService.getTodaySteps();
        _lastActivityTime = DateTime.now();
      }
      
      // Load fresh data from pedometer and save to local DB
      await loadStepTrackerData(silent: false);
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to refresh data: $e');
      _setLoading(false);
    }
  }

  /// Check if the device has a step sensor available
  Future<void> _checkSensorAvailability() async {
    try {
      _sensorAvailable = await _repository.isSensorAvailable();
      notifyListeners();
    } catch (e) {
      print('Could not check sensor availability: $e');
      _sensorAvailable = false;
    }
  }

  /// Get progress as a percentage (0-100)
  double getProgressPercentage() {
    return (progress * 100).clamp(0.0, 100.0);
  }

  /// Get remaining steps to reach the goal
  int getRemainingSteps() {
    final remaining = goalSteps - steps;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if daily goal is achieved
  bool isGoalAchieved() {
    return steps >= goalSteps;
  }

  /// Format distance as a readable string
  String formatDistance() {
    return distance.toStringAsFixed(1);
  }

  /// Format kcal as a readable whole number
  String formatKcal() {
    return kcal.round().toString();
  }

  /// Format steps with comma separators (e.g., 8,150)
  String formatSteps() {
    print(steps.toString());
    return steps.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Get last update time
  String getLastUpdateTime() {
    final now = DateTime.now();
    final diff = now.difference(_stepTrackerData.timestamp);
    
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  /// Check if user has been inactive for 1 hour
  /// Returns true if no steps detected in the last 1 hour
  bool isUserInactive() {
    final now = DateTime.now();
    final inactiveTime = now.difference(_lastActivityTime);
    return inactiveTime.inHours >= 1;
  }

  /// Get inactivity duration in hours
  int getInactivityHours() {
    final now = DateTime.now();
    final inactiveTime = now.difference(_lastActivityTime);
    return inactiveTime.inHours;
  }

  /// Update inactivity reminder visibility
  void updateInactivityReminder() {
    _showInactivityReminder = isUserInactive();
    notifyListeners();
  }

  /// Reset all step tracker data in the local database
  /// This clears all recorded steps
  Future<void> resetData() async {
    try {
      _setLoading(true);
      // Clear all data from local database
      await LocalStepDatabase.deleteOldRecords();
      
      // Reset to today with 0 steps
      _stepTrackerData = _stepTrackerData.copyWith(
        steps: 0,
        distance: 0.0,
        progress: 0.0,
        kcal: 0.0,
        dailySteps: [0, 0, 0, 0, 0, 0, 0],
      );
      
      _previousStepCount = 0;
      _lastActivityTime = DateTime.now();
      _showInactivityReminder = false;
      
      _setLoading(false);
      notifyListeners();
      print('✓ Step tracker data reset successfully');
    } catch (e) {
      _setError('Failed to reset data: $e');
      _setLoading(false);
    }
  }

  /// Get dynamic day labels starting from 6 days ago to today
  /// Returns only the first character of each day
  /// For example, if today is Thursday, returns ['F', 'S', 'S', 'M', 'T', 'W', 'T']
  List<String> getDynamicDayLabels() {
    const allDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1; // Convert to 0-indexed (0 = Monday, 6 = Sunday)
    
    // Build labels from 6 days ago to today
    final labels = <String>[];
    for (int i = 0; i < 7; i++) {
      // Calculate which day of week this position represents (6 days ago + i)
      final dayIndex = ((today - 6 + i) % 7 + 7) % 7; // Handle negative modulo properly
      labels.add(allDays[dayIndex]);
    }
    return labels;
  }

  /// Get a readable date range string for the last 7 days
  /// For example: "Mar 21 - Mar 27" or "Last 7 Days"
  String getDayRangeLabel() {
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    
    if (sevenDaysAgo.month == today.month) {
      // Same month
      return '${_getDayName(sevenDaysAgo)} ${sevenDaysAgo.day} - ${_getDayName(today)} ${today.day}';
    } else {
      // Different months
      return '${_getMonthAbbr(sevenDaysAgo)} ${sevenDaysAgo.day} - ${_getMonthAbbr(today)} ${today.day}';
    }
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getMonthAbbr(DateTime date) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month];
  }

  /// Get the full day name for a given index (0-6, where 0 is 6 days ago)
  /// For example, if today is Thursday, index 0 returns "Friday" (6 days ago)
  String getFullDayName(int index) {
    const fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final today = DateTime.now().weekday - 1; // 0-indexed (0=Monday, 6=Sunday)
    final dayIndex = ((today - 6 + index) % 7 + 7) % 7;
    return fullDays[dayIndex];
  }

  /// Get the date string for a given index (0-6, where 0 is 6 days ago)
  /// Returns format like "Mar 21"
  String getDateForIndex(int index) {
    final date = DateTime.now().subtract(Duration(days: 6 - index));
    final monthAbbr = _getMonthAbbr(date);
    return '$monthAbbr ${date.day}';
  }

  /// Get tooltip text for a bar showing day, date, and step count
  String getBarTooltip(int index, int steps) {
    final day = getFullDayName(index);
    final date = getDateForIndex(index);
    return '$day, $date\n$steps steps';
  }

  /// Clear all errors
  void _clearError() {
    _errorMessage = null;
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Dispose resources and clean up streams
  @override
  void dispose() {
    _stepCountStreamSubscription?.cancel();
    super.dispose();
  }
}
