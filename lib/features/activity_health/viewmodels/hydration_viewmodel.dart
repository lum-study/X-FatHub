import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/hydration_model.dart';
import '../repositories/hydration_repository.dart';

/// ViewModel for Hydration Tracker feature
/// Handles business logic, state management, and data flow between Model and View
class HydrationViewModel extends ChangeNotifier {
  final HydrationRepository _repository;

  // State variables
  late HydrationTrackerModel _hydrationData;
  bool _isLoading = false;
  String? _errorMessage;
  List<HydrationEntry> _deletedEntries = []; // For undo functionality
  Map<int, int> _undoTimerIds = {}; // Track undo timers for each entry

  // Getters for exposing state to UI
  HydrationTrackerModel get hydrationData => _hydrationData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  Completer<void>? _initCompleter;
  
  // Convenience getters for common values
  int get todayConsumption => _hydrationData.todayConsumption;
  int get dailyGoal => _hydrationData.dailyGoal;
  double get progress => _hydrationData.progress;
  List<HydrationEntry> get todayEntries => _hydrationData.todayEntries;
  double get consumptionInLiters => _hydrationData.consumptionInLiters;
  double get goalInLiters => _hydrationData.goalInLiters;

  // Constructor
  HydrationViewModel({HydrationRepository? repository})
      : _repository = repository ?? HydrationRepository(),
        _hydrationData = HydrationTrackerModel(
          todayConsumption: 0,
          dailyGoal: 0,
          progress: 0.0,
          todayEntries: [],
          timestamp: DateTime.now(),
        );

  /// Initialize the ViewModel by loading initial data and syncing to remote
  Future<void> init() async {
    // Guard against concurrent initialization - if already initializing, wait for completion
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    
    try {
      await loadHydrationData();
      // Sync goal to remote on page load
      await _repository.syncGoalToRemote();
      _initCompleter?.complete();
    } catch (e) {
      _initCompleter?.completeError(e);
      rethrow;
    }
  }

  /// Load hydration tracker data from repository
  Future<void> loadHydrationData({bool silent = false}) async {
    if (!silent) _setLoading(true);
    _clearError();

    try {
      _hydrationData = await _repository.getHydrationTrackerData();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load hydration data: $e');
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  /// Add a quick hydration entry
  Future<void> addEntry(int amountMl) async {
    _clearError();

    try {
      await _repository.addEntry(dateTime: DateTime.now(), amountMl: amountMl);
      
      // Reload data silently to update UI
      await loadHydrationData(silent: true);
      
      print('✓ Added $amountMl ml hydration entry');
    } catch (e) {
      _setError('Failed to add entry: $e');
    }
  }

  /// Add custom hydration entry
  Future<void> addCustomEntry(int amountMl) async {
    if (amountMl <= 0) {
      _setError('Please enter a valid amount greater than 0');
      return;
    }

    await addEntry(amountMl);
  }

  /// Update a hydration entry's amount
  Future<void> updateEntry(int entryId, int newAmountMl) async {
    if (newAmountMl <= 0) {
      _setError('Please enter a valid amount greater than 0');
      return;
    }

    _clearError();

    try {
      await _repository.updateEntry(entryId: entryId, amountMl: newAmountMl);
      
      // Reload data silently to update UI
      await loadHydrationData(silent: true);
      
      print('✓ Updated entry to $newAmountMl ml');
    } catch (e) {
      _setError('Failed to update entry: $e');
    }
  }

  /// Immediately remove entry from UI, then delete from server
  /// This ensures the Dismissible widget is removed from the tree right away
  /// Returns the deleted entry for undo functionality
  Future<HydrationEntry?> deleteEntry(int entryId) async {
    _clearError();

    try {
      // Find and store the entry for undo
      final entry = _hydrationData.todayEntries
          .firstWhere((e) => e.id == entryId, orElse: () => null as dynamic);

      if (entry == null) {
        return null;
      }

      // Immediately remove from UI (optimistic update)
      _hydrationData = _hydrationData.copyWith(
        todayEntries: _hydrationData.todayEntries
            .where((e) => e.id != entryId)
            .toList(),
        todayConsumption:
            (_hydrationData.todayConsumption - entry.amountMl).clamp(0, 999999),
      );
      _deletedEntries.add(entry as HydrationEntry);
      notifyListeners(); // Notify immediately to remove from UI

      // Delete from server in background
      await _repository.deleteEntry(entryId);

      print('✓ Deleted entry $entryId');
      return entry as HydrationEntry;
    } catch (e) {
      _setError('Failed to delete entry: $e');
      // Reload to restore the entry if deletion failed
      await loadHydrationData(silent: true);
      return null;
    }
  }

  /// Undo the last deleted entry
  Future<void> undoDeleteEntry(HydrationEntry entry) async {
    _clearError();

    try {
      // Re-add the entry
      await _repository.addEntry(
        dateTime: DateTime.parse('${entry.date} ${entry.time}'),
        amountMl: entry.amountMl,
      );

      // Remove from deleted entries list
      _deletedEntries.remove(entry);

      // Reload data silently to update UI
      await loadHydrationData(silent: true);
      
      print('✓ Restored deleted entry');
    } catch (e) {
      _setError('Failed to undo deletion: $e');
    }
  }

  /// Update the user's daily hydration goal
  Future<void> updateGoalMl(int newGoalMl) async {
    if (newGoalMl <= 0) {
      _setError('Goal must be greater than 0');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _repository.setGoalMl(newGoalMl);

      // Recalculate progress with the new goal
      final newProgress = _hydrationData.todayConsumption / newGoalMl;

      _hydrationData = _hydrationData.copyWith(
        dailyGoal: newGoalMl,
        progress: newProgress.clamp(0.0, 1.0),
      );

      notifyListeners();
      print('Goal ml updated to $newGoalMl');
    } catch (e) {
      _setError('Failed to update goal: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sync unsynced entries to Supabase (called at 8:20 AM)
  Future<void> syncToSupabase() async {
    try {
      await _repository.syncToSupabase();
      print('✓ Hydration data synced to Supabase');
    } catch (e) {
      print('Error syncing to Supabase: $e');
    }
  }

  /// Get today's total hydration consumption directly from remote database
  /// Returns the sum of all entries for today in liters
  Future<double> getTodayConsumptionFromRemote() async {
    try {
      final todayEntries = await _repository.getTodayEntries();
      final totalMl = todayEntries.fold<int>(0, (sum, entry) => sum + entry.amountMl);
      return totalMl / 1000.0; // Convert ml to liters
    } catch (e) {
      print('Error getting consumption from remote: $e');
      return 0.0;
    }
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _deletedEntries.clear();
    _undoTimerIds.clear();
    super.dispose();
  }
}
