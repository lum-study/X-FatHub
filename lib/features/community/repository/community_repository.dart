import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/local_community_db.dart';
import '../../../core/database/local_profile_db.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

class CommunityRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fallback to dummy Alex Fit UUID if not authenticated so local testing works
  String? get currentUserId =>
      _supabase.auth.currentUser?.id ?? '11111111-1111-1111-1111-111111111111';

  Future<Map<String, dynamic>?> _buildOfflineOwnProfileStats(String userId) async {
    final localProfile = await LocalProfileDatabase.getProfile(userId);
    final cachedPosts = await LocalCommunityDatabase.getOwnCachedPosts(userId);

    if (localProfile == null && cachedPosts.isEmpty) {
      return null;
    }

    final createdAtStr = localProfile?[LocalProfileDatabase.colCreatedAt] as String?;
    final joinedDate = createdAtStr != null
        ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
        : (cachedPosts.isNotEmpty ? cachedPosts.last.createdAt : DateTime.now());

    final name = (localProfile?[LocalProfileDatabase.colName] as String?)?.trim();
    final avatarUrl = localProfile?[LocalProfileDatabase.colProfilePictureUrl] as String?;
    final totalLikes = cachedPosts.fold<int>(0, (sum, post) => sum + post.likesCount);

    return {
      'name': (name != null && name.isNotEmpty) ? name : 'You',
      'profilePictureUrl': avatarUrl,
      'joinedDate': joinedDate,
      'totalPosts': cachedPosts.length,
      'totalLikes': totalLikes,
      'totalFollowers': 0,
    };
  }

  Future<Map<String, Map<String, String?>>> _fetchPublicProfilesByUserIds(
      Iterable<String> userIds) async {
    final ids = userIds.toSet().toList();
    if (ids.isEmpty) return <String, Map<String, String?>>{};

    final response = await _supabase.rpc(
      'get_public_profiles',
      params: {'p_user_ids': ids},
    );

    final Map<String, Map<String, String?>> profilesById = {};
    for (final row in (response as List)) {
      final id = row['id'] as String?;
      if (id == null) continue;
      profilesById[id] = {
        'name': (row['name'] as String?) ?? 'User',
        'profile_picture_url': row['profile_picture_url'] as String?,
      };
    }
    return profilesById;
  }

  Future<List<PostModel>> fetchPosts(String selectedFilter) async {
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('posts')
        .select(
        '*, post_likes(user_id), post_comments(id), post_favourites(user_id)')
        .order('created_at', ascending: false);

    List<PostModel> posts = (response as List).map((map) {
      return PostModel.fromMap(map, currentUserId: currentUserId);
    }).toList();

    final profilesById = await _fetchPublicProfilesByUserIds(posts.map((p) => p.userId));
    posts = posts
        .map(
          (post) => post.copyWith(
            authorName: profilesById[post.userId]?['name'] ?? post.authorName,
            authorAvatarUrl:
                profilesById[post.userId]?['profile_picture_url'] ?? post.authorAvatarUrl,
          ),
        )
        .toList();

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
    try {
      final response = await _supabase
          .from('posts')
          .select(
          '*, post_likes(user_id), post_comments(id), post_favourites(user_id)')
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false);

      var posts = (response as List)
          .map((map) => PostModel.fromMap(map, currentUserId: currentUserId))
          .toList();

      final profilesById = await _fetchPublicProfilesByUserIds(posts.map((p) => p.userId));
      posts = posts
          .map(
            (post) => post.copyWith(
              authorName: profilesById[post.userId]?['name'] ?? post.authorName,
              authorAvatarUrl:
                  profilesById[post.userId]?['profile_picture_url'] ?? post.authorAvatarUrl,
            ),
          )
          .toList();

      if (currentUserId != null && targetUserId == currentUserId) {
        await LocalCommunityDatabase.saveOwnPosts(userId: targetUserId, posts: posts);
      }

      return posts;
    } catch (e) {
      // Offline fallback for current user's own profile posts.
      if (currentUserId != null && targetUserId == currentUserId) {
        final cachedPosts = await LocalCommunityDatabase.getOwnCachedPosts(targetUserId);
        if (cachedPosts.isNotEmpty) {
          return cachedPosts;
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfileStats(
      String targetUserId) async {
    final isOwnProfile = currentUserId != null && currentUserId == targetUserId;

    try {
      final profileResponse = await _supabase.rpc(
        'get_public_profile',
        params: {'p_user_id': targetUserId},
      ).timeout(const Duration(seconds: 8));

      if (profileResponse == null || profileResponse['success'] != true) {
        print('Profile not found for ID: $targetUserId. Is RLS blocking this?');
        if (isOwnProfile) {
          return await _buildOfflineOwnProfileStats(targetUserId);
        }
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
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 8));
      final postsCount = postsCountResponse.count ?? 0;

      // Count likes received on their posts
      final likesCountResponse = await _supabase
          .from('post_likes')
          .select('id, posts!inner(user_id)')
          .eq('posts.user_id', targetUserId)
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 8));
      final likesCount = likesCountResponse.count ?? 0;

      // Count followers
      final followersCountResponse = await _supabase
          .from('user_followers')
          .select('follower_id')
          .eq('following_id', targetUserId)
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 8));
      final followersCount = followersCountResponse.count ?? 0;

      return {
        'name': name,
        'profilePictureUrl': profileResponse['profile_picture_url'],
        'joinedDate': joinedDate,
        'totalPosts': postsCount,
        'totalLikes': likesCount,
        'totalFollowers': followersCount,
      };
    } catch (e) {
      print('Error fetching user profile stats: $e');
      if (isOwnProfile) {
        return await _buildOfflineOwnProfileStats(targetUserId);
      }
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

    // Keep local cache fresh for offline own-profile view.
    try {
      await fetchUserPosts(userId);
    } catch (_) {
      // Ignore cache refresh errors here; post was already created remotely.
    }
  }

  // --- DELETE POST ---
  Future<void> deletePost(String postId) async {
    final userId = currentUserId;
    if (userId == null) return;
    await _supabase.from('posts').delete().eq('id', postId).eq('user_id', userId);
    await LocalCommunityDatabase.deleteCachedPost(postId, userId);
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
        .select('*')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    final data = response as List;
    var comments = data.map((json) => CommentModel.fromJson(json)).toList();
    final profilesById = await _fetchPublicProfilesByUserIds(comments.map((c) => c.userId));
    comments = comments
        .map(
          (comment) => comment.copyWith(
            authorName: profilesById[comment.userId]?['name'] ?? comment.authorName,
            authorAvatarUrl: profilesById[comment.userId]?['profile_picture_url'] ??
                comment.authorAvatarUrl,
          ),
        )
        .toList();
    return comments;
  }

  Future<CommentModel> addComment(String postId, String userId, String content) async {
    final response = await _supabase.from('post_comments').insert({
      'post_id': postId,
      'user_id': userId,
        'content': content,
      }).select('*').single();

      final comment = CommentModel.fromJson(response);
      final profilesById = await _fetchPublicProfilesByUserIds([userId]);
      return comment.copyWith(
        authorName: profilesById[userId]?['name'] ?? comment.authorName,
        authorAvatarUrl:
            profilesById[userId]?['profile_picture_url'] ?? comment.authorAvatarUrl,
      );
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

      if (currentUserId != null && post.userId == currentUserId) {
        await LocalCommunityDatabase.upsertOwnPost(post);
      }
    }
  }
