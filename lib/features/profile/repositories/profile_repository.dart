import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/profile_model.dart';
import 'package:flutter/foundation.dart';

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Authentication ---
  
  Future<AuthResponse> signUp({required String email, required String password}) async {
    // We tell Supabase to redirect back to the app scheme directly
    // This avoids needing a real website during testing
    return await _supabase.auth.signUp(
      email: email, 
      password: password,
      emailRedirectTo: kIsWeb ? null : 'xfathub://auth/verified',
    );
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  // --- Profile CRUD ---

  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      return ProfileModel.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile(ProfileModel profile) async {
    try {
      final data = profile.toMap();
      data['updated_at'] = DateTime.now().toIso8601String();
      await _supabase
          .from('profiles')
          .upsert(data, onConflict: 'id');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('profiles').delete().eq('id', userId);
        try {
          await _supabase.auth.admin.deleteUser(userId);
        } catch (e) {
        }
        await _supabase.auth.signOut();
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // --- Weight Progress ---
  
  Future<List<Map<String, dynamic>>> getWeightHistory(String userId) async {
    try {
      final response = await _supabase
          .from('weight_history')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [
        {'recorded_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(), 'weight': 85.0},
        {'recorded_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(), 'weight': 83.5},
        {'recorded_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(), 'weight': 82.0},
        {'recorded_at': DateTime.now().toIso8601String(), 'weight': 80.5},
      ];
    }
  }

  Future<void> addWeightEntry(String userId, double weight) async {
    try {
      await _supabase.from('weight_history').insert({
        'user_id': userId,
        'weight': weight,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
    }
  }

  Future<String?> uploadProfilePicture(String userId, String imagePath) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        throw Exception('User not authenticated');
      }

      final file = File(imagePath);
      final fileName = '$userId/profile_picture_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from('avatars').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      final url = _supabase.storage.from('avatars').getPublicUrl(fileName);

      await _supabase
          .from('profiles')
          .upsert({
            'id': userId,
            'email': authUser.email,
            'profile_picture_url': url,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'id');

      return url;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<void> updateCurrentWeight(String userId, double currentWeight) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('profiles')
          .upsert({
            'id': userId,
            'email': authUser.email,
            'current_weight': currentWeight,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'id');

      await addWeightEntry(userId, currentWeight);
    } catch (e) {
      throw Exception('Failed to update current weight: $e');
    }
  }
}
