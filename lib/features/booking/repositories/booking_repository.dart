import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../models/package_model.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';

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

      return (response as List).map((data) => SlotModel.fromMap(data)).toList();
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

      final bookingPayload = data['booking'];
      if (bookingPayload is Map) {
        return BookingModel.fromMap(Map<String, dynamic>.from(bookingPayload));
      }

      if (bookingPayload is String && bookingPayload.isNotEmpty) {
        try {
          final decoded = jsonDecode(bookingPayload);
          if (decoded is Map) {
            return BookingModel.fromMap(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          // Ignore and try the database fallback lookup below.
        }
      }

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
        return BookingModel.fromMap(Map<String, dynamic>.from(fallback));
      }

      throw Exception('Booking was created but response payload was missing.');
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

      return (response as List)
          .map((data) => BookingModel.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user bookings: $e');
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
}
