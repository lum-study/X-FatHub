import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'package:intl/intl.dart';

class CommunityProfileScreen extends StatefulWidget {
  final String userId;

  const CommunityProfileScreen({super.key, required this.userId});

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userStats;
  List<PostModel> _userPosts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    final provider = context.read<CommunityProvider>();

    // Fetch stats and posts in parallel
    final results = await Future.wait([
      provider.fetchUserProfileStats(widget.userId),
      provider.fetchUserPosts(widget.userId),
    ]);

    setState(() {
      _userStats = results[0] as Map<String, dynamic>?;
      _userPosts = results[1] as List<PostModel>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (_userStats == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.orange),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.orange, size: 60),
              const SizedBox(height: 16),
              const Text(
                'User not found',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${widget.userId}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'If this is a new account, the database trigger might have failed to create your profile.\n\nTry running the RLS fix in Supabase SQL Editor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                ),
              ),
            ],
          ), 
        ),
      );
    }

    final name = _userStats!['name'] as String;
    final joinedDate = _userStats!['joinedDate'] as DateTime;
    final totalLikes = _userStats!['totalLikes'] as int;
    final totalPosts = _userStats!['totalPosts'] as int;
    final formattedDate = DateFormat.yMMMMd().format(joinedDate);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.orange),
        title: Text(
          name,
          style: const TextStyle(color: Colors.orange, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildProfileHeader(name, formattedDate, totalLikes, totalPosts),
          const Divider(color: Color(0xFF333333), height: 1),
          Expanded(
            child: _userPosts.isEmpty
                ? const Center(
                    child: Text(
                      'No posts yet',
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: _userPosts.length,
                    itemBuilder: (context, index) {
                      final post = _userPosts[index];
                      final diff = DateTime.now().difference(post.createdAt);
                      final timeStr = diff.inHours > 0
                          ? '${diff.inHours} hours ago'
                          : '${diff.inMinutes} mins ago';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PostCard(
                          author: post.authorName,
                          time: timeStr,
                          avatarIcon: Icons.person,
                          content: post.content,
                          hasMedia: post.mediaUrl != null && post.mediaUrl!.isNotEmpty,
                          likes: post.likesCount,
                          comments: post.commentsCount,
                          isLiked: post.isLikedByMe,
                          isStarred: post.isFavouritedByMe,
                          onLikeToggle: () {
                            context.read<CommunityProvider>().toggleLike(post.id, !post.isLikedByMe);
                          },
                          onStarToggle: () {
                            context.read<CommunityProvider>().toggleFavourite(post.id, !post.isFavouritedByMe);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      String name, String formattedDate, int totalLikes, int totalPosts) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF1E1E1E),
            child: Icon(Icons.person, color: Colors.orange, size: 50),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Joined $formattedDate',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
               _buildStatItem('Likes', totalLikes.toString()),
              _buildStatItem('Posts', totalPosts.toString()),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
             color: Colors.orange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
        ),
      ],
    );
  }
}
