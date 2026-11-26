import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '../enum/booking_status.enum.dart';

import '../fixtures/booking.fixtures.dart';

part 'booking.model.freezed.dart';
part 'booking.model.g.dart';

/// Comprehensive model representing a client security booking or bodyguard dispatch mission.
@freezed
abstract class BookingModel with _$BookingModel {
  const factory BookingModel({
    required String id,
    required String bookingNumber,
    required DateTime startDateTime,
    required DateTime endDateTime,
    @JsonKey(includeToJson: false) required BodyGuardModel bodyguard,
    @JsonKey(includeToJson: false) required UserModel customer,
    required BookingStatus status,
    GuardService? serviceType,
    String? pickupAddress,
    String? destinationAddress,
    double? hourlyRate,
    double? totalAmount,
    @Default('USD') String currency,
    String? scheduleLabel,
    String? specialInstructions,
    String? bodyguardSpecialization,
    String? trackingStatusText,
    double? customerRating,
    String? customerReviewText,
    required DateTime createdAt,
  }) = _BookingModel;

  factory BookingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingModelFromJson(json);

  /// Curated list of mock bookings across lifecycle states (Pending, Ongoing, Completed).
  @Deprecated('Use bookingFixtures from data/fixtures/booking.fixtures.dart')
  static List<BookingModel> get fakeData => bookingFixtures;
}
