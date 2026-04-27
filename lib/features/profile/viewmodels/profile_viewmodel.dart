import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;

  ProfileViewModel({ProfileRepository? repository}) 
      : _repository = repository ?? ProfileRepository() {
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    notifyListeners();
  }

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get weightHistory => _weightHistory;
  bool get isOnline => _isOnline;
  
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
      final localProfile = await LocalProfileDatabase.getProfile(userId);
      
      if (_isOnline) {
        _profile = await _repository.getProfile(userId);
        if (_profile != null) {
          await LocalProfileDatabase.saveProfile(_profile!.toMap(), synced: true);
        }
      }
      
      if (_profile == null && localProfile != null) {
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
    int? hydrationGoal,
    String? profilePictureUrl,
    bool? profileCompleted,
  }) async {
    if (!_isOnline) {
      throw Exception('Cannot update profile while offline');
    }

    final user = _repository.currentUser;
    if (user == null) return;

    final currentProfile = _profile ?? ProfileModel(id: user.id, email: user.email!);
    
    double? resolvedCurrentWeight = currentWeight;
    if (resolvedCurrentWeight == null) {
      if (initialWeight != null && initialWeight != currentProfile.initialWeight) {
        resolvedCurrentWeight = initialWeight;
      } else {
        resolvedCurrentWeight = currentProfile.currentWeight ?? initialWeight;
      }
    }

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
      await _repository.updateProfile(updatedProfile);
      await LocalProfileDatabase.saveProfile(updatedProfile.toMap(), synced: true);
      
      _profile = updatedProfile;
      notifyListeners();

      try {
        if (updatedProfile.stepsGoal != null) {
          await StepTrackerRepository().setGoalSteps(updatedProfile.stepsGoal!);
        }

        if (updatedProfile.hydrationGoal != null) {
          await HydrationRepository().setGoalMl(updatedProfile.hydrationGoal!);
        }
      } catch (_) {
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password) async {
    if (!_isOnline) {
      throw Exception('No internet connection. Please connect and try again.');
    }
    _setLoading(true);
    _error = null;
    try {
      await _repository.signUp(email: email, password: password);
      await _repository.signOut();
    } catch (e) {
      _error = _getReadableErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn(String email, String password) async {
    if (!_isOnline) {
      throw Exception('No internet connection. Please connect and try again.');
    }
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
    final String message = (e is AuthException ? e.message : e.toString()).toLowerCase();

    if (message.contains('invalid') && message.contains('credentials')) {
      return 'Invalid email or password';
    }
    
    if (message.contains('email not confirmed') || message.contains('email_not_confirmed')) {
      return 'Please verify your email first';
    }
    
    if (message.contains('already registered') || message.contains('user_already_exists')) {
      return 'This email is already registered. Please Proceed to Login';
    }
    
    if ((e is AuthException && e.statusCode == '429') || message.contains('rate_limit')) {
      return 'Too many requests. Please wait a few minutes before trying again.';
    }

    if (e is Exception && e.toString().contains('No internet connection')) {
      return 'No internet connection. Please connect and try again.';
    }

    if (e is AuthException) return e.message;
    return e.toString();
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
    if (!_isOnline) {
      throw Exception('Cannot change password while offline');
    }
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
    if (!_isOnline) {
      throw Exception('Cannot delete account while offline');
    }
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
    if (!_isOnline) {
      throw Exception('Cannot upload profile picture while offline');
    }
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
    if (!_isOnline) {
      throw Exception('Cannot update weight while offline');
    }
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
