import 'package:flutter/foundation.dart';

class PostModel {
  final String id;
  final String userId;
  final String content;
  final String? mediaUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? locationName;
  final double? locationLat;
  final double? locationLng;

  // Activity fields
  final String? activityId;
  final String? activityType;
  final String? activityTitle;
  final int? activityDurationSeconds;
  final double? activityDistance;

  // Helper to split mediaUrl if multiple media exist
  List<String> get mediaUrls {
    if (mediaUrl == null || mediaUrl!.isEmpty) return [];
    return mediaUrl!.split(',').where((e) => e.trim().isNotEmpty).toList();
  }

  bool isVideo(String url) {
    final lower = url.toLowerCase();
    // Typical query separation checking just the path part
    final path = lower.split('?').first;
    return path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi') || path.endsWith('.mkv');
  }

  // Extra fields for UI display
  final String authorName;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;
  final bool isFavouritedByMe;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaUrl,
    required this.createdAt,
    this.updatedAt,
    this.locationName,
    this.locationLat,
    this.locationLng,
    this.activityId,
    this.activityType,
    this.activityTitle,
    this.activityDurationSeconds,
    this.activityDistance,
    this.authorName = 'User',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByMe = false,
    this.isFavouritedByMe = false,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, {String? currentUserId}) {
    final postLikes = map['post_likes'] as List?;
    final postFavs = map['post_favourites'] as List?;

    bool checkIsLiked = false;
    bool checkIsFav = false;
    if (currentUserId != null) {
      if (postLikes != null) {
        checkIsLiked = postLikes.any((like) => like['user_id'] == currentUserId);
      }
      if (postFavs != null) {
        checkIsFav = postFavs.any((fav) => fav['user_id'] == currentUserId);
      }
    }

    return PostModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      mediaUrl: map['media_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      locationName: map['location_name'] as String?,
      locationLat: (map['location_lat'] as num?)?.toDouble(),
      locationLng: (map['location_lng'] as num?)?.toDouble(),
      activityId: map['activity_id'] as String?,
      activityType: map['activity_type'] as String?,
      activityTitle: map['activity_title'] as String?,
      activityDurationSeconds: map['activity_duration_seconds'] as int?,
      activityDistance: (map['activity_distance'] as num?)?.toDouble(),

      // These fields might be joined from other tables in a real query
      authorName: map['profiles']?['name'] ?? 'User',
      likesCount: map['likes_count'] ?? postLikes?.length ?? 0,
      commentsCount: map['comments_count'] ?? map['post_comments']?.length ?? 0,
      isLikedByMe: map['is_liked_by_me'] ?? checkIsLiked,
      isFavouritedByMe: map['is_favourited_by_me'] ?? checkIsFav,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'content': content,
      'media_url': mediaUrl,
      'location_name': locationName,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'activity_id': activityId,
      'activity_type': activityType,
      'activity_title': activityTitle,
      'activity_duration_seconds': activityDurationSeconds,
      'activity_distance': activityDistance,
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? content,
    String? mediaUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? locationName,
    double? locationLat,
    double? locationLng,
    String? activityId,
    String? activityType,
    String? activityTitle,
    int? activityDurationSeconds,
    double? activityDistance,
    String? authorName,
    int? likesCount,
    int? commentsCount,
    bool? isLikedByMe,
    bool? isFavouritedByMe,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locationName: locationName ?? this.locationName,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      activityId: activityId ?? this.activityId,
      activityType: activityType ?? this.activityType,
      activityTitle: activityTitle ?? this.activityTitle,
      activityDurationSeconds: activityDurationSeconds ?? this.activityDurationSeconds,
      activityDistance: activityDistance ?? this.activityDistance,
      authorName: authorName ?? this.authorName,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isFavouritedByMe: isFavouritedByMe ?? this.isFavouritedByMe,
    );
  }
}
