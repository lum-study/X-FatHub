import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/package_model.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final _supabase = Supabase.instance.client;

  // --- Packages ---
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

  // --- Gym Slots ---
  Stream<List<SlotModel>> streamSlotsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _supabase
        .from('gym_slots')
        .stream(primaryKey: ['id'])
        .order('start_time', ascending: true)
        .map((data) {
      return data
          .map((d) => SlotModel.fromMap(d))
          .where((slot) =>
              slot.startTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              slot.startTime.isBefore(endOfDay.add(const Duration(seconds: 1))))
          .toList();
    });
  }

  Future<List<SlotModel>> fetchSlotsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

      final response = await _supabase
          .from('gym_slots')
          .select()
          .gte('start_time', startOfDay)
          .lte('start_time', endOfDay)
          .order('start_time', ascending: true);

      return (response as List)
          .map((data) => SlotModel.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch slots: $e');
    }
  }

  // --- Bookings ---
  Future<void> createBooking(BookingModel booking) async {
    try {
      await _supabase.from('bookings').insert(booking.toMap());
      
      // If booking a specific slot, we might need to increment occupied_spots in gym_slots
      if (booking.slotId != null) {
        await _supabase.rpc('increment_slot_occupancy', params: {'slot_id': booking.slotId});
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

      return (response as List)
          .map((data) => BookingModel.fromMap(data))
          .toList();
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
