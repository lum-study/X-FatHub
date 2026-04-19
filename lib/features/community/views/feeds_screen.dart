import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'community_profile_screen.dart';
import 'new_post_screen.dart';

class FeedsScreen extends StatefulWidget {
  const FeedsScreen({super.key});

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  int _selectedPillIndex = 0;
  final List<String> _pills = [
    'All Posts',
    'Following',
    'Liked',
    'Favourited',
  ];
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final String category = _pills[_selectedPillIndex];
    final provider = context.read<CommunityProvider>();
    final fetchedPosts = await provider.fetchPosts(category);
    setState(() {
      _posts = fetchedPosts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.group, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Community',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.orange),
            onPressed: () {
              final provider = context.read<CommunityProvider>();
              if (provider.currentUserId != null) {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        CommunityProfileScreen(userId: provider.currentUserId!),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 200),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.orange),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Pills
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _pills.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedPillIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPillIndex = index;
                    });
                    _loadPosts(); // Fetch new category
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange
                          : const Color(0xFF0D0D0D),
                      border: Border.all(
                        color: isSelected
                            ? Colors.orange
                            : const Color(0xFF333333),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _pills[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : const Color(0xFFAAAAAA),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          _isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  ),
                )
              : configExpandedList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () async {
          // Navigate to NewPostScreen
          await Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const NewPostScreen())
          );
          // Reload posts so the timeline is refreshed instantly!
          if (mounted) {
            _loadPosts();
          }
        },
        child: const Icon(Icons.edit, color: Colors.black),
      ),
    );
  }

  Expanded configExpandedList() {
    if (_posts.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No posts found',
            style: TextStyle(color: Color(0xFF666666)),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _posts.length + 1, // +1 for the bottom padding
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const SizedBox(height: 80); // Padding for FAB
          }
          final post = _posts[index];
          // Determine time formatted string, mocked here
          final diff = DateTime.now().difference(post.createdAt);
          final timeStr = diff.inHours > 0
              ? '${diff.inHours} hours ago'
              : '${diff.inMinutes} mins ago';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostCard(
               author: post.authorName, // This would require JOINs to profile tables
              time: timeStr,
              avatarIcon: Icons.person,
              content: post.content,
              hasMedia: post.mediaUrl != null && post.mediaUrl!.isNotEmpty,
              likes: post.likesCount,
              comments: post.commentsCount,
              isLiked: post.isLikedByMe,
              isStarred: post.isFavouritedByMe,                onLikeToggle: () {
                  context.read<CommunityProvider>().toggleLike(post.id, !post.isLikedByMe);
                },
                onStarToggle: () {
                  context.read<CommunityProvider>().toggleFavourite(post.id, !post.isFavouritedByMe);
                },              onProfileTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        CommunityProfileScreen(userId: post.userId),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 200),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
