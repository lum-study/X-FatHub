import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;
  
  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _weightHistory = [];

  ProfileProvider({ProfileRepository? repository}) 
      : _repository = repository ?? ProfileRepository();

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get weightHistory => _weightHistory;
  
  // Custom getter to check if user is truly logged in via session
  bool get isAuthenticated => Supabase.instance.client.auth.currentSession != null;
  
  /// Check if the user needs to complete their profile setup
  bool get needsProfileSetup => _profile != null && !_profile!.profileCompleted;

  Future<void> init() async {
    final user = _repository.currentUser;
    if (user != null) {
      print('ProfileProvider init - loading profile for user: ${user.id}');
      await loadProfile(user.id);
      await loadWeightHistory(user.id);
      print('Profile loaded: profileCompleted=${_profile?.profileCompleted}');
    }
  }

  Future<void> loadProfile(String userId) async {
    _setLoading(true);
    try {
      print('Loading profile for user: $userId');
      _profile = await _repository.getProfile(userId);
      print('Profile loaded: ${_profile?.name}, completed=${_profile?.profileCompleted}');
      _error = null;
      notifyListeners();
    } catch (e) {
      print('Error loading profile: $e');
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
      print('Error loading weight history: $e');
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
      initialWeight: initialWeight ?? currentProfile.initialWeight ?? currentWeight, // Use current weight if initial weight not set
      weightGoal: weightGoal ?? currentProfile.weightGoal,
      height: height ?? currentProfile.height,
      stepsGoal: stepsGoal ?? currentProfile.stepsGoal,
      hydrationGoal: hydrationGoal ?? currentProfile.hydrationGoal,
      profilePictureUrl: profilePictureUrl ?? currentProfile.profilePictureUrl,
      profileCompleted: profileCompleted ?? currentProfile.profileCompleted,
    );

    _setLoading(true);
    try {
      await _repository.updateProfile(updatedProfile);
      _profile = updatedProfile;
      _error = null;
      notifyListeners(); // Notify listeners of the change
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Authentication methods
  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    try {
      await _repository.signUp(email: email, password: password);
      _error = null;
      // After signup, manually sign out to prevent auto-login
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

  Future<void> deleteAccount() async {
    _setLoading(true);
    try {
      await _repository.deleteAccount();
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
}
