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
  CommunitySortMode _sortMode = CommunitySortMode.time;
  CommunitySortOrder _sortOrder = CommunitySortOrder.descending;
  bool _isSortDrawerOpen = false;
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

  List<PostModel> get _sortedUserPosts {
    final posts = List<PostModel>.from(_userPosts);
    posts.sort((a, b) {
      final compareDirection = _sortOrder == CommunitySortOrder.descending ? -1 : 1;

      if (_sortMode == CommunitySortMode.likes) {
        final likesComparison = a.likesCount.compareTo(b.likesCount) * compareDirection;
        if (likesComparison != 0) return likesComparison;
        return a.createdAt.compareTo(b.createdAt) * compareDirection;
      }

      final timeA = a.updatedAt ?? a.createdAt;
      final timeB = b.updatedAt ?? b.createdAt;
      final timeComparison = timeA.compareTo(timeB) * compareDirection;
      if (timeComparison != 0) return timeComparison;
      return a.likesCount.compareTo(b.likesCount) * compareDirection;
    });
    return posts;
  }

  Future<void> _refreshForSort() async {
    await _loadProfileData(showLoading: false, preservePosition: false);

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  Future<void> _setSortMode(CommunitySortMode sortMode) async {
    if (_sortMode != sortMode) {
      setState(() {
        _sortMode = sortMode;
      });
    }

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    setState(() => _isSortDrawerOpen = false);
    await _refreshForSort();
  }

  Future<void> _setSortOrder(CommunitySortOrder sortOrder) async {
    if (_sortOrder != sortOrder) {
      setState(() {
        _sortOrder = sortOrder;
      });
    }

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    setState(() => _isSortDrawerOpen = false);
    await _refreshForSort();
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
    final sortedUserPosts = _sortedUserPosts;

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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'Sort',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSortDrawerOpen = !_isSortDrawerOpen;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: const Color(0xFF0D0D0D),
                      side: const BorderSide(color: Color(0xFF333333)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    icon: Icon(
                      _isSortDrawerOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                    ),
                    label: const Text(
                      'Options',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Sort by',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildSortChip('Time', CommunitySortMode.time),
                      const SizedBox(width: 8),
                      _buildSortChip('Likes', CommunitySortMode.likes),
                      const SizedBox(width: 14),
                      const Text(
                        'Order',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildOrderChip('Desc', CommunitySortOrder.descending),
                      const SizedBox(width: 8),
                      _buildOrderChip('Asc', CommunitySortOrder.ascending),
                    ],
                  ),
                ),
              ),
              crossFadeState: _isSortDrawerOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
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
                itemCount: sortedUserPosts.length,
                itemBuilder: (context, index) {
                  final post = sortedUserPosts[index];
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

  Widget _buildSortChip(String label, CommunitySortMode sortMode) {
    final isSelected = _sortMode == sortMode;
    return GestureDetector(
      onTap: () => _setSortMode(sortMode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? Colors.orange : const Color(0xFF333333),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFFAAAAAA),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderChip(String label, CommunitySortOrder sortOrder) {
    final isSelected = _sortOrder == sortOrder;
    return GestureDetector(
      onTap: () => _setSortOrder(sortOrder),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? Colors.orange : const Color(0xFF333333),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFFAAAAAA),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
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
