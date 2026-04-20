import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../views/comments_screen.dart';
import '../models/post_model.dart';
import '../providers/community_provider.dart';
import 'custom_video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String author;
  final String time;
  final IconData avatarIcon;
  final String content;
  final bool hasMedia;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isStarred;
  final VoidTapCallback? onProfileTap;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onStarToggle;
  final VoidCallback? onCommentExit;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.author,
    required this.time,
    required this.avatarIcon,
    required this.content,
    required this.hasMedia,
    required this.likes,
    required this.comments,
    required this.isLiked,
    required this.isStarred,
    this.onProfileTap,
    this.onLikeToggle,
    this.onStarToggle,
    this.onCommentExit,
    this.onDelete,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late bool _isStarred;
  late int _likes;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _isStarred = widget.isStarred;
    _likes = widget.likes;
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked ||
        oldWidget.isStarred != widget.isStarred ||
        oldWidget.likes != widget.likes) {
      _isLiked = widget.isLiked;
      _isStarred = widget.isStarred;
      _likes = widget.likes;
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likes++;
      } else {
        _likes--;
      }
    });

    if (widget.onLikeToggle != null) {
      widget.onLikeToggle!();
    }
  }

  void _toggleStar() {
    setState(() {
      _isStarred = !_isStarred;
    });

    if (widget.onStarToggle != null) {
      widget.onStarToggle!();
    }
  }

  Future<void> _navigateToComments() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CommentsScreen(
          post: widget.post.copyWith(
            isLikedByMe: _isLiked,
            likesCount: _likes,
            isFavouritedByMe: _isStarred,
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
    if (widget.onCommentExit != null) {
      widget.onCommentExit!();
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (widget.onDelete != null) {
        widget.onDelete!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToComments,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border.all(color: const Color(0xFF2A2A2A)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onProfileTap,
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF1E1E1E),
                    child: Icon(widget.avatarIcon, color: Colors.orange),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onProfileTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.author,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.time,
                          style: const TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (context.read<CommunityProvider>().currentUserId == widget.post.userId)
                  Transform.translate(
                    offset: const Offset(12, -10),
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert, color: Color(0xFF555555), size: 18),
                      color: const Color(0xFF1E1E1E),
                      onSelected: (value) {
                        if (value == 'delete') _deletePost();
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete Post', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Content
            Text(
              widget.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFEEEEEE),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Optional Location Tag
            if (widget.post.locationName != null && widget.post.locationLat != null && widget.post.locationLng != null)
              GestureDetector(
                onTap: () async {
                  final lat = widget.post.locationLat!;
                  final lng = widget.post.locationLng!;
                  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                  try {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open map.')),
                      );
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.orange, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.post.locationName!,
                          style: const TextStyle(color: Colors.orange, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Optional Media
            if (widget.post.mediaUrls.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      border: Border.all(color: const Color(0xFF222222)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: widget.post.isVideo(widget.post.mediaUrls.first)
                          ? CustomVideoPlayer(
                              videoUrl: widget.post.mediaUrls.first,
                              autoPlay: false,
                              showControls: false,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              widget.post.mediaUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.broken_image, color: Color(0xFF555555), size: 40));
                              },
                            ),
                    ),
                  ),
                ),
              ),

            // Actions
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF2A2A2A),
                    style: BorderStyle.none,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const Divider(color: Color(0xFF2A2A2A), height: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _toggleLike,
                        behavior: HitTestBehavior.opaque,
                        child: _buildActionBtn(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          '$_likes',
                          isActive: _isLiked,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToComments,
                        behavior: HitTestBehavior.opaque,
                        child: _buildActionBtn(
                          Icons.chat_bubble_outline,
                          '${widget.comments}',
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleStar,
                        behavior: HitTestBehavior.opaque,
                        child: _buildActionBtn(
                          _isStarred ? Icons.star : Icons.star_border,
                          '',
                          isActive: _isStarred,
                        ),
                      ),
                      _buildActionBtn(Icons.share, ''),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String text, {bool isActive = false}) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: isActive ? Colors.orange : const Color(0xFF888888),
            size: 18,
          ),
          if (text.isNotEmpty) const SizedBox(width: 6),
          if (text.isNotEmpty)
            Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.orange : const Color(0xFF888888),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

typedef VoidTapCallback = void Function();
