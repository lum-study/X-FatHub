import 'package:flutter/foundation.dart';

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;

  // Extra metadata
  final String authorName;
  final String? authorAvatarUrl;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName = 'User',
    this.authorAvatarUrl,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Determine author name from joined 'profiles' table if available
    String author = json['author_name'] as String? ?? 'User';
    String? avatarUrl = json['author_avatar_url'] as String?;
    if (json['profiles'] != null && json['profiles'] is Map) {
      author = json['profiles']['name'] ?? 'User';
      avatarUrl = json['profiles']['profile_picture_url'] as String? ?? avatarUrl;
    }

    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      authorName: author,
      authorAvatarUrl: avatarUrl,
    );
  }

  CommentModel copyWith({
    String? authorName,
    String? authorAvatarUrl,
  }) {
    return CommentModel(
      id: id,
      postId: postId,
      userId: userId,
      content: content,
      createdAt: createdAt,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
    );
  }
}
