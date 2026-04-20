import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../repository/community_repository.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityRepository _repository = CommunityRepository();

  String? get currentUserId => _repository.currentUserId;

  Future<List<PostModel>> fetchPosts(String selectedFilter) async {
    return await _repository.fetchPosts(selectedFilter);
  }

  Future<List<PostModel>> fetchUserPosts(String targetUserId) async {
    return await _repository.fetchUserPosts(targetUserId);
  }

  Future<Map<String, dynamic>?> fetchUserProfileStats(
      String targetUserId) async {
    return await _repository.fetchUserProfileStats(targetUserId);
  }

  Future<void> toggleLike(String postId, bool isLiked) async {
    await _repository.toggleLike(postId, isLiked);
    notifyListeners();
  }

  Future<void> toggleFavourite(String postId, bool isFavourited) async {
    await _repository.toggleFavourite(postId, isFavourited);
    notifyListeners();
  }

  Future<void> createPost(String content, {String? mediaUrl, String? category}) async {
    await _repository.createPost(
        content, mediaUrl: mediaUrl, category: category);
    notifyListeners();
  }
}