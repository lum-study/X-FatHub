enum BookingStatus { upcoming, completed, cancelled, pendingRefund }

class BookingModel {
  final String id;
  final String userId;
  final String packageId;
  final String? slotId; // Can be null if it's just a package purchase
  final DateTime bookingDate;
  final BookingStatus status;
  final double totalPaid;
  final String? receiptUrl;
  final String? qrCodeData;
  final int sessionNumber; // e.g., "Session 6/12"

  BookingModel({
    required this.id,
    required this.userId,
    required this.packageId,
    this.slotId,
    required this.bookingDate,
    this.status = BookingStatus.upcoming,
    required this.totalPaid,
    this.receiptUrl,
    this.qrCodeData,
    this.sessionNumber = 1,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      packageId: map['package_id'] ?? '',
      slotId: map['slot_id'],
      bookingDate: DateTime.parse(map['booking_date']),
      status: BookingStatus.values.byName(map['status'] ?? 'upcoming'),
      totalPaid: (map['total_paid'] ?? 0).toDouble(),
      receiptUrl: map['receipt_url'],
      qrCodeData: map['qr_code_data'],
      sessionNumber: map['session_number'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'package_id': packageId,
      'slot_id': slotId,
      'booking_date': bookingDate.toIso8601String(),
      'status': status.name,
      'total_paid': totalPaid,
      'receipt_url': receiptUrl,
      'qr_code_data': qrCodeData,
      'session_number': sessionNumber,
    };
  }
}
