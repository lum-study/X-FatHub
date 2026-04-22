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
  late final CommunityProvider _communityProvider;
  bool _isLoading = true;
  Map<String, dynamic>? _userStats;
  List<PostModel> _userPosts = [];
  bool _isFollowing = false;
  bool _isCurrentUser = false;
  final ScrollController _scrollController = ScrollController();
  int _lastScrollToTopToken = 0;

  @override
  void initState() {
    super.initState();
    _communityProvider = context.read<CommunityProvider>();
    _lastScrollToTopToken = _communityProvider.scrollToTopToken;
    _communityProvider.addListener(_handleCommunityProviderUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  @override
  void dispose() {
    _communityProvider.removeListener(_handleCommunityProviderUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleCommunityProviderUpdate() {
    if (_lastScrollToTopToken == _communityProvider.scrollToTopToken) {
      return;
    }
    _lastScrollToTopToken = _communityProvider.scrollToTopToken;

    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.offset <= 0) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadProfileData({
    bool showLoading = true,
    bool preservePosition = false,
  }) async {
    final previousOffset =
        preservePosition && _scrollController.hasClients ? _scrollController.offset : 0.0;

    if (showLoading) {
      setState(() => _isLoading = true);
    }
    
    final provider = context.read<CommunityProvider>();
    _isCurrentUser = provider.currentUserId == widget.userId;

    // Fetch stats and posts in parallel
    final results = await Future.wait([
      provider.fetchUserProfileStats(widget.userId),
      provider.fetchUserPosts(widget.userId),
      if (!_isCurrentUser) provider.isFollowing(widget.userId) else Future.value(false),
    ]);

    if (!mounted) return;

    setState(() {
      _userStats = results[0] as Map<String, dynamic>?;
      _userPosts = results[1] as List<PostModel>;
      _isFollowing = results.length > 2 ? results[2] as bool : false;
      _isLoading = false;
    });

    if (preservePosition) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetOffset = previousOffset > maxScroll ? maxScroll : previousOffset;
        _scrollController.jumpTo(targetOffset);
      });
    }
  }

  Future<void> _toggleFollow() async {
    final provider = context.read<CommunityProvider>();
    final newStatus = !_isFollowing;
    setState(() => _isFollowing = newStatus);
    await provider.toggleFollow(widget.userId, !newStatus);
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
    final totalFollowers = _userStats!['totalFollowers'] ?? 0;
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
      body: RefreshIndicator(
        color: Colors.orange,
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: _loadProfileData,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildProfileHeader(name, formattedDate, totalLikes, totalPosts, totalFollowers),
            const Divider(color: Color(0xFF333333), height: 1),
            if (_userPosts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100.0),
                child: Center(
                  child: Text(
                    'No posts yet',
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                ),
              )
            else
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _userPosts.length,
                itemBuilder: (context, index) {
                  final post = _userPosts[index];
                  final diff = DateTime.now().difference(post.createdAt);
                  String timeStr = diff.inDays > 0
                      ? '${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago'
                      : diff.inHours > 0
                          ? '${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago'
                          : '${diff.inMinutes} ${diff.inMinutes == 1 ? "min" : "mins"} ago';

                  if (post.updatedAt != null && post.updatedAt!.difference(post.createdAt).inSeconds > 5) {
                    final updatedDiff = DateTime.now().difference(post.updatedAt!);
                    final updatedTimeStr = updatedDiff.inDays > 0
                        ? '${updatedDiff.inDays} ${updatedDiff.inDays == 1 ? "day" : "days"} ago'
                        : updatedDiff.inHours > 0
                            ? '${updatedDiff.inHours} ${updatedDiff.inHours == 1 ? "hour" : "hours"} ago'
                            : '${updatedDiff.inMinutes} ${updatedDiff.inMinutes == 1 ? "min" : "mins"} ago';
                    timeStr += ' (updated $updatedTimeStr)';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PostCard(
                      post: post,
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
                      onCommentExit: () =>
                          _loadProfileData(showLoading: false, preservePosition: true),
                      onDelete: () async {
                        await context.read<CommunityProvider>().deletePost(post.id);
                        _loadProfileData(showLoading: false, preservePosition: true); // refresh after deletion
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      String name, String formattedDate, int totalLikes, int totalPosts, int totalFollowers) {
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
          const SizedBox(height: 12),
          if (!_isCurrentUser)
            GestureDetector(
              onTap: _toggleFollow,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: _isFollowing ? Colors.transparent : Colors.orange,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: _isFollowing ? Colors.orange : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Followers', totalFollowers.toString()),
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
