import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/step_tracker_model.dart';
import '../repositories/step_tracker_repository.dart';
import '../../../core/service/permission_service.dart';
import '../../../core/service/pedometer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          goalSteps: 0,
          distance: 0.0,
          progress: 0.0,
          kcal: 0.0,
          timestamp: DateTime.now(),
        );

  /// Initialize the ViewModel by requesting permissions and loading initial data
  /// This should be called once when the step tracker feature is first accessed
  Completer<void>? _initCompleter;

  Future<void> init() async {
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();

    try {
      if (_isFirstLoadComplete) {
        _initCompleter?.complete();
        return;
      }

      _setLoading(true);
      _isFirstLoadComplete = false;

      // 1. Permissions
      final hasPermission = await PermissionService.requestStepTrackerPermissions();
      if (!hasPermission) {
        _setError('Activity recognition permission is required for step tracking');
        _setLoading(false);
        _initCompleter?.complete();
        return;
      }

      // 2. Initialize pedometer & check sensor
      final pedometerInitialized = await PedometerService.initPedometer();
      await _checkSensorAvailability();

      // 2a. Force fresh sensor read immediately after initialization
      // This ensures we get the latest value from the device, not cached data
      if (pedometerInitialized) {
        await PedometerService.getTodayStepsCalculated(refreshFromSensor: true);
        print('✓ Fresh sensor read completed during initialization');
      }

      // 3. Get today's steps from Supabase (remote source of truth)
      final supabaseSteps = await _repository.getTodayStepsFromRemoteChecked();

      if (supabaseSteps > 0) {
        // Retrieve the last synced sensor value (stored during previous save)
        final prefs = await SharedPreferences.getInstance();
        final lastSyncedSensor = prefs.getInt(PedometerService.lastSyncedSensorValueKey) ?? 0;
        await PedometerService.restoreFromSyncPoint(supabaseSteps, lastSyncedSensor);
        print('✓ Restored pedometer from sync point: steps=$supabaseSteps, lastSensor=$lastSyncedSensor');
      } else {
        // No remote steps for today – start from 0
        await PedometerService.hardReset();
        print('✓ No remote steps found – pedometer reset to 0');
      }

      // 4. Set up real-time listener (if sensor available)
      if (pedometerInitialized) {
        await Future.delayed(const Duration(seconds: 2));
        _setupStepCountListener();
      }

      // 5. Load full UI data and sync goal
      await loadStepTrackerData(forceRefresh: true);
      await _repository.syncGoalToRemote();

      // 6. Mark as complete
      _isFirstLoadComplete = true;
      _setLoading(false);
      notifyListeners();
      _initCompleter?.complete();
    } catch (e) {
      _setError('Initialization error: $e');
      _setLoading(false);
      _initCompleter?.completeError(e);
    }
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
  /// [forceRefresh] if true, forces fresh sensor reads instead of using cached values
  Future<void> loadStepTrackerData({bool silent = false, bool forceRefresh = false}) async {
    if (!silent) _setLoading(true);
    _clearError();

    try {
      _stepTrackerData = await _repository.getStepTrackerData(forceRefresh: forceRefresh);
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
  /// - Reset and reinitialize pedometer (fresh sensor read)
  /// - Give pedometer time to read fresh sensor data
  /// - Sync current steps to Supabase
  /// - Fetch fresh data from Supabase
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
        _previousStepCount = await PedometerService.getTodayStepsCalculated(
          refreshFromSensor: true,
        );
        _lastActivityTime = DateTime.now();
        
        // Sync current steps to Supabase
        await _repository.saveTodaySteps(_previousStepCount);
        print('✓ Synced ${ _previousStepCount} steps to Supabase on refresh');
      }
      
      // Load fresh data from pedometer and Supabase
      await loadStepTrackerData(silent: false, forceRefresh: true);
      
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

  /// Reset all step tracker data - deletes ALL records from Supabase
  /// This is a destructive operation that removes all historical step data
  Future<void> resetData() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Delete all step records from Supabase for current user
      await _repository.deleteAllStepRecords();

      // Reset local pedometer baseline and persist today's zero steps
      await PedometerService.resetTodaySteps();
      await _repository.saveTodaySteps(0);
      
      // Reset UI state to today with 0 steps
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
      print('✓ All step tracker data reset successfully - remote records deleted');
    } catch (e) {
      _setError('Failed to reset data: $e');
      _setLoading(false);
      rethrow;
    }
  }

  /// Clear all data in provider and reset pedometer baseline
  /// Called on logout
  Future<void> clearData() async {
    try {
      final currentSteps = await PedometerService.getTodayStepsCalculated(refreshFromSensor: true);
      await _repository.saveTodaySteps(currentSteps);
      print('✓ Final steps ($currentSteps) saved before logout');
    } catch (e) {
      print('⚠ Failed to save final steps: $e');
    }

    _stepCountStreamSubscription?.cancel();
    _stepCountStreamSubscription = null;
    
    // Reset local pedometer baseline
    await PedometerService.hardReset();
    
    _stepTrackerData = StepTrackerModel(
      steps: 0,
      goalSteps: 0,
      distance: 0.0,
      progress: 0.0,
      kcal: 0.0,
      timestamp: DateTime.now(),
      dailySteps: [0, 0, 0, 0, 0, 0, 0],
    );
    _previousStepCount = 0;
    _isFirstLoadComplete = false;
    _initCompleter = null;
    _errorMessage = null;
    notifyListeners();
    print('✓ StepTrackerViewModel data cleared and pedometer reset');
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

  /// Get today's steps from repository (Supabase first, then pedometer)
  /// This is used by dashboard and works even before pedometer is initialized
  Future<int> getTodayStepsFromRepository() async {
    try {
      return await _repository.getTodaySteps();
    } catch (e) {
      print('Error getting steps from repository: $e');
      return 0;
    }
  }

  /// Refresh step data and sync current pedometer reading to remote
  /// Call this when entering the module or pulling down to refresh
  Future<void> refreshAndSyncSteps() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Get current pedometer reading
      final currentSteps = await PedometerService.getTodayStepsCalculated(
        refreshFromSensor: true,
      );
      
      // Sync to Supabase
      await _repository.saveTodaySteps(currentSteps);
      print('✓ Synced $currentSteps steps to Supabase');
      
      // Reload the full tracker data
      await loadStepTrackerData(silent: true);
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to sync steps: $e');
      _setLoading(false);
    }
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
