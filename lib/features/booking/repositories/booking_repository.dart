import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/package_model.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final _supabase = Supabase.instance.client;

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
      final response =
          await _supabase.from('packages').select().order('price', ascending: true);

      return (response as List).map((data) => PackageModel.fromMap(data)).toList();
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

  Future<void> createBooking(BookingModel booking) async {
    try {
      await _supabase.from('bookings').insert(booking.toMap());

      if (booking.slotId != null) {
        await _supabase
            .rpc('increment_slot_occupancy', params: {'slot_id': booking.slotId});
      }
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

      return (response as List).map((data) => BookingModel.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user bookings: $e');
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }
}
