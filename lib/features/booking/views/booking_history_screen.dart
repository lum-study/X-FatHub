import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfathub/features/booking/models/booking_model.dart';
import 'package:xfathub/features/booking/models/package_model.dart';
import 'package:xfathub/features/booking/viewmodels/booking_viewmodel.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFA500)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Bookings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFA500),
          labelColor: const Color(0xFFFFA500),
          unselectedLabelColor: const Color(0xFF666666),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Missed'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<BookingViewModel>(
        builder: (context, provider, _) {
          final upcoming = provider.userBookings
              .where((b) => b.status == BookingStatus.upcoming && b.bookingDate.isAfter(DateTime.now()))
              .toList()
            ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
          
          final now = DateTime.now();
          final missed = provider.userBookings
              .where((b) => b.status == BookingStatus.upcoming && b.bookingDate.isBefore(now))
              .toList()
            ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
          
          final completed = provider.userBookings
              .where((b) => b.status == BookingStatus.completed || b.status == BookingStatus.cancelled)
              .toList()
            ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(upcoming, 'upcoming', provider),
              _buildBookingList(missed, 'missed', provider),
              _buildBookingList(completed, 'completed', provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings, String type, BookingViewModel provider) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'upcoming' ? Icons.event_available : Icons.history,
              color: const Color(0xFF333333),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              type == 'upcoming' 
                  ? 'No upcoming bookings' 
                  : type == 'missed'
                      ? 'No missed bookings'
                      : 'No completed bookings',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshCurrentUserBookingData(),
      color: const Color(0xFFFFA500),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _BookingCard(
            booking: booking,
            package: provider.packages.where((p) => p.id == booking.packageId).firstOrNull,
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final PackageModel? package;

  const _BookingCard({required this.booking, this.package});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bookingTime = booking.bookingDate.toLocal();
    final isUpcoming = booking.status == BookingStatus.upcoming && bookingTime.isAfter(now);
    
    String timeRemaining = '';
    if (isUpcoming) {
      final diff = bookingTime.difference(now);
      if (diff.inDays > 0) {
        timeRemaining = 'in ${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
      } else if (diff.inHours > 0) {
        timeRemaining = 'in ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''}';
      } else if (diff.inMinutes > 0) {
        timeRemaining = 'in ${diff.inMinutes} min';
      } else {
        timeRemaining = 'Starting now';
      }
    }

    final isMissed = booking.status == BookingStatus.upcoming && bookingTime.isBefore(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMissed 
              ? Colors.red.withValues(alpha: 0.3)
              : isUpcoming 
                  ? const Color(0xFFFFA500).withValues(alpha: 0.3)
                  : const Color(0xFF2A2A2A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMissed 
                      ? Colors.red.withValues(alpha: 0.2)
                      : isUpcoming 
                          ? const Color(0xFFFFA500).withValues(alpha: 0.2)
                          : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isMissed ? 'Missed' : booking.status.name.toUpperCase(),
                  style: TextStyle(
                    color: isMissed 
                        ? Colors.red
                        : isUpcoming 
                            ? const Color(0xFFFFA500)
                            : const Color(0xFF888888),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (timeRemaining.isNotEmpty)
                Text(
                  timeRemaining,
                  style: const TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            package?.name ?? 'Package',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF888888), size: 14),
              const SizedBox(width: 6),
              Text(
                DateFormat('EEE, d MMM yyyy').format(bookingTime),
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF888888), size: 14),
              const SizedBox(width: 6),
              Text(
                DateFormat('hh:mm a').format(bookingTime),
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
              ),
            ],
          ),
          if (booking.id.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.tag, color: Color(0xFF888888), size: 14),
                const SizedBox(width: 6),
                Text(
                  'ID: ${booking.id.substring(0, 8)}',
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}