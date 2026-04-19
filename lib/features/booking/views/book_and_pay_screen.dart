import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfathub/features/booking/models/package_model.dart';
import 'package:xfathub/features/booking/viewmodels/booking_viewmodel.dart';

class BookAndPayScreen extends StatefulWidget {
  const BookAndPayScreen({super.key});

  @override
  State<BookAndPayScreen> createState() => _BookAndPayScreenState();
}

class _BookAndPayScreenState extends State<BookAndPayScreen> {
  static const double _sstRate = 0.08;

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
        final subtotal = package?.price ?? 0;
        final sst = subtotal * _sstRate;
        final total = subtotal + sst;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: provider.refreshBookSession,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    _buildOrderSummary(provider, subtotal, sst, total),
                    const SizedBox(height: 14),
                    _buildSectionTitle(Icons.credit_card, "Payment Method"),
                    const SizedBox(height: 14),
                    _buildPaymentMethods(provider),
                    const SizedBox(height: 20),
                    _buildConfirmButton(
                      provider,
                      total,
                      canProceed: provider.canProceedToPayment,
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
                  style: const TextStyle(color: Color(0xFF777777), fontSize: 11),
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
          final bool isSelected = selectedDate.year == date.year &&
              selectedDate.month == date.month &&
              selectedDate.day == date.day;

          return GestureDetector(
            onTap: () => provider.selectDate(date),
            child: Container(
              margin: const EdgeInsets.only(right: 7),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFA500) : const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFA500) : const Color(0xFF2A2A2A),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : const Color(0xFF666666),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.black : const Color(0xFFAAAAAA),
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
        final bool isTaken = slot.isFull;

        return GestureDetector(
          onTap: isTaken ? null : () => provider.selectSlot(slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFA500)
                  : (isTaken ? const Color(0xFF0A0A0A) : const Color(0xFF111111)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFA500)
                    : (isTaken ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A2A)),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    DateFormat('hh:mm a').format(slot.startTime),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : (isTaken
                              ? const Color(0xFF333333)
                              : const Color(0xFFAAAAAA)),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
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
        '${DateFormat('hh:mm a').format(slot.startTime)} - ${DateFormat('hh:mm a').format(slot.endTime)}';

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
          _buildSlotMetaRow(Icons.person, slot.coachName.isEmpty ? '-' : slot.coachName),
          const SizedBox(height: 6),
          _buildSlotMetaRow(Icons.location_on, slot.location.isEmpty ? '-' : slot.location),
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

  Widget _buildOrderSummary(
    BookingViewModel provider,
    double subtotal,
    double sst,
    double total,
  ) {
    final packageName = provider.selectedPackage?.name ?? '-';
    final dateText = DateFormat('EEE, d MMM y').format(provider.selectedDate);
    final timeText = provider.selectedSlot == null
        ? '-'
        : DateFormat('hh:mm a').format(provider.selectedSlot!.startTime);

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
          _buildPayRow("Subtotal", "RM ${subtotal.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          _buildPayRow("SST (8%)", "RM ${sst.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          _buildPayRow("Total", "RM ${total.toStringAsFixed(2)}", isOrange: true),
        ],
      ),
    );
  }

  Widget _buildPayRow(String label, String val, {bool isOrange = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
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

  Widget _buildPaymentMethods(BookingViewModel provider) {
    final methods = [
      {'type': PaymentMethodOption.card, 'name': 'Card', 'icon': Icons.credit_card},
      {'type': PaymentMethodOption.applePay, 'name': 'Apple Pay', 'icon': Icons.apple},
      {
        'type': PaymentMethodOption.eWallet,
        'name': 'e-Wallet',
        'icon': Icons.account_balance_wallet,
      },
      {'type': PaymentMethodOption.fpx, 'name': 'FPX', 'icon': Icons.account_balance},
    ];

    return Row(
      children: methods.map((m) {
        final method = m['type'] as PaymentMethodOption;
        final bool isSelected = provider.selectedPaymentMethod == method;

        return Expanded(
          child: GestureDetector(
            onTap: () => provider.selectPaymentMethod(method),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1A1000) : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFA500) : const Color(0xFF2A2A2A),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    m['icon'] as IconData,
                    color:
                        isSelected ? const Color(0xFFFFA500) : const Color(0xFF555555),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m['name'] as String,
                    style: TextStyle(
                      color:
                          isSelected ? const Color(0xFFFFA500) : const Color(0xFF777777),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmButton(
    BookingViewModel provider,
    double total, {
    required bool canProceed,
  }) {
    return GestureDetector(
      onTap: !canProceed
          ? null
          : () {
              final contextPayload = provider.buildCheckoutContext();
              if (contextPayload == null || !mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Payment integration ready. Method: ${contextPayload['paymentMethod']}.',
                  ),
                ),
              );
            },
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: canProceed ? const Color(0xFFFFA500) : const Color(0xFF5E5E5E),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: (canProceed ? const Color(0xFFFFA500) : const Color(0xFF5E5E5E))
                .withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, color: Colors.black, size: 16),
            const SizedBox(width: 8),
            Text(
              "Confirm & Pay RM ${total.toStringAsFixed(2)}",
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
