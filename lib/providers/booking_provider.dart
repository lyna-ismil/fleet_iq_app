import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// ─── Booking State ─────────────────────────────────────────
class BookingState {
  final List<BookingModel> active;
  final List<BookingModel> history;
  final bool isLoading;
  final String? errorMessage;

  const BookingState({
    this.active = const [],
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  const BookingState.initial()
      : active = const [],
        history = const [],
        isLoading = false,
        errorMessage = null;

  BookingState copyWith({
    List<BookingModel>? active,
    List<BookingModel>? history,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BookingState(
      active: active ?? this.active,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ─── Booking Notifier ──────────────────────────────────────
class BookingNotifier extends Notifier<BookingState> {
  @override
  BookingState build() => const BookingState.initial();

  /// Fetch all bookings for the current user
  Future<void> fetchBookings() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await ApiService.getMyBookings(userId);

      final activeList = (data['active'] as List? ?? [])
          .map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
          .toList();
      final historyList = (data['history'] as List? ?? [])
          .map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
          .toList();

      state = BookingState(
        active: activeList,
        history: historyList,
        isLoading: false,
      );
    } catch (e) {
      print('❌ Error fetching bookings: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load bookings',
      );
    }
  }

  /// Create a new booking
  Future<Map<String, dynamic>?> createBooking({
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
    required String pickupLocation,
    required String dropoffLocation,
  }) async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return null;

    try {
      final result = await ApiService.createBooking(
        userId: userId,
        carId: carId,
        startDate: startDate,
        endDate: endDate,
        locationBeforeRenting: pickupLocation,
        locationAfterRenting: dropoffLocation,
        estimatedLocation: dropoffLocation,
      );
      // Refresh bookings list after creation
      await fetchBookings();
      return result;
    } catch (e) {
      print('❌ Error creating booking: $e');
      return null;
    }
  }

  /// Generate NFC key for a booking (server-side)
  Future<String?> generateNfcKey(String bookingId) async {
    try {
      final result = await ApiService.generateNfcKey(bookingId);
      return result;
    } catch (e) {
      print('❌ Error generating NFC key: $e');
      return null;
    }
  }
}

// ─── Provider ──────────────────────────────────────────────
final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(
  BookingNotifier.new,
);
