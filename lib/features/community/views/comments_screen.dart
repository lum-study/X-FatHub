import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../activity_health/repositories/activity_repository.dart';
import '../../activity_health/views/activity_summary_screen.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../providers/community_provider.dart';
import '../widgets/custom_video_player.dart';
import 'community_profile_screen.dart';
import 'new_post_screen.dart';

class CommentsScreen extends StatefulWidget {
  final PostModel post;

  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  late bool _isLiked;
  late int _likesCount;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByMe;
    _likesCount = widget.post.likesCount;
    _loadComments();
    _checkFollowing();
  }

  Future<void> _checkFollowing() async {
    final provider = context.read<CommunityProvider>();
    if (provider.currentUserId == widget.post.userId) return;
    final following = await provider.isFollowing(widget.post.userId);
    if (mounted) {
      setState(() => _isFollowing = following);
    }
  }

  Future<void> _toggleFollow() async {
    final provider = context.read<CommunityProvider>();
    final newStatus = !_isFollowing;
    setState(() => _isFollowing = newStatus);
    await provider.toggleFollow(widget.post.userId, !newStatus);
  }

  Future<void> _navigateToProfile() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CommunityProfileScreen(userId: widget.post.userId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
    _loadComments();
    _checkFollowing();
  }

  Future<void> _navigateToUserProfile(String userId) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CommunityProfileScreen(userId: userId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
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
      try {
        final provider = context.read<CommunityProvider>();
        await provider.deletePost(widget.post.id);
        if (mounted) Navigator.pop(context); // Go back after delete
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: $e')),
          );
        }
      }
    }
  }

  void _showMagnifiedImage(BuildContext context, String imageUrl) {
    final isVideo = widget.post.isVideo(imageUrl);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: isVideo 
                  ? CustomVideoPlayer(
                      videoUrl: imageUrl,
                      showControls: true,
                      autoPlay: true,
                      loop: true,
                      fit: BoxFit.contain, // Don't cutoff video
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                      ),
                    ),
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      if (_isLiked) {
        _likesCount--;
      } else {
        _likesCount++;
      }
      _isLiked = !_isLiked;
    });
    context.read<CommunityProvider>().toggleLike(widget.post.id, _isLiked);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final provider = context.read<CommunityProvider>();
      final comments = await provider.getComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final provider = context.read<CommunityProvider>();
      await provider.addComment(widget.post.id, text);
      
      _commentController.clear();
      FocusScope.of(context).unfocus();
      
      // Reload comments to show the new one
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final diff = DateTime.now().difference(post.createdAt);
    String timeStr = diff.inDays > 0
        ? '${diff.inDays} days ago'
        : diff.inHours > 0
            ? '${diff.inHours} hours ago'
            : '${diff.inMinutes} mins ago';

    if (post.updatedAt != null && post.updatedAt!.difference(post.createdAt).inSeconds > 5) {
      final updatedDiff = DateTime.now().difference(post.updatedAt!);
      final updatedTimeStr = updatedDiff.inDays > 0
          ? '${updatedDiff.inDays} days ago'
          : updatedDiff.inHours > 0
              ? '${updatedDiff.inHours} hours ago'
              : '${updatedDiff.inMinutes} mins ago';
      timeStr += ' (updated $updatedTimeStr)';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Comments',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Original Post highlighting
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _navigateToProfile,
                            child: CircleAvatar(
                              backgroundColor: Color(0xFF1E1E1E),
                              backgroundImage: (post.authorAvatarUrl != null && post.authorAvatarUrl!.isNotEmpty)
                                  ? NetworkImage(post.authorAvatarUrl!)
                                  : null,
                              child: (post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty)
                                  ? const Icon(Icons.person, color: Colors.orange)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: _navigateToProfile,
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.authorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      color: Color(0xFF777777),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (context.read<CommunityProvider>().currentUserId == post.userId)
                            Transform.translate(
                              offset: const Offset(12, -10),
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_vert, color: Color(0xFF555555), size: 18),
                                color: const Color(0xFF1E1E1E),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => NewPostScreen(editingPost: post),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    _deletePost();
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Text('Edit Post', style: TextStyle(color: Colors.white)),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Delete Post', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: _toggleFollow,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _isFollowing ? Colors.transparent : Colors.orange,
                                  border: Border.all(color: Colors.orange),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _isFollowing ? 'Following' : 'Follow',
                                  style: TextStyle(
                                    color: _isFollowing ? Colors.orange : Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.content,
                        style: const TextStyle(
                          color: Color(0xFFEEEEEE),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                                            // Optional Activity Tag
                      if (post.activityType != null)
                        GestureDetector(
                          onTap: () async {
                            if (post.activityId != null) {
                              final activity = await ActivityRepository().getActivityById(post.activityId!);
                              if (activity != null && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ActivitySummaryScreen(
                                      activity: activity,
                                      routePoints: activity.routePoints,
                                    ),
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Activity details not found')),
                                );
                              }
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.withOpacity(0.15), Colors.transparent],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              border: const Border(left: BorderSide(color: Colors.orange, width: 4)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.fitness_center, color: Colors.orange, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.activityTitle ?? '${post.activityType![0].toUpperCase()}${post.activityType!.substring(1)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            '${(post.activityDistance ?? 0.0).toStringAsFixed(2)} km',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                          if (post.activityDurationSeconds != null) ...[
                                            const Text(' • ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                            Text(
                                              '${(post.activityDurationSeconds! ~/ 3600).toString().padLeft(2, '0')}:${((post.activityDurationSeconds! % 3600) ~/ 60).toString().padLeft(2, '0')}:${(post.activityDurationSeconds! % 60).toString().padLeft(2, '0')}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.orange, size: 20),
                              ],
                            ),
                          ),
                        ),
                      
                      // Optional Location Tag
                      if (post.locationName != null && post.locationLat != null && post.locationLng != null)
                        GestureDetector(
                          onTap: () async {
                            final lat = post.locationLat!;
                            final lng = post.locationLng!;
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
                                    post.locationName!,
                                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Add media here if exists
                      if (post.mediaUrls.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: post.mediaUrls.length,
                            itemBuilder: (context, index) {
                              final url = post.mediaUrls[index];
                              final isVideo = post.isVideo(url);
                              return GestureDetector(
                                onTap: () => _showMagnifiedImage(context, url),
                                child: Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 12, bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFF1E1E1E),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: isVideo
                                      ? CustomVideoPlayer(
                                          videoUrl: url,
                                          autoPlay: false,
                                          showControls: false,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Icon(Icons.broken_image, color: Colors.grey),
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      GestureDetector(
                        onTap: _toggleLike,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked ? Colors.orange : const Color(0xFF888888),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_likesCount Likes',
                              style: TextStyle(
                                color: _isLiked ? Colors.orange : const Color(0xFF888888),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'REPLIES (${_comments.length})',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Comment list
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'No comments yet. Be the first!',
                        style: TextStyle(color: Color(0xFF666666)),
                      ),
                    ),
                  )
                else
                  ..._comments.map((comment) {
                    final commentDiff = DateTime.now().difference(comment.createdAt);
                    final commentTime = commentDiff.inDays > 0
                        ? '${commentDiff.inDays}d ago'
                        : commentDiff.inHours > 0
                            ? '${commentDiff.inHours}h ago'
                            : '${commentDiff.inMinutes}m ago';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCommentItem(
                        author: comment.authorName,
                        time: commentTime,
                        text: comment.content,
                        avatarUrl: comment.authorAvatarUrl,
                        userId: comment.userId,
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Comment Input Bar
          Container(
            color: Colors.black,
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 20,
              top: 10,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                border: Border.all(color: const Color(0xFF2A2A2A)),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(color: Color(0xFF555555)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _submitComment,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _isSubmitting ? Colors.grey : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: _isSubmitting
                          ? const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.black,
                              size: 16,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem({
    required String author,
    required String time,
    required String text,
    String? avatarUrl,
    required String userId,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _navigateToUserProfile(userId),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFF1E1E1E),
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? const Icon(Icons.person, color: Color(0xFFAAAAAA), size: 16)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              border: Border.all(color: const Color(0xFF222222)),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      author,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
