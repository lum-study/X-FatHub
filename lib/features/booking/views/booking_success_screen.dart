import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xfathub/features/booking/models/booking_model.dart';
import 'package:xfathub/features/booking/models/package_model.dart';

class BookingSuccessScreen extends StatelessWidget {
  final BookingModel booking;
  final PackageModel package;

  const BookingSuccessScreen({
    super.key,
    required this.booking,
    required this.package,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(booking.bookingDate.toLocal());
    final timeLabel = DateFormat('hh:mm a').format(booking.bookingDate.toLocal());

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFFA500),
                size: 72,
              ),
              const SizedBox(height: 14),
              const Text(
                'Booking Confirmed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your session is successfully reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  children: [
                    _buildRow('Package', package.name),
                    _buildRow('Date', dateLabel),
                    _buildRow('Time', timeLabel),
                    _buildRow('Booking ID', booking.id),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
