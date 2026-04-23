import 'package:flutter/foundation.dart';
import 'dart:async';
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
  Completer<void>? _initCompleter;

  ProfileViewModel({ProfileRepository? repository}) 
      : _repository = repository ?? ProfileRepository();

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get weightHistory => _weightHistory;
  
  bool get isAuthenticated => Supabase.instance.client.auth.currentSession != null;
  
  bool get needsProfileSetup => _profile != null && !_profile!.profileCompleted;

  Future<void> init() async {
    // Guard against concurrent initialization - if already initializing, wait for completion
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    
    try {
      final user = _repository.currentUser;
      if (user != null) {
        await _repository.ensureProfileRecord(user);
        await loadProfile(user.id);
        await loadWeightHistory(user.id);
      }
      _initCompleter?.complete();
    } catch (e) {
      _initCompleter?.completeError(e);
      rethrow;
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
    double? currentWeight,
    double? initialWeight,
    double? weightGoal,
    double? height,
    int? stepsGoal,
    double? hydrationGoal,
    String? profilePictureUrl,
    bool? profileCompleted,
  }) async {
    final user = _repository.currentUser;
    if (user == null) return;

    final currentProfile = _profile ?? ProfileModel(id: user.id, email: user.email!);

    final updatedProfile = currentProfile.copyWith(
      name: name ?? currentProfile.name,
      bio: bio ?? currentProfile.bio,
      age: age ?? currentProfile.age,
      currentWeight: currentWeight ?? currentProfile.currentWeight,
      initialWeight: initialWeight ?? (currentProfile.initialWeight != null 
          ? currentProfile.initialWeight 
          : currentWeight),
      weightGoal: weightGoal ?? currentProfile.weightGoal,
      height: height ?? currentProfile.height,
      stepsGoal: stepsGoal ?? currentProfile.stepsGoal,
      hydrationGoal: hydrationGoal ?? currentProfile.hydrationGoal,
      profilePictureUrl: profilePictureUrl ?? currentProfile.profilePictureUrl,
      profileCompleted: profileCompleted ?? currentProfile.profileCompleted,
    );

    _setLoading(true);
    try {
      // Save to local first (offline support)
      await LocalProfileDatabase.saveProfile(updatedProfile.toMap(), synced: false);
      
      // Then try to sync to remote
      try {
        await _repository.updateProfile(updatedProfile);
        await LocalProfileDatabase.updateSyncStatus(user.id, true);
      } catch (e) {
        // Keep local version, will sync later
      }
      
      _profile = updatedProfile;
      _error = null;
      notifyListeners();

      try {
        if (updatedProfile.stepsGoal != null) {
          await StepTrackerRepository().setGoalSteps(updatedProfile.stepsGoal!);
        }

        if (updatedProfile.hydrationGoal != null) {
          final ml = (updatedProfile.hydrationGoal! * 1000).round();
          await HydrationRepository().setGoalMl(ml);
        }
      } catch (_) {
      }
    } catch (e) {
      _error = e.toString();
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
      final authResponse = await _repository.signIn(email: email, password: password);
      final signedInUser = authResponse.user;
      if (signedInUser != null) {
        await _repository.ensureProfileRecord(signedInUser);
      }
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
    if (_profile == null) return;
    
    _setLoading(true);
    try {
      final url = await _repository.uploadProfilePicture(_profile!.id, imagePath);
      if (url != null) {
        _profile = _profile!.copyWith(profilePictureUrl: url);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
}