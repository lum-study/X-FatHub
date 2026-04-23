import 'package:flutter/foundation.dart';
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
          dailyGoal: 2000,
          progress: 0.0,
          todayEntries: [],
          timestamp: DateTime.now(),
        );

  /// Initialize the ViewModel by loading initial data and syncing to remote
  Future<void> init() async {
    await loadHydrationData();
    // Sync goal to remote on page load
    await _repository.syncGoalToRemote();
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

  /// Delete a hydration entry with undo capability
  /// Returns the deleted entry for undo functionality
  Future<HydrationEntry?> deleteEntry(int entryId) async {
    _clearError();

    try {
      // Get the entry before deletion for undo
      final entry = await _repository.getEntryById(entryId);
      
      if (entry != null) {
        _deletedEntries.add(entry);
      }

      await _repository.deleteEntry(entryId);
      
      // Reload data silently to update UI
      await loadHydrationData(silent: true);
      
      print('✓ Deleted entry $entryId');
      return entry;
    } catch (e) {
      _setError('Failed to delete entry: $e');
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

  /// Sync unsynced entries to Supabase (called at 11:59 PM)
  Future<void> syncToSupabase() async {
    try {
      await _repository.syncToSupabase();
      print('✓ Hydration data synced to Supabase');
    } catch (e) {
      print('Error syncing to Supabase: $e');
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
