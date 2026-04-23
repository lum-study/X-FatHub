import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';
import '../../booking/viewmodels/booking_viewmodel.dart';
import '../../community/providers/community_provider.dart';
import '../../community/models/post_model.dart';
import '../../booking/models/booking_model.dart';
import '../../booking/views/booking_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    
    // Refresh Booking data
    final bookingVM = context.read<BookingViewModel>();
    final profileVM = context.read<ProfileViewModel>();
    
    await Future.wait([
      bookingVM.refreshCurrentUserBookingData(),
      profileVM.init(),
    ]);

    if (mounted) {
      setState(() {
        _isFirstLoad = false;
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
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 15, left: 15),
          child: SvgPicture.asset(
            'lib/assets/img/logo_wordmark_dark.svg',
            height: 67,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFFFA500),
        backgroundColor: const Color(0xFF1A1A1A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 30),
              _buildQuickStats(),
              const SizedBox(height: 30),
              _buildUpcomingSessions(),
              const SizedBox(height: 30),
              _buildCommunityHighlights(),
              const SizedBox(height: 50), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<ProfileViewModel>(
      builder: (context, profileVM, _) {
        final name = profileVM.profile?.name ?? 'Athlete';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Consumer2<BookingViewModel, ProfileViewModel>(
      builder: (context, bookingVM, profileVM, _) {
        final currentWeight = profileVM.profile?.currentWeight?.toStringAsFixed(1) ?? '0.0';
        final weightGoal = profileVM.profile?.weightGoal?.toStringAsFixed(1) ?? '0.0';
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFFFFA500).withValues(alpha: 0.15), Colors.black],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFA500).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Weight', currentWeight, 'kg'),
              _divider(),
              _statItem('Sessions', '${bookingVM.sessionsRemaining}', 'left'),
              _divider(),
              _statItem('Goal', weightGoal, 'kg'),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(color: Color(0xFFFFA500), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[800],
    );
  }

  Widget _buildUpcomingSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Session',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Consumer<BookingViewModel>(
          builder: (context, bookingVM, _) {
            if (bookingVM.isLoading && _isFirstLoad) {
              return const Center(child: CircularProgressIndicator());
            }

            final now = DateTime.now();
            final upcoming = bookingVM.userBookings
                .where((b) => b.status == BookingStatus.upcoming && b.bookingDate.isAfter(now))
                .toList();
            
            upcoming.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

            if (upcoming.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[900]!),
                ),
                child: const Text(
                  'No upcoming sessions. Book one now!',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final nearest = upcoming.first;
            final dateStr = DateFormat('EEE, d MMM').format(nearest.bookingDate);
            final timeStr = DateFormat('h:mm a').format(nearest.bookingDate);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingDetailScreen(
                      booking: nearest,
                      packageNameFallback: bookingVM.packageNameForBooking(nearest.id),
                      slotLocation: nearest.slotLocation,
                      slotCoach: nearest.slotCoach,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFFFA500).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA500).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_today, color: Color(0xFFFFA500)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nearest.slotLocation ?? 'Main Gym',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dateStr • $timeStr',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommunityHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Community Highlights',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        FutureBuilder<List<PostModel>>(
          future: context.read<CommunityProvider>().fetchPosts('All'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _isFirstLoad) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No highlights yet', style: TextStyle(color: Colors.grey));
            }

            // Filter for current week and sort by likes
            final now = DateTime.now();
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final weekPosts = snapshot.data!.where((p) => p.createdAt.isAfter(startOfWeek)).toList();
            
            weekPosts.sort((a, b) => b.likesCount.compareTo(a.likesCount));
            final topPosts = weekPosts.take(3).toList();

            if (topPosts.isEmpty) {
               // Fallback to top 3 all time if this week is empty
               final allTime = snapshot.data!;
               allTime.sort((a, b) => b.likesCount.compareTo(a.likesCount));
               topPosts.addAll(allTime.take(3));
            }

            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topPosts.length,
                itemBuilder: (context, index) {
                  final post = topPosts[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(15),
                      image: post.mediaUrls.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(post.mediaUrls.first),
                              fit: BoxFit.cover,
                              opacity: 0.4,
                            )
                          : null,
                      border: Border.all(color: Colors.grey[900]!),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFFFFA500),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    post.authorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                post.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.favorite, color: Colors.red, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.likesCount} likes',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
