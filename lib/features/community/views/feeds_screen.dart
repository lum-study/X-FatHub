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
  late final CommunityProvider _communityProvider;
  int _selectedPillIndex = 0;
  CommunitySortMode _sortMode = CommunitySortMode.time;
  CommunitySortOrder _sortOrder = CommunitySortOrder.descending;
  bool _isSortDrawerOpen = false;
  final List<String> _pills = [
    'All Posts',
    'Following',
    'Liked',
    'Favourited',
  ];
  List<PostModel> _posts = [];
  bool _isLoading = true;
  int _displayedCount = 10;
  final ScrollController _scrollController = ScrollController();
  int _lastScrollToTopToken = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _communityProvider = context.read<CommunityProvider>();
    _lastScrollToTopToken = _communityProvider.scrollToTopToken;
    _communityProvider.addListener(_handleCommunityProviderUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  List<PostModel> get _sortedPosts {
    final posts = List<PostModel>.from(_posts);
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

  @override
  void dispose() {
    _communityProvider.removeListener(_handleCommunityProviderUpdate);
    _scrollController.removeListener(_onScroll);
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

    _scrollController.jumpTo(0);
  }

  Future<void> _refreshForSort() async {
    await _loadPosts(showLoading: false, preservePosition: false);

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
        _displayedCount = 10;
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
        _displayedCount = 10;
      });
    }

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    setState(() => _isSortDrawerOpen = false);
    await _refreshForSort();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_displayedCount < _posts.length) {
        setState(() {
          _displayedCount += 10;
          if (_displayedCount > _posts.length) {
            _displayedCount = _posts.length;
          }
        });
      }
    }
  }

  Future<void> _loadPosts({
    bool showLoading = true,
    bool preservePosition = false,
  }) async {
    final previousOffset =
        preservePosition && _scrollController.hasClients ? _scrollController.offset : 0.0;
    final previousDisplayedCount = _displayedCount;

    if (showLoading) {
      setState(() => _isLoading = true);
    }

    final String selectedFilter = _pills[_selectedPillIndex];
    final provider = context.read<CommunityProvider>();
    final fetchedPosts = await provider.fetchPosts(selectedFilter);

    final nextDisplayedCount = preservePosition
        ? (previousDisplayedCount > fetchedPosts.length
            ? fetchedPosts.length
            : previousDisplayedCount)
        : (fetchedPosts.length < 10 ? fetchedPosts.length : 10);

    if (!mounted) return;
    setState(() {
      _posts = fetchedPosts;
      _displayedCount = nextDisplayedCount;
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
            onPressed: () async {
              final provider = context.read<CommunityProvider>();
              if (provider.currentUserId != null) {
                await Navigator.push(
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
                _loadPosts(showLoading: false, preservePosition: true);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                    _loadPosts(); // Fetch posts for selected filter
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
              : Expanded(
                  child: RefreshIndicator(
                    color: Colors.orange,
                    backgroundColor: const Color(0xFF1E1E1E),
                    onRefresh: _loadPosts,
                    child: configExpandedList(),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () async {
          // Navigate to NewPostScreen
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const NewPostScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
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

  Widget configExpandedList() {
    final visiblePosts = _sortedPosts;

    if (_posts.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              'No posts found',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),       
      itemCount: (_displayedCount < visiblePosts.length ? _displayedCount : visiblePosts.length) + 1,
      itemBuilder: (context, index) {
          final displayCount = _displayedCount < visiblePosts.length ? _displayedCount : visiblePosts.length;
          if (index == displayCount) {
            return const SizedBox(height: 80); // Padding for FAB
          }
          final post = visiblePosts[index];
          // Determine time formatted string, mocked here
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

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostCard(
              post: post,
              author: post.authorName, // This would require JOINs to profile tables
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
                onCommentExit: () => _loadPosts(showLoading: false, preservePosition: true),
                onDelete: () async {
                  await context.read<CommunityProvider>().deletePost(post.id);
                  _loadPosts(showLoading: false, preservePosition: true); // refresh after deletion
                },
                onProfileTap: () async {
                await Navigator.push(
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
                _loadPosts(showLoading: false, preservePosition: true);
              },
            ),
          );
        },
      );
  }
}
