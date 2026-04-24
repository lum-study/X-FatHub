import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';
import '../../activity_health/repositories/step_tracker_repository.dart';
import '../../activity_health/repositories/hydration_repository.dart';
import '../../../core/database/local_profile_db.dart';

final _supabase = Supabase.instance.client;

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;
  
  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _weightHistory = [];

  ProfileViewModel({ProfileRepository? repository}) 
      : _repository = repository ?? ProfileRepository();

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get weightHistory => _weightHistory;
  
  bool get isAuthenticated => Supabase.instance.client.auth.currentSession != null;
  
  bool get needsProfileSetup => _profile != null && !_profile!.profileCompleted;

  Future<void> init() async {
    final user = _repository.currentUser;
    if (user != null) {
      await loadProfile(user.id);
      await loadWeightHistory(user.id);
    }
  }

  Future<void> loadProfile(String userId) async {
    _setLoading(true);
    try {
      // Try to get from local first
      final localProfile = await LocalProfileDatabase.getProfile(userId);
      
      // Then try to get from remote
      _profile = await _repository.getProfile(userId);
      
      // Save to local
      if (_profile != null) {
        await LocalProfileDatabase.saveProfile(_profile!.toMap(), synced: true);
      } else if (localProfile != null) {
        // Use local if remote fails
        _profile = ProfileModel.fromMap(localProfile);
      }
      
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadWeightHistory(String userId) async {
    try {
      _weightHistory = await _repository.getWeightHistory(userId);
      notifyListeners();
    } catch (e) {
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    int? age,
    String? gender,
    DateTime? birthdate,
    double? currentWeight,
    double? initialWeight,
    double? weightGoal,
    double? height,
    int? stepsGoal,
    int? hydrationGoal, // Changed to int (ML) to match ProfileModel
    String? profilePictureUrl,
    bool? profileCompleted,
  }) async {
    final user = _repository.currentUser;
    if (user == null) return;

    final currentProfile = _profile ?? ProfileModel(id: user.id, email: user.email!);
    
    // Logic: Only update currentWeight to initialWeight if initialWeight has actually changed.
    double? resolvedCurrentWeight = currentWeight;
    if (resolvedCurrentWeight == null) {
      if (initialWeight != null && initialWeight != currentProfile.initialWeight) {
        // Initial weight changed, so we also update current weight to the new starting point
        resolvedCurrentWeight = initialWeight;
      } else {
        // Keep existing current weight progress
        resolvedCurrentWeight = currentProfile.currentWeight ?? initialWeight;
      }
    }

    // Ensure values are passed correctly to copyWith
    final updatedProfile = currentProfile.copyWith(
      name: name,
      bio: bio,
      age: age,
      gender: gender,
      birthdate: birthdate,
      currentWeight: resolvedCurrentWeight,
      initialWeight: initialWeight,
      weightGoal: weightGoal,
      height: height,
      stepsGoal: stepsGoal,
      hydrationGoal: hydrationGoal,
      profilePictureUrl: profilePictureUrl,
      profileCompleted: profileCompleted,
    );

    _setLoading(true);
    _error = null;
    try {
      // Save to local first (offline support)
      await LocalProfileDatabase.saveProfile(updatedProfile.toMap(), synced: false);
      
      // Then try to sync to remote
      await _repository.updateProfile(updatedProfile);
      await LocalProfileDatabase.updateSyncStatus(user.id, true);
      
      _profile = updatedProfile;
      notifyListeners();

      try {
        if (updatedProfile.stepsGoal != null) {
          await StepTrackerRepository().setGoalSteps(updatedProfile.stepsGoal!);
        }

        if (updatedProfile.hydrationGoal != null) {
          // Already in ML now
          await HydrationRepository().setGoalMl(updatedProfile.hydrationGoal!);
        }
      } catch (_) {
      }
    } catch (e) {
      _error = e.toString();
      // Even if sync fails, update local state if possible
      _profile = updatedProfile;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncPendingUpdates() async {
    try {
      final unsyncedProfiles = await LocalProfileDatabase.getUnsyncedProfiles();
      for (final profileData in unsyncedProfiles) {
        try {
          await _repository.updateProfile(ProfileModel.fromMap(profileData));
          await LocalProfileDatabase.updateSyncStatus(profileData['id'], true);
        } catch (e) {
          // Skip this one, will try again later
        }
      }
    } catch (e) {
      // Ignore sync errors
    }
  }

  // Authentication methods
  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    try {
      await _repository.signUp(email: email, password: password);
      _error = null;
      await _repository.signOut();
    } catch (e) {
      _error = _getReadableErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _repository.signIn(email: email, password: password);
      await init();
      _error = null;
    } catch (e) {
      _error = _getReadableErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  String _getReadableErrorMessage(dynamic e) {
    String msg = e.toString();
    if (msg.contains('invalid_credentials')) return 'Invalid email or password';
    if (msg.contains('email_not_confirmed')) return 'Please confirm your email first';
    if (msg.contains('user_already_exists')) return 'This email is already registered';
    return msg;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _profile = null;
    _weightHistory = [];
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      final user = _repository.currentUser;
      if (user?.email == null) {
        throw Exception('User not authenticated');
      }

      await _repository.signIn(
        email: user!.email!,
        password: currentPassword,
      );

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      _error = null;
    } catch (e) {
      _error = _getReadableErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    _setLoading(true);
    try {
      await _repository.deleteAccount();
      if (_profile != null) {
        await LocalProfileDatabase.deleteProfile(_profile!.id);
      }
      _profile = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> uploadProfilePicture(String imagePath) async {
    if (_profile == null) {
      throw Exception('Profile not loaded');
    }
    
    _setLoading(true);
    try {
      final url = await _repository.uploadProfilePicture(_profile!.id, imagePath);
      if (url != null) {
        _profile = _profile!.copyWith(profilePictureUrl: url);
        await LocalProfileDatabase.saveProfile(_profile!.toMap(), synced: true);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCurrentWeightOnly(double newWeight) async {
    final user = _repository.currentUser;
    if (user == null || _profile == null) {
      throw Exception('Profile not loaded');
    }

    try {
      await _repository.updateCurrentWeight(user.id, newWeight);
      _profile = _profile!.copyWith(currentWeight: newWeight);
      await LocalProfileDatabase.saveProfile(_profile!.toMap(), synced: true);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
