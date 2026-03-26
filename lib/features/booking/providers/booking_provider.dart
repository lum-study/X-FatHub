import 'package:flutter/material.dart';
import '../models/package_model.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
import '../repository/booking_repository.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository _repository = BookingRepository();

  // State variables
  List<PackageModel> _packages = [];
  List<SlotModel> _slots = [];
  List<BookingModel> _userBookings = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  PackageModel? _selectedPackage;
  DateTime _selectedDate = DateTime.now();
  SlotModel? _selectedSlot;

  // Getters
  List<PackageModel> get packages => _packages;
  List<SlotModel> get slots => _slots;
  List<BookingModel> get userBookings => _userBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  PackageModel? get selectedPackage => _selectedPackage;
  DateTime get selectedDate => _selectedDate;
  SlotModel? get selectedSlot => _selectedSlot;

  // Setters/Selectors
  void selectPackage(PackageModel package) {
    _selectedPackage = package;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    fetchSlotsForDate(date);
    notifyListeners();
  }

  void selectSlot(SlotModel slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  // Business Logic
  Future<void> fetchPackages() async {
    _setLoading(true);
    try {
      _packages = await _repository.fetchPackages();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchSlotsForDate(DateTime date) async {
    _setLoading(true);
    try {
      _slots = await _repository.fetchSlotsByDate(date);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchUserBookings(String userId) async {
    _setLoading(true);
    try {
      _userBookings = await _repository.fetchUserBookings(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> confirmBooking({required String userId, required double amount}) async {
    if (_selectedPackage == null) return false;

    _setLoading(true);
    try {
      final newBooking = BookingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID generation
        userId: userId,
        packageId: _selectedPackage!.id,
        slotId: _selectedSlot?.id,
        bookingDate: DateTime.now(),
        totalPaid: amount,
        status: BookingStatus.upcoming,
        sessionNumber: 1, // Logic to increment this based on user history would go here
      );

      await _repository.createBooking(newBooking);
      await fetchUserBookings(userId); // Refresh history
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
