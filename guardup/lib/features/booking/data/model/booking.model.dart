import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../gen/assets.gen.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '../enum/booking_status.enum.dart';

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
  static List<BookingModel> get fakeData => [
    BookingModel(
      id: 'bk_cust_001',
      bookingNumber: '#9878213',
      startDateTime: DateTime(2025, 4, 24, 14, 0),
      endDateTime: DateTime(2025, 4, 24, 18, 0),
      bodyguard: BodyGuardModel(
        id: 'guard_vikram',
        user: UserModel(
          id: 'usr_vikram',
          name: 'Vikram Singh',
          profileImageUrl: Assets.images.profilePicture.path,
          role: UserRole.guard,
        ),
        hourlyRate: 60.0,
        bio: 'Executive security specialist.',
        rating: 0.0,
        experienceYears: 0,
        status: UserStatus.active,
      ),
      customer: const UserModel(
        id: 'usr_me',
        name: 'Client Account',
        role: UserRole.customer,
      ),
      status: BookingStatus.completed,
      hourlyRate: 60.0,
      bodyguardSpecialization: 'Licensed armed, Corporate visits',
      scheduleLabel: 'Apr 24, 2025 • 2:00 PM – 6:00 PM',
      pickupAddress: 'Yorkville Plaza, Toronto, ON',
      createdAt: DateTime(2025, 4, 20),
    ),
    BookingModel(
      id: 'bk_cust_002',
      bookingNumber: '#9878214',
      startDateTime: DateTime.now().subtract(const Duration(hours: 1)),
      endDateTime: DateTime.now().add(const Duration(hours: 3)),
      bodyguard: BodyGuardModel(
        id: 'guard_rahul',
        user: UserModel(
          id: 'usr_rahul',
          name: 'Rahul Patel',
          profileImageUrl: Assets.images.profilePicture2.path,
          role: UserRole.guard,
        ),
        hourlyRate: 60.0,
        bio: 'Close protection operative.',
        rating: 0.0,
        experienceYears: 0,
        status: UserStatus.active,
      ),
      customer: const UserModel(
        id: 'usr_me',
        name: 'Client Account',
        role: UserRole.customer,
      ),
      status: BookingStatus.onGoing,
      hourlyRate: 60.0,
      bodyguardSpecialization: 'Licensed armed, Corporate visits',
      trackingStatusText: 'Started 10:00 AM • ETA 1:00 PM',
      pickupAddress: 'Yorkville Plaza, Toronto, ON',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    BookingModel(
      id: 'bk_cust_003',
      bookingNumber: '#9878215',
      startDateTime: DateTime.now().subtract(const Duration(days: 1)),
      endDateTime: DateTime.now().subtract(const Duration(days: 1, hours: -4)),
      bodyguard: BodyGuardModel(
        id: 'guard_siwa',
        user: UserModel(
          id: 'usr_siwa',
          name: 'Siwa Patel',
          profileImageUrl: Assets.images.profilePicture.path,
          role: UserRole.guard,
        ),
        hourlyRate: 60.0,
        bio: 'Senior dignitary bodyguard.',
        rating: 0.0,
        experienceYears: 0,
        status: UserStatus.active,
      ),
      customer: const UserModel(
        id: 'usr_me',
        name: 'Client Account',
        role: UserRole.customer,
      ),
      status: BookingStatus.completed,
      hourlyRate: 60.0,
      bodyguardSpecialization: 'Licensed armed, Corporate visits',
      scheduleLabel: 'Today, Apr 18 • 2:00 PM – 6:00 PM',
      pickupAddress: 'Yorkville Plaza, Toronto, ON',
      customerRating: 0.0,
      customerReviewText: null,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    BookingModel(
      id: 'bk_cust_004',
      bookingNumber: '#9878216',
      startDateTime: DateTime.now().subtract(const Duration(minutes: 30)),
      endDateTime: DateTime.now().add(const Duration(hours: 2)),
      bodyguard: BodyGuardModel(
        id: 'guard_marcus',
        user: UserModel(
          id: 'usr_marcus',
          name: 'Marcus Sterling',
          profileImageUrl: Assets.images.profilePicture.path,
          role: UserRole.guard,
        ),
        hourlyRate: 60.0,
        bio: 'Tactical motorcade specialist.',
        rating: 0.0,
        experienceYears: 0,
        status: UserStatus.active,
      ),
      customer: const UserModel(id: 'usr_me', name: 'Client Account'),
      status: BookingStatus.onGoing,
      hourlyRate: 60.0,
      bodyguardSpecialization: 'Tactical Motorcade Escort',
      trackingStatusText: 'Started 11:30 AM • ETA 2:30 PM',
      pickupAddress: 'The Ritz-Carlton, Wellington St, Toronto',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    BookingModel(
      id: 'bk_cust_005',
      bookingNumber: '#9878217',
      startDateTime: DateTime.now().add(const Duration(days: 1)),
      endDateTime: DateTime.now().add(const Duration(days: 1, hours: 5)),
      bodyguard: BodyGuardModel(
        id: 'guard_david',
        user: UserModel(
          id: 'usr_david',
          name: 'David Sterling',
          profileImageUrl: Assets.images.profilePicture2.path,
          role: UserRole.guard,
        ),
        hourlyRate: 60.0,
        bio: 'Dignitary protection.',
        rating: 0.0,
        experienceYears: 0,
        status: UserStatus.active,
      ),
      customer: const UserModel(id: 'usr_me', name: 'Client Account'),
      status: BookingStatus.pending,
      hourlyRate: 60.0,
      bodyguardSpecialization: 'Licensed armed, Corporate visits',
      scheduleLabel: 'Tomorrow, Apr 29 • 1:00 PM – 6:00 PM',
      pickupAddress: 'Four Seasons Hotel, Yorkville, Toronto',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];
}
