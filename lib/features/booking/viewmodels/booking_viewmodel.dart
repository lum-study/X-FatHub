import 'package:flutter/material.dart';
import '../models/package_model.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
import '../models/gym_model.dart';
import '../repositories/booking_repository.dart';
import '../../../core/database/local_booking_db.dart';
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
  List<GymModel> _selectedPackageGyms = [];
  Set<String> _selectedPackageGymIds = <String>{};
  List<BookingModel> _userBookings = [];

  bool _isLoading = false;
  String? _errorMessage;
  int _sessionsRemaining = 0;
  DateTime? _nextExpiryDate;
  String? _latestQrCodeData;
  final Map<String, int> _sessionsRemainingByPackage = {};
  final Map<String, DateTime> _expiryByPackage = {};
  final Map<String, String> _cachedPackageNameByBookingId = {};
  bool _isUsingLocalBookingCache = false;

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

  List<PackageModel> get packages => _packages;
  List<SlotModel> get slots => _slots;
  List<GymModel> get selectedPackageGyms =>
      List<GymModel>.unmodifiable(_selectedPackageGyms);
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
  bool get isUsingLocalBookingCache => _isUsingLocalBookingCache;
  Set<String> get selectedPackageGymIds =>
      Set<String>.unmodifiable(_selectedPackageGymIds);
  List<String> get allowedClassNames =>
      _selectedPackage?.allowedClassNames ?? [];
  String? packageNameForBooking(String bookingId) =>
      _cachedPackageNameByBookingId[bookingId];

  SlotModel? slotById(String slotId) {
    try {
      return _slots.firstWhere((s) => s.id == slotId);
    } catch (_) {
      return null;
    }
  }

  int sessionsRemainingForPackage(String packageId) {
    return _sessionsRemainingByPackage[packageId] ?? 0;
  }

  DateTime? expiryForPackage(String packageId) {
    return _expiryByPackage[packageId];
  }

  List<PackageModel> get activePackages {
    final now = DateTime.now();
    final list = _packages.where((p) {
      final sessions = _sessionsRemainingByPackage[p.id] ?? 0;
      final expiry = _expiryByPackage[p.id];
      final isExpired = expiry != null && expiry.isBefore(now);
      return sessions > 0 && !isExpired && p.isActive;
    }).toList();

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
      .where((p) {
        final sessions = _sessionsRemainingByPackage[p.id] ?? 0;
        final expiry = _expiryByPackage[p.id];
        final isExpired = expiry != null && expiry.isBefore(DateTime.now());
        // Buyable if: no sessions remaining, NOT expired, and IS active in store
        return sessions <= 0 && !isExpired && p.isActive;
      })
      .toList();

  List<PackageModel> get inactivePackages {
    final now = DateTime.now();
    return _packages.where((p) {
      final sessions = _sessionsRemainingByPackage[p.id] ?? 0;
      final expiry = _expiryByPackage[p.id];
      final isExpired = expiry != null && expiry.isBefore(now);

      // Inactive if:
      // 1. It is expired (even if it has sessions)
      // 2. OR it is deactivated in the store (isActive == false)
      return isExpired || !p.isActive;
    }).toList();
  }

  // Helper to check if a package is active (has credits and not expired)
  bool isPackageActive(String packageId) {
    final sessions = _sessionsRemainingByPackage[packageId] ?? 0;
    final expiry = _expiryByPackage[packageId];
    final isExpired = expiry != null && expiry.isBefore(DateTime.now());
    return sessions > 0 && !isExpired;
  }


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
          booking.slotId == slotId && (booking.status != BookingStatus.upcoming || booking.status != BookingStatus.missed || booking.status != BookingStatus.completed),
    );
  }

  bool _isSlotAllowedForPackage(PackageModel package, SlotModel slot) {
    final normalizedSlotClass = slot.className.trim().toLowerCase();
    if (normalizedSlotClass.isEmpty) {
      return false;
    }

    if (package.allowedClassNames.isNotEmpty) {
      final matchesClass = package.allowedClassNames.any(
        (allowed) => allowed.trim().toLowerCase() == normalizedSlotClass,
      );
      if (!matchesClass) {
        return false;
      }
    }

    final gymIdsFromModels = _selectedPackageGyms
        .map((gym) => gym.id)
        .where((id) => id.isNotEmpty)
        .toSet();

    final allowedGymIds = <String>{
      ...gymIdsFromModels,
      ..._selectedPackageGymIds,
    };

    if (allowedGymIds.isNotEmpty && !allowedGymIds.contains(slot.gymId)) {
      return false;
    }

    return true;
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
    _selectedPackageGyms = [];
    _selectedPackageGymIds = <String>{};
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadSelectedPackageDetails({bool setLoading = false}) async {
    final package = _selectedPackage;
    if (package == null) {
      _selectedPackageGyms = [];
      _selectedPackageGymIds = <String>{};
      notifyListeners();
      return;
    }

    if (setLoading) {
      _setLoading(true);
    }

    try {
      _selectedPackageGyms = await _repository.fetchPackageGyms(package.id);
      _selectedPackageGymIds = (await _repository.fetchPackageGymIds(
        package.id,
      )).toSet();
      _errorMessage = null;
    } catch (e) {
      _selectedPackageGyms = [];
      _selectedPackageGymIds = <String>{};
      _errorMessage = 'Package details error: ${e.toString()}';
    } finally {
      if (setLoading) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
    }
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

    // Ensure package details are loaded before fetching slots.
    await loadSelectedPackageDetails(setLoading: false);
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
    await refreshCurrentUserBookingData();
  }

  Future<void> initializeBookSession() async {
    if (_selectedPackage == null) {
      _errorMessage = 'Please select a package first.';
      notifyListeners();
      return;
    }

    await loadSelectedPackageDetails(setLoading: false);
    await fetchSlotsForDate(_selectedDate);
    await refreshCurrentUserBookingData();
  }

  Future<void> refreshBookSession() async {
    await loadSelectedPackageDetails(setLoading: false);
    await fetchSlotsForDate(_selectedDate);
  }

  Future<void> refreshPackagesPage() async {
    await fetchPackages();
    await refreshCurrentUserBookingData();
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
      var filteredSlots = _filterSlotsForSelectedPackage(fetchedSlots);

      if (_isToday(date)) {
        filteredSlots = _filterPastSlots(filteredSlots);
      }

      _slots = filteredSlots;
      _errorMessage = null;
      _syncSelectedSlotWithAvailableSlots();
    } catch (e) {
      _errorMessage = 'Slot fetch error: ${e.toString()}';
    } finally {
      if (setLoading) {
        _setLoading(false);
      }
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  List<SlotModel> _filterPastSlots(List<SlotModel> slots) {
    final now = DateTime.now();
    return slots.where((slot) {
      return slot.startTime.isAfter(now);
    }).toList();
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

  Future<bool> fetchUserBookings(
    String userId, {
    bool setLoading = true,
  }) async {
    if (setLoading) {
      _setLoading(true);
    }
    try {
      final bookings = await _repository.fetchUserBookings(userId);
      _userBookings = bookings;
      _errorMessage = null;
      _isUsingLocalBookingCache = false;

      // Sync missed bookings to backend
      await _repository.syncMissedBookings(userId, bookings);
      
      // Update memory cache for package names
      final packages = await _repository.fetchPackages();
      final packageNameById = {for (final p in packages) p.id: p.name};
      
      for (final b in bookings) {
        final name = packageNameById[b.packageId];
        if (name != null) {
          _cachedPackageNameByBookingId[b.id] = name;
        }
      }

      await _syncAllBookingsToLocalCache(userId);
      return bookings.isNotEmpty;
    } catch (e) {
      _errorMessage = e.toString();
      if (_userBookings.isEmpty) {
        await _loadBookingsFromLocalCache(userId);
      }
      return _userBookings.isNotEmpty;
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

    try {
      // Try fetching from remote first
      final bookings = await _repository.fetchUserBookings(userId);
      _userBookings = bookings;
      _isUsingLocalBookingCache = false;

      // Sync missed bookings to backend
      await _repository.syncMissedBookings(userId, bookings);
      
      // Update local cache with fresh data
      await _syncAllBookingsToLocalCache(userId);
      
      // Fetch other data if possible
      try {
        await fetchActivePackageCredits(setLoading: false);
        await fetchCreditBalance(
          packageId: _selectedPackage?.id,
          setLoading: false,
        );
      } catch (_) {}
    } catch (e) {
      // If remote fails (e.g. offline), load from local cache
      await _loadBookingsFromLocalCache(userId);
    }

    notifyListeners();
  }

  Future<void> _syncAllBookingsToLocalCache(String userId) async {
    try {
      final packageNameById = {for (final p in _packages) p.id: p.name};

      final rows = _userBookings
          .map(
            (b) => {
              'id': b.id,
              'user_id': b.userId,
              'package_id': b.packageId,
              'package_name': b.packageName ?? packageNameById[b.packageId] ?? _cachedPackageNameByBookingId[b.id] ?? '',
              'slot_id': b.slotId,
              'slot_location': b.slotLocation,
              'slot_coach': b.slotCoach,
              'booking_date': b.bookingDate.toIso8601String(),
              'status': b.status.name,
              'gym_name': b.gymName,
              'gym_address': b.gymAddress,
              'qr_code_data': b.qrCodeData,
              'session_number': b.sessionNumber,
              'total_paid': b.totalPaid,
            },
          )
          .toList();

      await LocalBookingDatabase.saveBookings(
        userId: userId,
        bookings: rows,
      );
      
      // Also update the memory map for package names
      for (final b in _userBookings) {
        final name = packageNameById[b.packageId] ?? _cachedPackageNameByBookingId[b.id];
        if (name != null) {
          _cachedPackageNameByBookingId[b.id] = name;
        }
      }
    } catch (_) {}
  }

  Future<void> _loadBookingsFromLocalCache(String userId) async {
    try {
      final rows = await LocalBookingDatabase.getCachedBookings(userId);
      _cachedPackageNameByBookingId.clear();

      final cached = <BookingModel>[];
      for (final row in rows) {
        final statusRaw = row[LocalBookingDatabase.colStatus]?.toString();
        final status = _parseBookingStatus(statusRaw);
        final bookingDateRaw =
            row[LocalBookingDatabase.colBookingDate]?.toString() ?? '';

        final booking = BookingModel(
          id: row[LocalBookingDatabase.colBookingId]?.toString() ?? '',
          userId: row[LocalBookingDatabase.colUserId]?.toString() ?? userId,
          packageId: row[LocalBookingDatabase.colPackageId]?.toString() ?? '',
          slotId: row[LocalBookingDatabase.colSlotId]?.toString(),
          slotLocation: row[LocalBookingDatabase.colSlotLocation]?.toString(),
          slotCoach: row[LocalBookingDatabase.colSlotCoach]?.toString(),
          bookingDate:
              DateTime.tryParse(bookingDateRaw)?.toLocal() ?? DateTime.now(),
          status: status,
          gymName: row[LocalBookingDatabase.colGymName]?.toString(),
          gymAddress: row[LocalBookingDatabase.colGymAddress]?.toString(),
          packageName: row[LocalBookingDatabase.colPackageName]?.toString(),
          totalPaid:
              double.tryParse(
                row[LocalBookingDatabase.colTotalPaid]?.toString() ?? '0',
              ) ??
              0,
          qrCodeData: row[LocalBookingDatabase.colQrCodeData]?.toString(),
          sessionNumber:
              int.tryParse(
                row[LocalBookingDatabase.colSessionNumber]?.toString() ?? '1',
              ) ??
              1,
        );
        cached.add(booking);

        final packageName =
            row[LocalBookingDatabase.colPackageName]?.toString() ?? '';
        if (packageName.isNotEmpty && booking.id.isNotEmpty) {
          _cachedPackageNameByBookingId[booking.id] = packageName;
        }
      }

      _userBookings = cached;
      _isUsingLocalBookingCache = cached.isNotEmpty;
      if (_isUsingLocalBookingCache) {
        _errorMessage =
            'Offline mode: showing cached booking history.';
      }
    } catch (_) {
      _isUsingLocalBookingCache = false;
    }
  }

  BookingStatus _parseBookingStatus(String? raw) {
    if (raw == null || raw.isEmpty) {
      return BookingStatus.upcoming;
    }

    for (final status in BookingStatus.values) {
      if (status.name == raw) {
        return status;
      }
    }

    return BookingStatus.upcoming;
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
      
      // Force immediate re-fetch and sync to local DB
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
    super.dispose();
  }
}
