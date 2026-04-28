enum BookingStatus { upcoming, completed, missed }

class BookingModel {
  final String id;
  final String userId;
  final String packageId;
  final String? slotId;
  final String? slotLocation;
  final String? slotCoach;
  final String? gymName;
  final String? gymAddress;
  final String? packageName;
  final DateTime bookingDate;
  final BookingStatus status;
  final double totalPaid;
  final String? receiptUrl;
  final String? qrCodeData;
  final int sessionNumber;

  BookingModel({
    required this.id,
    required this.userId,
    required this.packageId,
    this.slotId,
    this.slotLocation,
    this.slotCoach,
    this.gymName,
    this.gymAddress,
    this.packageName,
    required this.bookingDate,
    this.status = BookingStatus.upcoming,
    required this.totalPaid,
    this.receiptUrl,
    this.qrCodeData,
    this.sessionNumber = 1,
  });

  BookingModel copyWith({
    String? slotLocation,
    String? slotCoach,
    String? gymName,
    String? gymAddress,
    String? packageName,
  }) {
    return BookingModel(
      id: id,
      userId: userId,
      packageId: packageId,
      slotId: slotId,
      slotLocation: slotLocation ?? this.slotLocation,
      slotCoach: slotCoach ?? this.slotCoach,
      gymName: gymName ?? this.gymName,
      gymAddress: gymAddress ?? this.gymAddress,
      packageName: packageName ?? this.packageName,
      bookingDate: bookingDate,
      status: status,
      totalPaid: totalPaid,
      receiptUrl: receiptUrl,
      qrCodeData: qrCodeData,
      sessionNumber: sessionNumber,
    );
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      packageId: map['package_id']?.toString() ?? '',
      slotId: map['slot_id']?.toString(),
      slotLocation: map['slot_location']?.toString(),
      slotCoach: map['slot_coach']?.toString(),
      gymName: map['gym_name']?.toString(),
      gymAddress: map['gym_address']?.toString(),
      packageName: map['package_name']?.toString(),
      bookingDate: DateTime.tryParse(map['booking_date']?.toString() ?? '') ?? DateTime.now(),
      status: BookingStatus.values.byName(map['status']?.toString() ?? 'upcoming'),
      totalPaid: double.tryParse(map['total_paid']?.toString() ?? '0') ?? 0.0,
      receiptUrl: map['receipt_url']?.toString(),
      qrCodeData: map['qr_code_data']?.toString(),
      sessionNumber: int.tryParse(map['session_number']?.toString() ?? '1') ?? 1,
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
