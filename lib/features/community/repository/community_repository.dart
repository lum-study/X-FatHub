import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

class CommunityRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fallback to dummy Alex Fit UUID if not authenticated so local testing works
  String? get currentUserId =>
      _supabase.auth.currentUser?.id ?? '11111111-1111-1111-1111-111111111111';

  Future<List<PostModel>> fetchPosts(String selectedFilter) async {
    if (currentUserId == null) return [];

    // We select the post, inner join to profiles for authorName,
    // and left join to likes/comments for counts.
    final response = await _supabase
        .from('posts')
        .select(
        '*, profiles(name), post_likes(user_id), post_comments(id), post_favourites(user_id)')
        .order('created_at', ascending: false);

    List<PostModel> posts = (response as List).map((map) {
      // Map JSON to dynamic model structure matching what PostModel expects
      return PostModel.fromMap(map, currentUserId: currentUserId);
    }).toList();

    // Map filters locally for simplicity, though this could be done via Supabase queries
    if (selectedFilter == 'Following') {
      final followingResponse = await _supabase
          .from('user_followers')
          .select('following_id')
          .eq('follower_id', currentUserId!);
      final followingIds = (followingResponse as List).map((
          f) => f['following_id']).toSet();
      posts = posts.where((p) => followingIds.contains(p.userId)).toList();
    } else if (selectedFilter == 'Liked') {
      posts = posts.where((p) => p.isLikedByMe).toList();
    } else if (selectedFilter == 'Favourited') {
      posts = posts.where((p) => p.isFavouritedByMe).toList();
    }

    return posts;
  }

  Future<List<PostModel>> fetchUserPosts(String targetUserId) async {
    final response = await _supabase
        .from('posts')
        .select(
        '*, profiles(name), post_likes(user_id), post_comments(id), post_favourites(user_id)')
        .eq('user_id', targetUserId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((map) => PostModel.fromMap(map, currentUserId: currentUserId))
        .toList();
  }

  Future<Map<String, dynamic>?> fetchUserProfileStats(
      String targetUserId) async {
    try {
      final profileResponse = await _supabase
          .from('profiles')
          .select('name, created_at')
          .eq('id', targetUserId)
          .maybeSingle();

      if (profileResponse == null) {
        // If it's returning null, it's highly likely RLS blocked it because 
        // they are viewing someone else's profile or they are unauthenticated using the dummy ID.
        print('Profile not found for ID: $targetUserId. Is RLS blocking this?');
        return null;
      }

      final name = profileResponse['name'] ?? 'Unknown User';
      
      // Safety check if created_at is null
      final joinedDate = profileResponse['created_at'] != null 
          ? DateTime.parse(profileResponse['created_at'])
          : DateTime.now();

      // Count posts
      final postsCountResponse = await _supabase
          .from('posts')
          .select('id')
          .eq('user_id', targetUserId)
          .count(CountOption.exact);
      final postsCount = postsCountResponse.count ?? 0;

      // Count likes received on their posts
      final likesCountResponse = await _supabase
          .from('post_likes')
          .select('id, posts!inner(user_id)')
          .eq('posts.user_id', targetUserId)
          .count(CountOption.exact);
      final likesCount = likesCountResponse.count ?? 0;

      // Count followers
      final followersCountResponse = await _supabase
          .from('user_followers')
          .select('follower_id')
          .eq('following_id', targetUserId)
          .count(CountOption.exact);
      final followersCount = followersCountResponse.count ?? 0;

      return {
        'name': name,
        'joinedDate': joinedDate,
        'totalPosts': postsCount,
        'totalLikes': likesCount,
        'totalFollowers': followersCount,
      };
    } catch (e) {
      print('Error fetching user profile stats: $e');
      return null;
    }
  }

  Future<void> toggleLike(String postId, bool isLiked) async {
    final userId = currentUserId;
    if (userId == null) return;
    if (isLiked) {
      await _supabase.from('post_likes').insert(
          {'post_id': postId, 'user_id': userId});
    } else {
      await _supabase.from('post_likes').delete().match(
          {'post_id': postId, 'user_id': userId});
    }
  }

  Future<void> toggleFavourite(String postId, bool isFavourited) async {
    final userId = currentUserId;
    if (userId == null) return;
    if (isFavourited) {
      await _supabase.from('post_favourites').insert(
          {'post_id': postId, 'user_id': userId});
    } else {
      await _supabase.from('post_favourites').delete().match(
          {'post_id': postId, 'user_id': userId});
    }
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
    final userId = currentUserId;
    if (userId == null) return;

    // Join the URLs if provided
    final joinedMediaUrls = (mediaUrls != null && mediaUrls.isNotEmpty)
        ? mediaUrls.join(',')
        : null;

    final data = {
      'user_id': userId,
      'content': content,
      'media_url': joinedMediaUrls,
      if (locationName != null) 'location_name': locationName,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLng != null) 'location_lng': locationLng,
      if (activityId != null) 'activity_id': activityId,
      if (activityType != null) 'activity_type': activityType,
      if (activityTitle != null) 'activity_title': activityTitle,
      if (activityDurationSeconds != null) 'activity_duration_seconds': activityDurationSeconds,
      if (activityDistance != null) 'activity_distance': activityDistance,
    };

    await _supabase.from('posts').insert(data);
  }

  // --- DELETE POST ---
  Future<void> deletePost(String postId) async {
    final userId = currentUserId;
    if (userId == null) return;
    await _supabase.from('posts').delete().eq('id', postId).eq('user_id', userId);
  }

  // --- FOLLOW ---
  Future<bool> isFollowing(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    final response = await _supabase
        .from('user_followers')
        .select()
        .eq('follower_id', userId)
        .eq('following_id', targetUserId);
    
    return (response as List).isNotEmpty;
  }

  Future<void> toggleFollow(String targetUserId, bool isCurrentlyFollowing) async {
    final userId = currentUserId;
    if (userId == null) return;

    if (isCurrentlyFollowing) {
      await _supabase
          .from('user_followers')
          .delete()
          .eq('follower_id', userId)
          .eq('following_id', targetUserId);
    } else {
      await _supabase.from('user_followers').insert({
        'follower_id': userId,
        'following_id': targetUserId,
      });
    }
  }

  // --- COMMENTS METHODS ---

  Future<List<CommentModel>> getComments(String postId) async {
    final response = await _supabase
        .from('post_comments')
        .select('*, profiles(name)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    final data = response as List;
    return data.map((json) => CommentModel.fromJson(json)).toList();
  }

  Future<CommentModel> addComment(String postId, String userId, String content) async {
    final response = await _supabase.from('post_comments').insert({
      'post_id': postId,
      'user_id': userId,
        'content': content,
      }).select('*, profiles(name)').single();
      
      return CommentModel.fromJson(response);
    }

    Future<void> updatePost(PostModel post) async {
      await _supabase.from('posts').update({
        'content': post.content,
        'media_url': post.mediaUrl,
        'location_name': post.locationName,
        'location_lat': post.locationLat,
        'location_lng': post.locationLng,
        'activity_id': post.activityId,
        'activity_type': post.activityType,
        'activity_title': post.activityTitle,
        'activity_duration_seconds': post.activityDurationSeconds,
        'activity_distance': post.activityDistance,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', post.id);
    }
  }
