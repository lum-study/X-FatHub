import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:xfathub/features/booking/models/booking_model.dart';
import 'package:xfathub/features/booking/models/package_model.dart';
import 'package:xfathub/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:xfathub/features/booking/repositories/booking_repository.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;
  final PackageModel? package;
  final String? packageNameFallback;
  final String? slotLocation;
  final String? slotCoach;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    this.package,
    this.packageNameFallback,
    this.slotLocation,
    this.slotCoach,
  });

  @override
  Widget build(BuildContext context) {
    final bookingTime = booking.bookingDate;
    final now = DateTime.now();
    final isUpcoming =
        booking.status == BookingStatus.upcoming && !bookingTime.isBefore(now);
    final isMissed = 
        booking.status == BookingStatus.upcoming && bookingTime.isBefore(now);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFFFFA500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Booking Details',
                    style: TextStyle(
                      color: Color(0xFFFFA500),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFA500).withValues(alpha: 0.15),
                      const Color(0xFF0F0F0F)
                    ],
                  ),
                  border: Border.all(color: const Color(0xFFFFA500)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package?.name ?? packageNameFallback ?? 'Package',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? const Color(0xFFFFA500)
                            : isMissed
                                ? Colors.red.withValues(alpha: 0.8)
                                : const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isUpcoming 
                            ? 'UPCOMING' 
                            : isMissed 
                                ? 'MISSED' 
                                : booking.status.name.toUpperCase(),
                        style: TextStyle(
                          color: isUpcoming ? Colors.black : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.tag,
                label: 'Booking ID',
                value: booking.id.isNotEmpty ? booking.id : '-',
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: DateFormat('EEE, d MMM yyyy').format(bookingTime),
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.access_time,
                label: 'Time',
                value: DateFormat('hh:mm a').format(bookingTime),
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.location_on,
                label: 'Location',
                value: slotLocation ?? '-',
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.person,
                label: 'Coach',
                value: slotCoach ?? '-',
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.credit_card,
                label: 'Paid by',
                value: 'Credit/Debit Card',
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.confirmation_number,
                label: 'Session',
                value: 'Session ${booking.sessionNumber}',
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.payments,
                label: 'Total Paid',
                value: 'RM ${booking.totalPaid.toStringAsFixed(2)}',
                valueColor: const Color(0xFFFFA500),
              ),
              if (booking.qrCodeData != null &&
                  booking.qrCodeData!.isNotEmpty &&
                  isUpcoming) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Check-in QR Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Show this at the gym front desk',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onLongPress: () async {
                          final connectivityResult = await Connectivity().checkConnectivity();
                          final isOffline = connectivityResult.contains(ConnectivityResult.none);
                          
                          if (isOffline) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Check-in not available offline. Please connect to internet.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }
                          
                          final repository = BookingRepository();
                          try {
                            await repository.updateBookingStatus(booking.id, 'completed', booking.userId);
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Thank you for checking in! Enjoy your workout!',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFFFFA500),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                              await Provider.of<BookingViewModel>(context, listen: false)
                                  .refreshCurrentUserBookingData();
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to check in: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data: booking.qrCodeData!,
                            size: 160,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        booking.qrCodeData!,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF888888), size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}