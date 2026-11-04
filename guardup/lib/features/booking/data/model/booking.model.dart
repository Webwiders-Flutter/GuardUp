import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '/gen/assets.gen.dart';
import '../enum/booking_status.enum.dart';

/// Comprehensive model representing a client security booking or bodyguard dispatch mission.
class BookingModel {
  final String id;
  final String bookingNumber;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final BodyGuardModel bodyguard;
  final UserModel customer;
  final BookingStatus status;
  final GuardService? serviceType;
  final String? pickupAddress;
  final String? destinationAddress;
  final double? hourlyRate;
  final double? totalAmount;
  final String currency;
  final String? scheduleLabel;
  final String? specialInstructions;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.bookingNumber,
    required this.startDateTime,
    required this.endDateTime,
    required this.bodyguard,
    required this.customer,
    required this.status,
    this.serviceType,
    this.pickupAddress,
    this.destinationAddress,
    this.hourlyRate,
    this.totalAmount,
    this.currency = 'USD',
    this.scheduleLabel,
    this.specialInstructions,
    required this.createdAt,
  });

  /// Duration of the security assignment in fractional hours.
  double get durationInHours {
    final diffMinutes = endDateTime.difference(startDateTime).inMinutes;
    return diffMinutes > 0 ? diffMinutes / 60.0 : 0.0;
  }

  /// Formatted duration string (e.g. "4 Hours", "2.5 Hours").
  String get formattedDuration {
    final hours = durationInHours;
    if (hours.truncateToDouble() == hours) {
      final intHours = hours.toInt();
      return '$intHours ${intHours == 1 ? 'Hour' : 'Hours'}';
    }
    return '${hours.toStringAsFixed(1)} Hours';
  }

  /// Effective hourly rate (falls back to bodyguard rate or $60).
  double get effectiveHourlyRate => hourlyRate ?? bodyguard.hourlyRate;

  /// Readable display date representation (e.g. "12 Jun 2026").
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final monthStr = months[startDateTime.month - 1];
    return '${startDateTime.day.toString().padLeft(2, '0')} $monthStr ${startDateTime.year}';
  }

  /// Formatted time window (e.g. "2:00 PM – 6:00 PM").
  String get formattedTimeRange {
    return '${_formatTime(startDateTime)} – ${_formatTime(endDateTime)}';
  }

  /// Formatted full schedule row (e.g. "Tomorrow, Apr 28 • 2:00 PM – 6:00 PM").
  String get formattedSchedule {
    if (scheduleLabel != null && scheduleLabel!.isNotEmpty) {
      return scheduleLabel!;
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    String prefix;
    if (startDateTime.year == now.year &&
        startDateTime.month == now.month &&
        startDateTime.day == now.day) {
      prefix = 'Today, ';
    } else if (startDateTime.year == tomorrow.year &&
        startDateTime.month == tomorrow.month &&
        startDateTime.day == tomorrow.day) {
      prefix = 'Tomorrow, ';
    } else {
      prefix = '';
    }
    final monthDay = '${months[startDateTime.month - 1]} ${startDateTime.day}';
    return '$prefix$monthDay • $formattedTimeRange';
  }

  static String _formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  BookingModel copyWith({
    String? id,
    String? bookingNumber,
    DateTime? startDateTime,
    DateTime? endDateTime,
    BodyGuardModel? bodyguard,
    UserModel? customer,
    BookingStatus? status,
    GuardService? serviceType,
    String? serviceTitle,
    String? pickupAddress,
    String? destinationAddress,
    double? hourlyRate,
    double? totalAmount,
    String? currency,
    String? scheduleLabel,
    String? specialInstructions,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      bodyguard: bodyguard ?? this.bodyguard,
      customer: customer ?? this.customer,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      scheduleLabel: scheduleLabel ?? this.scheduleLabel,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingNumber': bookingNumber,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'bodyguard': bodyguard.toJson(),
      'customer': customer.toJson(),
      'status': status.apiValue,
      if (serviceType != null) 'serviceType': serviceType!.apiValue,
      if (pickupAddress != null) 'pickupAddress': pickupAddress,
      if (destinationAddress != null) 'destinationAddress': destinationAddress,
      if (hourlyRate != null) 'hourlyRate': hourlyRate,
      if (totalAmount != null) 'totalAmount': totalAmount,
      'currency': currency,
      if (scheduleLabel != null) 'scheduleLabel': scheduleLabel,
      if (specialInstructions != null) 'specialInstructions': specialInstructions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String? ?? '',
      bookingNumber: json['bookingNumber'] as String? ?? '',
      startDateTime: DateTime.tryParse(json['startDateTime'] as String? ?? '') ??
          DateTime.now(),
      endDateTime: DateTime.tryParse(json['endDateTime'] as String? ?? '') ??
          DateTime.now().add(const Duration(hours: 4)),
      bodyguard: BodyGuardModel.fromJson(
        json['bodyguard'] as Map<String, dynamic>,
      ),
      customer: UserModel.fromJson(
        json['customer'] as Map<String, dynamic>,
      ),
      status: BookingStatus.fromApiValue(json['status'] as String?),
      serviceType: GuardService.tryFromApiValue(json['serviceType'] as String?),
      pickupAddress: json['pickupAddress'] as String?,
      destinationAddress: json['destinationAddress'] as String?,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      scheduleLabel: json['scheduleLabel'] as String?,
      specialInstructions: json['specialInstructions'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Fake Mock Bookings Matching UI Reference Designs
  // ---------------------------------------------------------------------------

  /// Pending confirmation booking (Card 1 in UI mockups).
  static BookingModel get fakePendingBooking => BookingModel(
    id: 'bk_pending_001',
    bookingNumber: '#9878213',
    startDateTime: DateTime.now().add(const Duration(days: 1)),
    endDateTime: DateTime.now().add(const Duration(days: 1, hours: 4)),
    bodyguard: BodyGuardModel.fakeBodyGuard,
    customer: UserModel(
      id: 'usr_deepak',
      name: 'Deepak Pandey',
      profileImageUrl: Assets.images.profilePicture.path,
      role: UserRole.customer,
    ),
    status: BookingStatus.pending,
    hourlyRate: 60.0,
    scheduleLabel: 'Tomorrow, Apr 28 • 2:00 PM – 6:00 PM',
    pickupAddress: 'Yorkville Plaza, Toronto, ON',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  /// Running / ongoing active mission (Card 2 in UI mockups).
  static BookingModel get fakeOngoingBooking => BookingModel(
    id: 'bk_ongoing_002',
    bookingNumber: '#9878213',
    startDateTime: DateTime.now().add(const Duration(days: 1)),
    endDateTime: DateTime.now().add(const Duration(days: 1, hours: 4)),
    bodyguard: BodyGuardModel.fakeBodyGuard,
    customer: UserModel(
      id: 'usr_marco',
      name: 'Marco Michel',
      profileImageUrl: Assets.images.profilePicture2.path,
      role: UserRole.customer,
    ),
    status: BookingStatus.onGoing,
    hourlyRate: 60.0,
    scheduleLabel: 'Tomorrow, Apr 28 • 2:00 PM – 6:00 PM',
    pickupAddress: 'Yorkville Plaza, Toronto, ON',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  );

  /// Completed protection assignment (Card 3 in UI mockups).
  static BookingModel get fakeCompletedBooking => BookingModel(
    id: 'bk_completed_003',
    bookingNumber: '#9878213',
    startDateTime: DateTime.now().add(const Duration(days: 1)),
    endDateTime: DateTime.now().add(const Duration(days: 1, hours: 4)),
    bodyguard: BodyGuardModel.fakeBodyGuard,
    customer: UserModel(
      id: 'usr_harry',
      name: 'Harry Porter',
      profileImageUrl: Assets.images.profilePicture.path,
      role: UserRole.customer,
    ),
    status: BookingStatus.completed,
    hourlyRate: 60.0,
    scheduleLabel: 'Tomorrow, Apr 28 • 2:00 PM – 6:00 PM',
    pickupAddress: 'Yorkville Plaza, Toronto, ON',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  );

  /// Curated list of 18 mock bookings matching the UI mockups and counts.
  static List<BookingModel> get fakeBookings => [
    // Top 3 featured cards matching design mockup
    fakePendingBooking,
    fakeOngoingBooking,
    fakeCompletedBooking,

    // Additional Running (Ongoing) Bookings
    BookingModel(
      id: 'bk_run_004',
      bookingNumber: '#9878214',
      startDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      endDateTime: DateTime.now().add(const Duration(hours: 3)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_elena',
        name: 'Elena Rostova',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.onGoing,
      hourlyRate: 60.0,
      scheduleLabel: 'Today • 1:00 PM – 6:00 PM',
      pickupAddress: 'Financial District, Bay St, Toronto',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    BookingModel(
      id: 'bk_run_005',
      bookingNumber: '#9878215',
      startDateTime: DateTime.now().subtract(const Duration(minutes: 45)),
      endDateTime: DateTime.now().add(const Duration(hours: 4)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_marcus',
        name: 'Marcus Sterling',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.onGoing,
      hourlyRate: 60.0,
      scheduleLabel: 'Today • 3:00 PM – 7:30 PM',
      pickupAddress: 'The Ritz-Carlton, Wellington St, Toronto',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    BookingModel(
      id: 'bk_run_006',
      bookingNumber: '#9878216',
      startDateTime: DateTime.now().subtract(const Duration(hours: 1)),
      endDateTime: DateTime.now().add(const Duration(hours: 5)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_lucas',
        name: 'Lucas Silva',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.onGoing,
      hourlyRate: 60.0,
      scheduleLabel: 'Today • 2:00 PM – 8:00 PM',
      pickupAddress: 'Four Seasons Hotel, Yorkville, Toronto',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),

    // Additional Pending Bookings
    BookingModel(
      id: 'bk_pen_007',
      bookingNumber: '#9878217',
      startDateTime: DateTime.now().add(const Duration(days: 2)),
      endDateTime: DateTime.now().add(const Duration(days: 2, hours: 6)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_sophia',
        name: 'Sophia Vance',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.pending,
      hourlyRate: 60.0,
      scheduleLabel: 'Wednesday, Apr 29 • 10:00 AM – 4:00 PM',
      pickupAddress: 'Harbourfront Centre, Toronto, ON',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    BookingModel(
      id: 'bk_pen_008',
      bookingNumber: '#9878218',
      startDateTime: DateTime.now().add(const Duration(days: 3)),
      endDateTime: DateTime.now().add(const Duration(days: 3, hours: 5)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_alex',
        name: 'Alexander Cross',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.pending,
      hourlyRate: 60.0,
      scheduleLabel: 'Thursday, Apr 30 • 6:00 PM – 11:00 PM',
      pickupAddress: 'TIFF Lightbox, King St W, Toronto',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    BookingModel(
      id: 'bk_pen_009',
      bookingNumber: '#9878219',
      startDateTime: DateTime.now().add(const Duration(days: 3, hours: 2)),
      endDateTime: DateTime.now().add(const Duration(days: 3, hours: 8)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_liam',
        name: 'Liam Chen',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.pending,
      hourlyRate: 60.0,
      scheduleLabel: 'Thursday, Apr 30 • 12:00 PM – 6:00 PM',
      pickupAddress: 'Pearson Executive Tarmac, Toronto',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    BookingModel(
      id: 'bk_pen_010',
      bookingNumber: '#9878220',
      startDateTime: DateTime.now().add(const Duration(days: 4)),
      endDateTime: DateTime.now().add(const Duration(days: 4, hours: 4)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_olivia',
        name: 'Olivia Davis',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.pending,
      hourlyRate: 60.0,
      scheduleLabel: 'Friday, May 1 • 8:00 AM – 12:00 PM',
      pickupAddress: 'King Edward Hotel, Toronto, ON',
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    ),
    BookingModel(
      id: 'bk_pen_011',
      bookingNumber: '#9878221',
      startDateTime: DateTime.now().add(const Duration(days: 5)),
      endDateTime: DateTime.now().add(const Duration(days: 5, hours: 6)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_noah',
        name: 'Noah Martin',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.pending,
      hourlyRate: 60.0,
      scheduleLabel: 'Saturday, May 2 • 7:00 PM – 1:00 AM',
      pickupAddress: 'Private Residence, Forest Hill, Toronto',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),

    // Additional Completed Bookings
    BookingModel(
      id: 'bk_comp_012',
      bookingNumber: '#9878222',
      startDateTime: DateTime.now().subtract(const Duration(days: 2)),
      endDateTime: DateTime.now().subtract(const Duration(days: 2, hours: -4)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_carlos',
        name: 'Carlos Sterling',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.completed,
      hourlyRate: 60.0,
      scheduleLabel: 'Sunday, Apr 26 • 2:00 PM – 6:00 PM',
      pickupAddress: 'Royal Ontario Museum, Toronto, ON',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    BookingModel(
      id: 'bk_comp_013',
      bookingNumber: '#9878223',
      startDateTime: DateTime.now().subtract(const Duration(days: 3)),
      endDateTime: DateTime.now().subtract(const Duration(days: 3, hours: -5)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_david',
        name: 'David Miller',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.completed,
      hourlyRate: 60.0,
      scheduleLabel: 'Saturday, Apr 25 • 4:00 PM – 9:00 PM',
      pickupAddress: 'Scotiabank Arena, VIP Gate 2, Toronto',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    BookingModel(
      id: 'bk_comp_014',
      bookingNumber: '#9878224',
      startDateTime: DateTime.now().subtract(const Duration(days: 4)),
      endDateTime: DateTime.now().subtract(const Duration(days: 4, hours: -3)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_emma',
        name: 'Emma Watson',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.completed,
      hourlyRate: 60.0,
      scheduleLabel: 'Friday, Apr 24 • 11:00 AM – 2:00 PM',
      pickupAddress: 'Yorkville Luxury Village, Toronto, ON',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    BookingModel(
      id: 'bk_comp_015',
      bookingNumber: '#9878225',
      startDateTime: DateTime.now().subtract(const Duration(days: 5)),
      endDateTime: DateTime.now().subtract(const Duration(days: 5, hours: -8)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_james',
        name: 'James Wilson',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.completed,
      hourlyRate: 60.0,
      scheduleLabel: 'Thursday, Apr 23 • 9:00 AM – 5:00 PM',
      pickupAddress: 'Metro Toronto Convention Centre',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    BookingModel(
      id: 'bk_comp_016',
      bookingNumber: '#9878226',
      startDateTime: DateTime.now().subtract(const Duration(days: 6)),
      endDateTime: DateTime.now().subtract(const Duration(days: 6, hours: -4)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_isabella',
        name: 'Isabella Rossi',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.completed,
      hourlyRate: 60.0,
      scheduleLabel: 'Wednesday, Apr 22 • 1:00 PM – 5:00 PM',
      pickupAddress: 'Distillery Historic District, Toronto',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    BookingModel(
      id: 'bk_comp_017',
      bookingNumber: '#9878227',
      startDateTime: DateTime.now().subtract(const Duration(days: 7)),
      endDateTime: DateTime.now().subtract(const Duration(days: 7, hours: -6)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_ethan',
        name: 'Ethan Hunt',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.completed,
      hourlyRate: 60.0,
      scheduleLabel: 'Tuesday, Apr 21 • 10:00 AM – 4:00 PM',
      pickupAddress: 'Billy Bishop Toronto City Airport',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    BookingModel(
      id: 'bk_comp_018',
      bookingNumber: '#9878228',
      startDateTime: DateTime.now().subtract(const Duration(days: 8)),
      endDateTime: DateTime.now().subtract(const Duration(days: 8, hours: -5)),
      bodyguard: BodyGuardModel.fakeBodyGuard,
      customer: UserModel(
        id: 'usr_mia',
        name: 'Mia Taylor',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.customer,
      ),
      status: BookingStatus.completed,
      hourlyRate: 60.0,
      scheduleLabel: 'Monday, Apr 20 • 3:00 PM – 8:00 PM',
      pickupAddress: 'Bloor-Yorkville Heritage Area, Toronto',
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
    ),
  ];
}
