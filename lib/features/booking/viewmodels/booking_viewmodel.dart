import 'package:flutter/material.dart';
import '../models/package_model.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';
import 'dart:async';

enum PaymentMethodOption { card, applePay, eWallet, fpx }

class BookingActionResult {
  final bool success;
  final bool requiresPurchase;
  final String message;
  final BookingModel? booking;

  const BookingActionResult({
    required this.success,
    required this.requiresPurchase,
    required this.message,
    this.booking,
  });
}

class BookingViewModel extends ChangeNotifier {
  final BookingRepository _repository = BookingRepository();

  List<PackageModel> _packages = [];
  List<SlotModel> _slots = [];
  List<SlotModel> _todaySlots = [];
  List<BookingModel> _userBookings = [];

  bool _isLoading = false;
  String? _errorMessage;
  int _sessionsRemaining = 0;
  DateTime? _nextExpiryDate;
  String? _latestQrCodeData;
  final Map<String, int> _sessionsRemainingByPackage = {};
  final Map<String, DateTime> _expiryByPackage = {};

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
  StreamSubscription<List<SlotModel>>? _todaySlotsSubscription;

  List<PackageModel> get packages => _packages;
  List<SlotModel> get slots => _slots;
  List<SlotModel> get todaySlots => _todaySlots;
  List<BookingModel> get userBookings => _userBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get sessionsRemaining => _sessionsRemaining;
  DateTime? get nextExpiryDate => _nextExpiryDate;
  String? get latestQrCodeData => _latestQrCodeData;
  Map<String, int> get sessionsRemainingByPackage =>
      Map.unmodifiable(_sessionsRemainingByPackage);
  Map<String, DateTime> get expiryByPackage =>
      Map.unmodifiable(_expiryByPackage);

  List<PackageModel> get activePackages {
    final list = _packages
        .where((p) => (_sessionsRemainingByPackage[p.id] ?? 0) > 0)
        .toList();

    list.sort((a, b) {
      final aExpiry = _expiryByPackage[a.id];
      final bExpiry = _expiryByPackage[b.id];
      if (aExpiry == null && bExpiry == null) return 0;
      if (aExpiry == null) return 1;
      if (bExpiry == null) return -1;
      return aExpiry.compareTo(bExpiry);
    });
    return list;
  }

  List<PackageModel> get availablePackages => _packages
      .where((p) => (_sessionsRemainingByPackage[p.id] ?? 0) <= 0)
      .toList();

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
    final bookingWindowEndExclusive = _bookingWindowStartDate.add(
      const Duration(days: 7),
    );

    return !normalizedDate.isBefore(_bookingWindowStartDate) &&
        normalizedDate.isBefore(bookingWindowEndExclusive);
  }

  bool get canProceedToPayment =>
      _selectedPackage != null && _selectedSlot != null;

  bool isSlotAlreadyBooked(String slotId) {
    return _userBookings.any(
      (booking) =>
          booking.slotId == slotId && booking.status != BookingStatus.cancelled,
    );
  }

  bool _isSlotAllowedForPackage(PackageModel package, SlotModel slot) {
    if (package.allowedClassNames.isEmpty) {
      return true;
    }

    return package.allowedClassNames.contains(slot.className);
  }

  List<SlotModel> _filterSlotsForSelectedPackage(List<SlotModel> slots) {
    final package = _selectedPackage;
    if (package == null) {
      return slots;
    }

    return slots
        .where((slot) => _isSlotAllowedForPackage(package, slot))
        .toList();
  }

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

    final isSameDay =
        _selectedDate.year == normalizedDate.year &&
        _selectedDate.month == normalizedDate.month &&
        _selectedDate.day == normalizedDate.day;

    if (isSameDay) return;

    _selectedDate = normalizedDate;
    _selectedSlot = null;
    _errorMessage = null;
    notifyListeners();

    await fetchSlotsForDate(_selectedDate);
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

  Future<void> initializePackagesPage() async {
    await fetchPackages();
    await fetchTodaySlots();
    await refreshCurrentUserBookingData();
  }

  Future<void> initializeBookSession() async {
    if (_selectedPackage == null) {
      _errorMessage = 'Please select a package first.';
      notifyListeners();
      return;
    }

    await fetchSlotsForDate(_selectedDate);
    await refreshCurrentUserBookingData();
  }

  Future<void> refreshBookSession() async {
    await fetchSlotsForDate(_selectedDate);
  }

  Future<void> refreshPackagesPage() async {
    await fetchPackages();
    await fetchTodaySlots();
    await refreshCurrentUserBookingData();
  }

  Future<void> fetchTodaySlots({bool setLoading = true}) async {
    if (setLoading) {
      _setLoading(true);
    }
    try {
      _todaySlots = await _repository.fetchSlotsByDate(_bookingWindowStartDate);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (setLoading) {
        _setLoading(false);
      }
    }
  }

  Future<void> fetchPackages({bool setLoading = true}) async {
    if (setLoading) {
      _setLoading(true);
    }
    try {
      _packages = await _repository.fetchPackages();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (setLoading) {
        _setLoading(false);
      }
    }
  }

  Future<void> fetchSlotsForDate(
    DateTime date, {
    bool setLoading = true,
  }) async {
    if (setLoading) {
      _setLoading(true);
    }
    try {
      final fetchedSlots = await _repository.fetchSlotsByDate(date);
      _slots = _filterSlotsForSelectedPackage(fetchedSlots);
      _errorMessage = null;
      _syncSelectedSlotWithAvailableSlots();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (setLoading) {
        _setLoading(false);
      }
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

  Future<void> fetchUserBookings(
    String userId, {
    bool setLoading = true,
  }) async {
    if (setLoading) {
      _setLoading(true);
    }
    try {
      _userBookings = await _repository.fetchUserBookings(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (setLoading) {
        _setLoading(false);
      }
    }
  }

  Future<void> fetchCreditBalance({
    String? packageId,
    bool setLoading = true,
  }) async {
    final userId = _safeCurrentUserId();
    if (userId == null) {
      _sessionsRemaining = 0;
      _nextExpiryDate = null;
      return;
    }

    if (setLoading) {
      _setLoading(true);
    }

    try {
      final data = await _repository.getCreditBalance(
        userId,
        packageId: packageId,
      );
      _sessionsRemaining =
          int.tryParse(data['sessions_remaining']?.toString() ?? '0') ?? 0;
      final expiryRaw = data['next_expiry_date']?.toString();
      _nextExpiryDate = expiryRaw == null || expiryRaw.isEmpty
          ? null
          : DateTime.tryParse(expiryRaw);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (setLoading) {
        _setLoading(false);
      }
    }
  }

  Future<void> fetchActivePackageCredits({bool setLoading = true}) async {
    final userId = _safeCurrentUserId();
    if (userId == null) {
      _sessionsRemainingByPackage.clear();
      _expiryByPackage.clear();
      return;
    }

    if (setLoading) {
      _setLoading(true);
    }

    try {
      final rows = await _repository.fetchUserActiveSubscriptions(userId);
      _sessionsRemainingByPackage.clear();
      _expiryByPackage.clear();

      for (final row in rows) {
        final packageId = row['package_id']?.toString();
        if (packageId == null || packageId.isEmpty) {
          continue;
        }
        final sessions =
            int.tryParse(row['sessions_remaining']?.toString() ?? '0') ?? 0;
        final expiryRaw = row['expiry_date']?.toString();
        final expiry = expiryRaw == null ? null : DateTime.tryParse(expiryRaw);

        _sessionsRemainingByPackage[packageId] = sessions;
        if (expiry != null) {
          _expiryByPackage[packageId] = expiry;
        }
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (setLoading) {
        _setLoading(false);
      }
    }
  }

  Future<void> refreshCurrentUserBookingData() async {
    final userId = _safeCurrentUserId();
    if (userId == null) {
      return;
    }

    await fetchUserBookings(userId, setLoading: false);
    await fetchActivePackageCredits(setLoading: false);
    await fetchCreditBalance(
      packageId: _selectedPackage?.id,
      setLoading: false,
    );
    notifyListeners();
  }

  Future<String> createCheckoutForSelectedPackage() async {
    final package = _selectedPackage;
    if (package == null) {
      throw Exception('Please select a package first.');
    }

    return createCheckoutForPackage(package.id);
  }

  Future<String> createCheckoutForPackage(String packageId) async {
    return _repository.createCheckoutSession(packageId: packageId);
  }

  Future<BookingActionResult> bookSelectedSlotWithCredit() async {
    final userId = _safeCurrentUserId();
    if (userId == null) {
      return const BookingActionResult(
        success: false,
        requiresPurchase: false,
        message: 'You must be logged in to continue.',
      );
    }

    if (_selectedPackage == null || _selectedSlot == null) {
      return const BookingActionResult(
        success: false,
        requiresPurchase: false,
        message: 'Please select both a package and a slot.',
      );
    }

    _setLoading(true);
    try {
      await fetchCreditBalance(
        packageId: _selectedPackage!.id,
        setLoading: false,
      );

      if (_sessionsRemaining <= 0) {
        return const BookingActionResult(
          success: false,
          requiresPurchase: true,
          message: 'No credits left. Purchase a package to continue.',
        );
      }

      final createdBooking = await _repository.createBookingWithCredit(
        userId: userId,
        packageId: _selectedPackage!.id,
        slotId: _selectedSlot!.id,
      );

      _latestQrCodeData = createdBooking.qrCodeData;
      await fetchUserBookings(userId, setLoading: false);
      await fetchCreditBalance(setLoading: false);

      return BookingActionResult(
        success: true,
        requiresPurchase: false,
        message: 'Booking confirmed successfully.',
        booking: createdBooking,
      );
    } catch (e) {
      _errorMessage = e.toString();
      return BookingActionResult(
        success: false,
        requiresPurchase: false,
        message: _errorMessage ?? 'Failed to book slot.',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelBookingWithRefund(String bookingId) async {
    final userId = _safeCurrentUserId();
    if (userId == null) {
      _errorMessage = 'You must be logged in to cancel bookings.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _repository.cancelBookingWithRefund(
        bookingId: bookingId,
        userId: userId,
      );
      await fetchUserBookings(userId, setLoading: false);
      await fetchCreditBalance(setLoading: false);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rescheduleBooking({
    required String bookingId,
    required String newSlotId,
  }) async {
    final userId = _safeCurrentUserId();
    if (userId == null) {
      _errorMessage = 'You must be logged in to reschedule bookings.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _repository.rescheduleBooking(
        bookingId: bookingId,
        userId: userId,
        newSlotId: newSlotId,
      );
      await fetchUserBookings(userId, setLoading: false);
      await fetchSlotsForDate(_selectedDate, setLoading: false);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String? _safeCurrentUserId() {
    try {
      return _repository.currentUserId;
    } catch (_) {
      return null;
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
    _todaySlotsSubscription?.cancel();
    super.dispose();
  }
}
