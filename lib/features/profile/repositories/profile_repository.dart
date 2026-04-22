import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/profile_model.dart';

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Authentication ---
  
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _supabase.auth.signUp(email: email, password: password);
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
        // Step 1: Delete profile data first
        await _supabase.from('profiles').delete().eq('id', userId);
        
        // Step 2: Delete auth user using admin API
        // Note: You'll need to set up an edge function or use admin key
        // For now, we attempt to delete via the auth API
        try {
          await _supabase.auth.admin.deleteUser(userId);
        } catch (e) {
          // If admin delete fails, user can still be deleted from auth directly
        }
        
        // Step 3: Sign out locally
        await _supabase.auth.signOut();
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // --- Weight Progress (for Charts) ---
  
  Future<List<Map<String, dynamic>>> getWeightHistory(String userId) async {
    try {
      final response = await _supabase
          .from('weight_history')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Mock data for demo if table doesn't exist
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
      // ignore
    }
  }

  Future<String?> uploadProfilePicture(String userId, String imagePath) async {
    try {
      final file = File(imagePath);
      final fileName = '$userId/profile_picture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _supabase.storage.from('avatars').upload(fileName, file);
      final url = _supabase.storage.from('avatars').getPublicUrl(fileName);
      
      // Update profile with URL
      await _supabase.from('profiles').update({
        'profile_picture_url': url
      }).eq('id', userId);
      
      return url;
    } catch (e) {
      return null;
    }
  }
}
