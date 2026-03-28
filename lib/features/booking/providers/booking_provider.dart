import 'package:flutter/material.dart';
import '../models/package_model.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
import '../repository/booking_repository.dart';
import 'dart:async';

enum PaymentMethodOption { card, applePay, eWallet, fpx }

class BookingProvider extends ChangeNotifier {
  final BookingRepository _repository = BookingRepository();

  // State variables
  List<PackageModel> _packages = [];
  List<SlotModel> _slots = [];
  List<BookingModel> _userBookings = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  final DateTime _bookingWindowStartDate = _localToday();
  PackageModel? _selectedPackage;
  late DateTime _selectedDate = _bookingWindowStartDate;
  SlotModel? _selectedSlot;
  PaymentMethodOption _selectedPaymentMethod = PaymentMethodOption.card;

  static DateTime _localToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  StreamSubscription<List<PackageModel>>? _packagesSubscription;
  StreamSubscription<List<SlotModel>>? _slotsSubscription;

  // Getters
  List<PackageModel> get packages => _packages;
  List<SlotModel> get slots => _slots;
  List<BookingModel> get userBookings => _userBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  PackageModel? get selectedPackage => _selectedPackage;
  DateTime get selectedDate => _selectedDate;
  SlotModel? get selectedSlot => _selectedSlot;
  PaymentMethodOption get selectedPaymentMethod => _selectedPaymentMethod;
  DateTime get bookingWindowStartDate => _bookingWindowStartDate;
  List<DateTime> get bookingWindowDates => List<DateTime>.generate(
        7,
        (index) => _bookingWindowStartDate.add(Duration(days: index)),
      );

  bool isWithinBookingWindow(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final bookingWindowEndExclusive =
        _bookingWindowStartDate.add(const Duration(days: 7));

    return !normalizedDate.isBefore(_bookingWindowStartDate) &&
        normalizedDate.isBefore(bookingWindowEndExclusive);
  }

  bool get canProceedToPayment =>
      _selectedPackage != null && _selectedSlot != null;

  Map<String, dynamic>? buildCheckoutContext({double sstRate = 0.08}) {
    if (!canProceedToPayment) {
      return null;
    }

    final package = _selectedPackage!;
    final slot = _selectedSlot!;
    final subtotal = package.price;
    final sst = subtotal * sstRate;
    final total = subtotal + sst;

    return {
      'packageId': package.id,
      'packageName': package.name,
      'slotId': slot.id,
      'slotStartTimeIso': slot.startTime.toIso8601String(),
      'slotEndTimeIso': slot.endTime.toIso8601String(),
      'selectedDateIso': _selectedDate.toIso8601String(),
      'paymentMethod': _selectedPaymentMethod.name,
      'subtotal': subtotal,
      'sst': sst,
      'total': total,
    };
  }

  // Setters/Selectors
  void selectPackage(PackageModel package) {
    _selectedPackage = package;
    _selectedSlot = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> selectDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (!isWithinBookingWindow(normalizedDate)) {
      return;
    }

    final isSameDay = _selectedDate.year == normalizedDate.year &&
        _selectedDate.month == normalizedDate.month &&
        _selectedDate.day == normalizedDate.day;

    if (isSameDay) return;

    _selectedDate = normalizedDate;
    _selectedSlot = null;
    _errorMessage = null;
    notifyListeners();

    await fetchSlotsForDate(_selectedDate);
    startListeningSlotsForDate(_selectedDate);
  }

  void selectSlot(SlotModel slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethodOption method) {
    if (_selectedPaymentMethod == method) {
      return;
    }

    _selectedPaymentMethod = method;
    notifyListeners();
  }

  // Business Logic
  Future<void> initializePackagesPage() async {
    // Fetch first to guarantee full list render, then attach realtime updates.
    await fetchPackages();
    await fetchSlotsForDate(_selectedDate);
    startListeningPackages();
    startListeningSlotsForDate(_selectedDate);
  }

  Future<void> initializeBookSession() async {
    if (_selectedPackage == null) {
      _errorMessage = 'Please select a package first.';
      notifyListeners();
      return;
    }

    await fetchSlotsForDate(_selectedDate);
    startListeningSlotsForDate(_selectedDate);
  }

  Future<void> refreshBookSession() async {
    await fetchSlotsForDate(_selectedDate);
  }

  Future<void> refreshPackagesPage() async {
    await fetchPackages();
    await fetchSlotsForDate(_selectedDate);
  }

  void startListeningPackages() {
    _packagesSubscription?.cancel();
    _packagesSubscription = _repository.streamPackages().listen(
      (data) {
        _packages = data;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  void startListeningSlotsForDate(DateTime date) {
    _slotsSubscription?.cancel();
    _slotsSubscription = _repository.streamSlotsByDate(date).listen(
      (data) {
        _slots = data;
        _errorMessage = null;
        _syncSelectedSlotWithAvailableSlots();
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

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
      _syncSelectedSlotWithAvailableSlots();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _syncSelectedSlotWithAvailableSlots() {
    if (_selectedSlot == null) {
      return;
    }

    final match = _slots.where((slot) => slot.id == _selectedSlot!.id);
    if (match.isEmpty) {
      _selectedSlot = null;
      return;
    }

    _selectedSlot = match.first;
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

  @override
  void dispose() {
    _packagesSubscription?.cancel();
    _slotsSubscription?.cancel();
    super.dispose();
  }
}
