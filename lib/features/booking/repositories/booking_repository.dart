import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/package_model.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
import '../models/gym_model.dart';
import '../../../core/database/local_booking_db.dart';

class BookingRepository {
  final _supabase = Supabase.instance.client;

  String get currentUserId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) {
      throw Exception('User is not authenticated.');
    }
    return id;
  }

  DateTime _localDayStart(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _localDayEndExclusive(DateTime date) {
    return _localDayStart(date).add(const Duration(days: 1));
  }

  bool _isInSelectedLocalDay(DateTime timestamp, DateTime selectedDate) {
    final localTimestamp = timestamp.toLocal();
    final start = _localDayStart(selectedDate);
    final end = _localDayEndExclusive(selectedDate);
    return !localTimestamp.isBefore(start) && localTimestamp.isBefore(end);
  }

  Stream<List<PackageModel>> streamPackages() {
    return _supabase
        .from('packages')
        .stream(primaryKey: ['id'])
        .order('price', ascending: true)
        .map((data) => data.map((d) => PackageModel.fromMap(d)).toList());
  }

  Future<List<PackageModel>> fetchPackages() async {
    try {
      final response = await _supabase
          .from('packages')
          .select()
          .order('price', ascending: true);

      return (response as List)
          .map((data) => PackageModel.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch packages: $e');
    }
  }

  Future<List<GymModel>> fetchPackageGyms(String packageId) async {
    try {
      final response = await _supabase
          .from('package_gyms')
          .select('gym_id, is_active, gyms(id, name, venue, address, status)')
          .eq('package_id', packageId)
          .eq('is_active', true);

      final rows = (response as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      final gyms = <GymModel>[];
      final fallbackGymIds = <String>[];

      for (final row in rows) {
        final gymRaw = row['gyms'];
        if (gymRaw is Map) {
          gyms.add(GymModel.fromMap(Map<String, dynamic>.from(gymRaw)));
        } else if (gymRaw is List) {
          for (final item in gymRaw) {
            if (item is Map) {
              gyms.add(GymModel.fromMap(Map<String, dynamic>.from(item)));
            }
          }
        } else {
          final gymId = row['gym_id']?.toString();
          if (gymId != null && gymId.isNotEmpty) {
            fallbackGymIds.add(gymId);
          }
        }
      }

      if (gyms.isEmpty && fallbackGymIds.isNotEmpty) {
        final fallbackResponse = await _supabase
            .from('gyms')
            .select('id, name, venue, address, status')
            .inFilter('id', fallbackGymIds);

        gyms.addAll(
          (fallbackResponse as List).map(
            (row) => GymModel.fromMap(Map<String, dynamic>.from(row)),
          ),
        );
      }

      final uniqueGyms = <String, GymModel>{
        for (final gym in gyms) gym.id: gym,
      }.values.toList();

      uniqueGyms.sort((a, b) => a.name.compareTo(b.name));
      return uniqueGyms;
    } catch (e) {
      throw Exception('Failed to fetch package gyms: $e');
    }
  }

  Future<List<String>> fetchPackageGymIds(String packageId) async {
    try {
      final response = await _supabase
          .from('package_gyms')
          .select('gym_id')
          .eq('package_id', packageId)
          .eq('is_active', true);

      return (response as List)
          .map((row) => row['gym_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch package gym IDs: $e');
    }
  }

  Stream<List<SlotModel>> streamSlotsByDate(DateTime date) {
    return _supabase
        .from('gym_slots')
        .stream(primaryKey: ['id'])
        .order('start_time', ascending: true)
        .map((data) {
          final filtered = data
              .map((d) => SlotModel.fromMap(d))
              .where((slot) => _isInSelectedLocalDay(slot.startTime, date))
              .toList();

          filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
          return filtered;
        });
  }

  Future<List<SlotModel>> fetchSlotsByDate(DateTime date) async {
    try {
      final startUtc = _localDayStart(date).toUtc().toIso8601String();
      final endUtc = _localDayEndExclusive(date).toUtc().toIso8601String();

      final response = await _supabase
          .from('gym_slots')
          .select()
          .gte('start_time', startUtc)
          .lt('start_time', endUtc)
          .order('start_time', ascending: true);

      final slots = (response as List)
          .map((data) => SlotModel.fromMap(data))
          .toList();

      return slots;
    } catch (e) {
      throw Exception('Failed to fetch slots: $e');
    }
  }

  Future<Map<String, dynamic>> getCreditBalance(
    String userId, {
    String? packageId,
  }) async {
    try {
      final params = <String, dynamic>{'p_user_id': userId};
      if (packageId != null) {
        params['p_package_id'] = packageId;
      }

      final response = await _supabase.rpc(
        'get_user_credit_balance',
        params: params,
      );

      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw Exception('Failed to get credit balance: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserActiveSubscriptions(
    String userId,
  ) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final response = await _supabase
          .from('user_subscriptions')
          .select('package_id, sessions_remaining, expiry_date')
          .eq('user_id', userId)
          .gt('sessions_remaining', 0)
          .gte('expiry_date', today)
          .order('expiry_date', ascending: true);

      return (response as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active subscriptions: $e');
    }
  }

  Future<String> createCheckoutSession({
    required String packageId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final payload = <String, dynamic>{
        'package_id': packageId,
        'user_id': currentUserId,
      };
      if (successUrl != null) {
        payload['success_url'] = successUrl;
      }
      if (cancelUrl != null) {
        payload['cancel_url'] = cancelUrl;
      }

      final response = await _supabase.functions.invoke(
        'create-checkout-session',
        body: payload,
      );

      if (response.status != 200) {
        throw Exception(
          'Checkout function failed with status ${response.status}',
        );
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      final checkoutUrl = data['checkout_url']?.toString();
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Checkout URL is missing in response.');
      }

      return checkoutUrl;
    } catch (e) {
      throw Exception('Failed to create checkout session: $e');
    }
  }

  Future<BookingModel> createBookingWithCredit({
    required String userId,
    required String packageId,
    required String slotId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_booking_with_credit',
        params: {
          'p_user_id': userId,
          'p_slot_id': slotId,
          'p_package_id': packageId,
        },
      );

      final normalizedResponse = response is List
          ? (response.isNotEmpty ? response.first : null)
          : response;

      if (normalizedResponse is! Map) {
        throw Exception('Unexpected booking response format.');
      }

      final data = Map<String, dynamic>.from(normalizedResponse);
      final successRaw = data['success'];
      final success =
          successRaw == true || successRaw?.toString().toLowerCase() == 'true';
      if (!success) {
        final error = data['error']?.toString() ?? 'Failed to create booking.';
        throw Exception(error);
      }

      BookingModel? booking;
      final bookingPayload = data['booking'];
      if (bookingPayload is Map) {
        booking = BookingModel.fromMap(Map<String, dynamic>.from(bookingPayload));
      } else if (bookingPayload is String && bookingPayload.isNotEmpty) {
        try {
          final decoded = jsonDecode(bookingPayload);
          if (decoded is Map) {
            booking = BookingModel.fromMap(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {}
      }

      if (booking == null) {
        final fallback = await _supabase
            .from('bookings')
            .select()
            .eq('user_id', userId)
            .eq('slot_id', slotId)
            .eq('package_id', packageId)
            .order('booking_date', ascending: false)
            .limit(1)
            .maybeSingle();

        if (fallback != null) {
          booking = BookingModel.fromMap(Map<String, dynamic>.from(fallback));
        }
      }

      if (booking == null) {
        throw Exception('Booking was created but response payload was missing.');
      }

      final qrCodeData = 'QR-${const Uuid().v4()}';
      await _supabase
          .from('bookings')
          .update({'qr_code_data': qrCodeData})
          .eq('id', booking.id);

      return BookingModel(
        id: booking.id,
        userId: booking.userId,
        packageId: booking.packageId,
        slotId: booking.slotId,
        bookingDate: booking.bookingDate,
        status: booking.status,
        totalPaid: booking.totalPaid,
        receiptUrl: booking.receiptUrl,
        qrCodeData: qrCodeData,
        sessionNumber: booking.sessionNumber,
      );
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

Future<List<BookingModel>> fetchUserBookings(String userId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .order('booking_date', ascending: false);

      final bookings = <BookingModel>[];

      for (final data in response) {
        var booking = BookingModel.fromMap(data);
        var qrCodeData = booking.qrCodeData;

        if (qrCodeData == null || qrCodeData.isEmpty) {
          qrCodeData = 'QR-${const Uuid().v4()}';
          try {
            await _supabase
                .from('bookings')
                .update({'qr_code_data': qrCodeData})
                .eq('id', booking.id)
                .eq('user_id', userId);
          } catch (_) {}
        }

        String? slotName;
        String? slotLocation;
        String? slotCoach;
        DateTime? slotStartTime;

        if (booking.slotId != null && booking.slotId!.isNotEmpty) {
          try {
            final slotResponse = await _supabase
                .from('gym_slots')
                .select('class_name, location, coach_name, start_time')
                .eq('id', booking.slotId!)
                .single();
            slotName = slotResponse['class_name'];
            slotLocation = slotResponse['location'];
            slotCoach = slotResponse['coach_name'];
            slotStartTime = slotResponse['start_time'] != null
                ? DateTime.parse(slotResponse['start_time']).toLocal()
                : null;
          } catch (_) {}
        }

        final updatedBooking = BookingModel(
          id: booking.id,
          userId: booking.userId,
          packageId: booking.packageId,
          slotId: booking.slotId,
          bookingDate: slotStartTime ?? booking.bookingDate.toLocal(),
          status: booking.status,
          totalPaid: booking.totalPaid,
          receiptUrl: booking.receiptUrl,
          qrCodeData: qrCodeData,
          sessionNumber: booking.sessionNumber,
        );
        bookings.add(updatedBooking);

        try {
          await LocalBookingDatabase.cacheBookings(
            userId: userId,
            bookings: [
              {
                'id': updatedBooking.id,
                'user_id': updatedBooking.userId,
                'package_id': updatedBooking.packageId,
                'package_name': null,
                'slot_id': updatedBooking.slotId,
                'slot_name': slotName,
                'slot_location': slotLocation,
                'slot_coach': slotCoach,
                'slot_start_time': slotStartTime?.toIso8601String(),
                'booking_date': (slotStartTime ?? updatedBooking.bookingDate).toIso8601String(),
                'status': updatedBooking.status.name,
                'qr_code_data': qrCodeData,
                'session_number': updatedBooking.sessionNumber,
                'total_paid': updatedBooking.totalPaid,
              }
            ],
          );
        } catch (_) {}
      }

      return bookings;
    } catch (e) {
      try {
        final cached = await LocalBookingDatabase.getCachedBookings(userId);
        if (cached.isNotEmpty) {
          return cached.map((row) => BookingModel(
            id: row['booking_id']?.toString() ?? '',
            userId: row['user_id']?.toString() ?? '',
            packageId: row['package_id']?.toString() ?? '',
            slotId: row['slot_id']?.toString(),
            bookingDate: DateTime.tryParse(row['booking_date']?.toString() ?? '') ?? DateTime.now(),
            status: BookingStatus.values.byName(row['status']?.toString() ?? 'upcoming'),
            totalPaid: double.tryParse(row['total_paid']?.toString() ?? '0') ?? 0,
            qrCodeData: row['qr_code_data']?.toString(),
            sessionNumber: int.tryParse(row['session_number']?.toString() ?? '1') ?? 1,
          )).toList();
        }
      } catch (_) {}
      rethrow;
}
  }

  Future<void> cancelBookingWithRefund({
    required String bookingId,
    required String userId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'cancel_booking_with_refund',
        params: {'p_booking_id': bookingId, 'p_user_id': userId},
      );

      final data = Map<String, dynamic>.from(response as Map);
      if (data['success'] != true) {
        final error = data['error']?.toString() ?? 'Failed to cancel booking.';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  Future<void> rescheduleBooking({
    required String bookingId,
    required String userId,
    required String newSlotId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'reschedule_booking',
        params: {
          'p_booking_id': bookingId,
          'p_user_id': userId,
          'p_new_slot_id': newSlotId,
        },
      );

      final data = Map<String, dynamic>.from(response as Map);
      if (data['success'] != true) {
        final error =
            data['error']?.toString() ?? 'Failed to reschedule booking.';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Failed to reschedule booking: $e');
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status, String userId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': status})
          .eq('id', bookingId)
          .eq('user_id', userId);

      try {
        await LocalBookingDatabase.updateCachedBookingStatus(bookingId, status);
      } catch (_) {}
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  Future<Map<String, dynamic>?> getSlotDetails(String slotId) async {
    try {
      final response = await _supabase
          .from('gym_slots')
          .select('class_name, location, coach_name')
          .eq('id', slotId)
          .single()
          .maybeSingle();
      if (response == null) return null;
      return Map<String, dynamic>.from({
        'location': response['location'],
        'coachName': response['coach_name'],
        'className': response['class_name'],
      });
    } catch (_) {
      return null;
    }
  }
}
