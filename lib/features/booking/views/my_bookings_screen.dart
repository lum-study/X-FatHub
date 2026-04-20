import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../viewmodels/booking_viewmodel.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool _showUpcoming = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<BookingViewModel>().refreshCurrentUserBookingData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<BookingViewModel>(
          builder: (context, provider, _) {
            final upcoming = provider.userBookings
                .where((b) => b.status == BookingStatus.upcoming)
                .toList();
            final history = provider.userBookings
                .where((b) => b.status != BookingStatus.upcoming)
                .toList();
            final visible = _showUpcoming ? upcoming : history;

            return RefreshIndicator(
              onRefresh: provider.refreshCurrentUserBookingData,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildCreditStrip(provider),
                  const SizedBox(height: 14),
                  _buildTabs(),
                  const SizedBox(height: 14),
                  if (provider.isLoading && visible.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFA500),
                        ),
                      ),
                    )
                  else if (visible.isEmpty)
                    const _EmptyList()
                  else
                    ...visible.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BookingCard(
                          booking: booking,
                          onCancel: booking.status == BookingStatus.upcoming
                              ? () => _cancelBooking(provider, booking.id)
                              : null,
                          onReschedule: booking.status == BookingStatus.upcoming
                              ? () => _rescheduleBooking(provider, booking)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.chevron_left,
            color: Color(0xFFFFA500),
            size: 30,
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'My Bookings',
              style: TextStyle(
                color: Color(0xFFFFA500),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 30),
      ],
    );
  }

  Widget _buildCreditStrip(BookingViewModel provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1000), Color(0xFF0F0F0F)],
        ),
        border: Border.all(color: const Color(0xFFFFA500)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Credit Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                provider.nextExpiryDate == null
                    ? 'No active package'
                    : 'Valid until ${DateFormat('d MMM y').format(provider.nextExpiryDate!)}',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 10),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                provider.sessionsRemaining.toString(),
                style: const TextStyle(
                  color: Color(0xFFFFA500),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Sessions Left',
                style: TextStyle(
                  color: Color(0xFFFFA500),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showUpcoming = true),
              child: _tab('Upcoming', _showUpcoming),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showUpcoming = false),
              child: _tab('History', !_showUpcoming),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFA500) : Colors.transparent,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: active ? Colors.black : const Color(0xFF666666),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _cancelBooking(
    BookingViewModel provider,
    String bookingId,
  ) async {
    final ok = await provider.cancelBookingWithRefund(bookingId);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Booking cancelled and credit refunded.'
              : provider.errorMessage ?? 'Unable to cancel booking.',
        ),
      ),
    );
  }

  Future<void> _rescheduleBooking(
    BookingViewModel provider,
    BookingModel booking,
  ) async {
    await provider.fetchSlotsForDate(booking.bookingDate);
    if (!mounted) {
      return;
    }

    final newSlotId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: provider.slots
                .where((slot) => !slot.isFull && slot.id != booking.slotId)
                .map(
                  (slot) => ListTile(
                    title: Text(
                      slot.className,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      DateFormat('EEE, d MMM  hh:mm a').format(slot.startTime),
                      style: const TextStyle(color: Color(0xFFAAAAAA)),
                    ),
                    onTap: () => Navigator.pop(context, slot.id),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (newSlotId == null) {
      return;
    }

    final ok = await provider.rescheduleBooking(
      bookingId: booking.id,
      newSlotId: newSlotId,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Booking rescheduled.'
              : provider.errorMessage ?? 'Unable to reschedule booking.',
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;

  const _BookingCard({required this.booking, this.onCancel, this.onReschedule});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = booking.status == BookingStatus.upcoming;
    final statusColor = isUpcoming
        ? const Color(0xFFFFA500)
        : booking.status == BookingStatus.cancelled
        ? const Color(0xFFE74C3C)
        : const Color(0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Booking #${booking.id.substring(0, 8)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                booking.status.name.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEE, d MMM y  hh:mm a').format(booking.bookingDate),
            style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
          ),
          if ((booking.qrCodeData ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              booking.qrCodeData!,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 10),
            ),
          ],
          if (isUpcoming) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReschedule,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFA500)),
                    ),
                    child: const Text(
                      'Reschedule',
                      style: TextStyle(color: Color(0xFFFFA500)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF666666)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFFAAAAAA)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: const Text(
        'No bookings found for this section.',
        style: TextStyle(color: Color(0xFFAAAAAA)),
      ),
    );
  }
}
