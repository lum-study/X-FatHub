import 'package:flutter/foundation.dart';

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;

  // Extra metadata
  final String authorName;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName = 'User',
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Determine author name from joined 'profiles' table if available
    String author = 'User';
    if (json['profiles'] != null && json['profiles'] is Map) {
      author = json['profiles']['name'] ?? 'User';
    }

    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      authorName: author,
    );
  }
}
