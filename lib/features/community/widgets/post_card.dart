import 'package:flutter/material.dart';
import '../views/comments_screen.dart';

class PostCard extends StatefulWidget {
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

  const PostCard({
    super.key,
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

  void _navigateToComments() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CommentsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToComments,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
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
                const Icon(Icons.more_vert, color: Color(0xFF555555), size: 18),
              ],
            ),
            const SizedBox(height: 10),

            // Content
            Text(
              widget.content,
              style: const TextStyle(
                color: Color(0xFFEEEEEE),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Optional Media
            if (widget.hasMedia)
              Container(
                height: 140,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF222222)),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image,
                  color: Color(0xFF333333),
                  size: 40,
                ),
              ),

            // Actions
            Container(
              padding: const EdgeInsets.only(top: 10),
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
                  const SizedBox(height: 2),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
