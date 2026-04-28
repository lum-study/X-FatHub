import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfathub/features/booking/models/package_model.dart';
import 'package:xfathub/features/booking/models/gym_model.dart';
import 'package:xfathub/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:xfathub/features/booking/views/checkout_screen.dart';
import 'package:xfathub/features/booking/views/booking_success_screen.dart';

class BookAndPayScreen extends StatefulWidget {
  const BookAndPayScreen({super.key});

  @override
  State<BookAndPayScreen> createState() => _BookAndPayScreenState();
}

class _BookAndPayScreenState extends State<BookAndPayScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<BookingViewModel>();
      provider.initializeBookSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingViewModel>(
      builder: (context, provider, child) {
        final package = provider.selectedPackage;
        final hasCredits = provider.sessionsRemaining > 0;
        final buttonLabel = hasCredits
            ? 'Confirm Booking'
            : 'Buy Package First';

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: provider.refreshBookSession,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBackRow(context),
                    const SizedBox(height: 14),
                    if (package == null)
                      _buildMissingPackageNotice(context)
                    else
                      _buildSelectedPackageBanner(package),
                    const SizedBox(height: 14),
                    _buildSectionTitle(Icons.calendar_month, "Select Date"),
                    const SizedBox(height: 14),
                    _buildDatePicker(provider),
                    const SizedBox(height: 14),
                    _buildSectionTitle(Icons.access_time, "Select Time"),
                    const SizedBox(height: 14),
                    _buildTimeContent(provider),
                    const SizedBox(height: 10),
                    _buildSelectedSlotDetails(provider),
                    const SizedBox(height: 14),
                    _buildSectionTitle(Icons.receipt_long, "Order Summary"),
                    const SizedBox(height: 14),
                    _buildBookingSummary(provider),
                    const SizedBox(height: 20),
                    _buildConfirmButton(
                      provider,
                      canProceed: provider.canProceedToPayment,
                      hasCredits: hasCredits,
                      label: buttonLabel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleConfirm(BookingViewModel provider) async {
    if (_isSubmitting) {
      return;
    }

    if (provider.sessionsRemaining <= 0) {
      await _showPurchasePrompt(provider);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await provider.bookSelectedSlotWithCredit();
      if (!mounted) {
        return;
      }

      if (result.success && result.booking != null) {
        final package = provider.selectedPackage;
        if (package == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking confirmed successfully.')),
          );
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingSuccessScreen(
              booking: result.booking!,
              package: package,
            ),
          ),
        );
        if (!mounted) return;
        provider.refreshPackagesPage();
        Navigator.popUntil(context, (route) => route.isFirst);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyBookingError(result.message))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _friendlyBookingError(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('already booked this slot')) {
      return 'You already have a booking for this slot.';
    }
    if (msg.contains('package is not available for the selected gym')) {
      return 'This slot is not available for your package. Please choose another slot.';
    }
    return raw;
  }

  Future<void> _showPurchasePrompt(BookingViewModel provider) async {
    final shouldBuy = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text(
          'No Credits Left',
          style: TextStyle(color: Color(0xFFFFA500)),
        ),
        content: const Text(
          'You do not have any sessions remaining. Buy a package first?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Later',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA500),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buy', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (shouldBuy != true) {
      return;
    }

    final package = provider.selectedPackage;
    if (package == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreen(package: package)),
    );
  }

  Widget _buildBackRow(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Row(
        children: [
          const Icon(Icons.chevron_left, color: Color(0xFFFFA500), size: 24),
          const SizedBox(width: 10),
          const Text(
            "Book a Session",
            style: TextStyle(
              color: Color(0xFFFFA500),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPackageBanner(PackageModel package) {
    IconData icon;
    switch (package.iconName) {
      case 'directions_run':
        icon = Icons.directions_run;
        break;
      case 'fitness_center':
      default:
        icon = Icons.fitness_center;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1000), Color(0xFF0F0F0F)],
        ),
        border: Border.all(color: const Color(0xFFFFA500)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFFFA500), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "RM ${package.price.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "${package.sessionsCount} Sessions Included",
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingPackageNotice(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No package selected',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Go back and choose a package first.',
            style: TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA500),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text(
                'Back to Packages',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFA500), size: 14),
        const SizedBox(width: 5),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BookingViewModel provider) {
    final selectedDate = provider.selectedDate;
    final dates = provider.bookingWindowDates;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: dates.map((date) {
          final bool isSelected =
              selectedDate.year == date.year &&
              selectedDate.month == date.month &&
              selectedDate.day == date.day;

          return GestureDetector(
            onTap: () => provider.selectDate(date),
            child: Container(
              margin: const EdgeInsets.only(right: 7),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFA500)
                    : const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFA500)
                      : const Color(0xFF2A2A2A),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : const Color(0xFF666666),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : const Color(0xFFAAAAAA),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeContent(BookingViewModel provider) {
    if (provider.isLoading && provider.slots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(color: Color(0xFFFFA500)),
        ),
      );
    }

    if (provider.errorMessage != null && provider.slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Text(
          provider.errorMessage!,
          style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
        ),
      );
    }

    if (provider.slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: const Text(
          'No sessions available for the selected date.',
          style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
        ),
      );
    }

    return _buildTimeGrid(provider);
  }

  Widget _buildTimeGrid(BookingViewModel provider) {
    final slots = provider.slots;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final bool isSelected = provider.selectedSlot?.id == slot.id;
        final bool isAlreadyBooked = provider.isSlotAlreadyBooked(slot.id);
        final bool isTaken = slot.isFull || isAlreadyBooked;

        return GestureDetector(
          onTap: isTaken ? null : () => provider.selectSlot(slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFA500)
                  : (isTaken
                        ? const Color(0xFF0A0A0A)
                        : const Color(0xFF111111)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFA500)
                    : (isTaken
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF2A2A2A)),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    isAlreadyBooked
                        ? 'Booked'
                        : DateFormat('hh:mm a').format(slot.startTime.toLocal()),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : (isTaken
                                ? const Color(0xFF333333)
                                : const Color(0xFFAAAAAA)),
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.black,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedSlotDetails(BookingViewModel provider) {
    final slot = provider.selectedSlot;

    if (slot == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border.all(color: const Color(0xFF2A2A2A)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Select a time slot to see session details.',
          style: TextStyle(color: Color(0xFF888888), fontSize: 11),
        ),
      );
    }

    final timeRange =
        '${DateFormat('hh:mm a').format(slot.startTime.toLocal())} - ${DateFormat('hh:mm a').format(slot.endTime.toLocal())}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot.className,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildSlotMetaRow(Icons.schedule, timeRange),
          const SizedBox(height: 6),
          _buildSlotMetaRow(
            Icons.person,
            slot.coachName.isEmpty ? '-' : slot.coachName,
          ),
          const SizedBox(height: 6),
          _buildSlotMetaRow(
            Icons.business,
            provider.selectedPackageGyms
                .where((g) => g.id == slot.gymId)
                .firstOrNull
                ?.name ?? '-',
          ),
          const SizedBox(height: 6),
          _buildSlotMetaRow(
            Icons.location_on,
            slot.location.isEmpty ? '-' : slot.location,
          ),
          const SizedBox(height: 6),
          _buildSlotMetaRow(
            Icons.event_seat,
            slot.isFull ? 'Full' : '${slot.spotsLeft} spots left',
          ),
        ],
      ),
    );
  }

  Widget _buildSlotMetaRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFA500), size: 12),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSummary(BookingViewModel provider) {
    final packageName = provider.selectedPackage?.name ?? '-';
    final dateText = DateFormat('EEE, d MMM y').format(provider.selectedDate);
    final timeText = provider.selectedSlot == null
        ? '-'
        : DateFormat('hh:mm a').format(provider.selectedSlot!.startTime.toLocal());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _buildPayRow("Package", packageName),
          const SizedBox(height: 8),
          _buildPayRow("Date", dateText),
          const SizedBox(height: 8),
          _buildPayRow("Time", timeText),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFF2A2A2A), height: 1, thickness: 1),
          ),
          _buildPayRow(
            "Sessions Remaining",
            provider.sessionsRemaining.toString(),
          ),
          const SizedBox(height: 8),
          _buildPayRow(
            "Status",
            provider.sessionsRemaining > 0
                ? 'Ready to book'
                : 'Buy a package first',
            isOrange: provider.sessionsRemaining > 0,
          ),
          const SizedBox(height: 8),
          _buildPayRow(
            "Charge",
            provider.sessionsRemaining > 0
                ? 'RM 0.00'
                : 'Package purchase required',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPayRow(String label, String val, {bool isOrange = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
        ),
        Text(
          val,
          style: TextStyle(
            color: isOrange ? const Color(0xFFFFA500) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(
    BookingViewModel provider, {
    required bool canProceed,
    required bool hasCredits,
    required String label,
  }) {
    final isBusy = provider.isLoading || _isSubmitting;

    return GestureDetector(
      onTap: (!canProceed || isBusy)
          ? null
          : () async {
              if (hasCredits) {
                await _handleConfirm(provider);
              } else {
                await _showPurchasePrompt(provider);
              }
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: (canProceed && !isBusy)
              ? const Color(0xFFFFA500)
              : const Color(0xFF5E5E5E),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color:
                  ((canProceed && !isBusy)
                          ? const Color(0xFFFFA500)
                          : const Color(0xFF5E5E5E))
                      .withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBusy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            else
              const Icon(Icons.lock, color: Colors.black, size: 16),
            const SizedBox(width: 8),
            Text(
              isBusy ? 'Processing...' : label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
