import 'package:flutter/material.dart';
import '../models/comment_model.dart';
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

  Future<void> createPost(String content, {
    List<String>? mediaUrls, 
    String? locationName, 
    double? locationLat, 
    double? locationLng,
    String? activityId,
    String? activityType,
    String? activityTitle,
    int? activityDurationSeconds,
    double? activityDistance,
  }) async {
    await _repository.createPost(
      content,
      mediaUrls: mediaUrls,
      locationName: locationName,
      locationLat: locationLat,
      locationLng: locationLng,
      activityId: activityId,
      activityType: activityType,
      activityTitle: activityTitle,
      activityDurationSeconds: activityDurationSeconds,
      activityDistance: activityDistance,
    );
    notifyListeners();
  }

  Future<void> deletePost(String postId) async {
    await _repository.deletePost(postId);
    notifyListeners();
  }

  Future<void> updatePost(PostModel post) async {
    await _repository.updatePost(post);
    notifyListeners();
  }

  Future<bool> isFollowing(String targetUserId) async {
    return await _repository.isFollowing(targetUserId);
  }

  Future<void> toggleFollow(String targetUserId, bool isCurrentlyFollowing) async {
    await _repository.toggleFollow(targetUserId, isCurrentlyFollowing);
    notifyListeners(); // Could also let particular components rebuild themselves
  }

  Future<List<CommentModel>> getComments(String postId) async {
    return await _repository.getComments(postId);
  }

  Future<void> addComment(String postId, String content) async {
    final userId = currentUserId;
    if (userId == null) return;
    await _repository.addComment(postId, userId, content);
    notifyListeners();
  }
}