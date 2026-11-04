import '/features/auth/auth.dart';
import '/gen/assets.gen.dart';

/// Represents a client feedback or operative rating record.
class ReviewModel {
  final String id;
  final UserModel from;
  final UserModel to;
  final double rating;
  final String reviewDescription;
  final DateTime createdAt;
  final String? bookingId;
  final String? customFormattedDate;
  final String? serviceTag;
  final String? customFormattedTimeAgo;

  const ReviewModel({
    required this.id,
    required this.from,
    required this.to,
    required this.rating,
    required this.reviewDescription,
    required this.createdAt,
    this.bookingId,
    this.customFormattedDate,
    this.serviceTag,
    this.customFormattedTimeAgo,
  });

  /// Readable display date representation (e.g. "28 Apr 2026").
  String get displayDate {
    if (customFormattedDate != null && customFormattedDate!.isNotEmpty) {
      return customFormattedDate!;
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthStr = months[createdAt.month - 1];
    return '${createdAt.day} $monthStr ${createdAt.year}';
  }

  /// Relative human-readable time (e.g. "2 days ago").
  String get timeAgo {
    if (customFormattedTimeAgo != null && customFormattedTimeAgo!.isNotEmpty) {
      return customFormattedTimeAgo!;
    }
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
    return 'Just now';
  }

  ReviewModel copyWith({
    String? id,
    UserModel? from,
    UserModel? to,
    double? rating,
    String? reviewDescription,
    DateTime? createdAt,
    String? bookingId,
    String? customFormattedDate,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      rating: rating ?? this.rating,
      reviewDescription: reviewDescription ?? this.reviewDescription,
      createdAt: createdAt ?? this.createdAt,
      bookingId: bookingId ?? this.bookingId,
      customFormattedDate: customFormattedDate ?? this.customFormattedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from.toJson(),
      'to': to.toJson(),
      'rating': rating,
      'reviewDescription': reviewDescription,
      'createdAt': createdAt.toIso8601String(),
      if (bookingId != null) 'bookingId': bookingId,
      if (customFormattedDate != null) 'customFormattedDate': customFormattedDate,
    };
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String? ?? '',
      from: UserModel.fromJson(json['from'] as Map<String, dynamic>),
      to: UserModel.fromJson(json['to'] as Map<String, dynamic>),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewDescription: json['reviewDescription'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      bookingId: json['bookingId'] as String?,
      customFormattedDate: json['customFormattedDate'] as String?,
    );
  }

  /// Curated list of verified client reviews matching the bodyguard profile design.
  static List<ReviewModel> get fakeBodyguardReviews => [
    ReviewModel(
      id: 'rev_elena',
      from: UserModel(
        id: 'usr_elena',
        name: 'Elena Rostova',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.customer,
      ),
      to: UserModel(
        id: 'usr_michael',
        name: 'Michael Carter',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.guard,
      ),
      rating: 5.0,
      serviceTag: 'Late-Night Transit',
      customFormattedTimeAgo: '1 week ago',
      reviewDescription: 'Felt completely safe during late-night transit. Michael was punctual, alert, and very professional throughout the escort.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      bookingId: 'Late-Night Transit',
    ),
    ReviewModel(
      id: 'rev_marcus',
      from: UserModel(
        id: 'usr_marcus',
        name: 'Marcus Sterling',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.customer,
      ),
      to: UserModel(
        id: 'usr_michael',
        name: 'Michael Carter',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.guard,
      ),
      rating: 4.8,
      serviceTag: 'VIP Private Event',
      customFormattedTimeAgo: '3 weeks ago',
      reviewDescription: 'Excellent crowd deterrence and calm composure during our private event. Highly recommended for close detail work.',
      createdAt: DateTime.now().subtract(const Duration(days: 21)),
      bookingId: 'VIP Private Event',
    ),
  ];

  /// Curated list of verified client reviews for bodyguards.
  static List<ReviewModel> get fakeReviews => [
    ReviewModel(
      id: 'rev_1',
      from: UserModel(
        id: 'usr_rahul',
        name: 'Rahul Sharma',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.customer,
      ),
      to: UserModel(
        id: 'usr_vikram',
        name: 'Vikram Singh',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.guard,
      ),
      rating: 5.0,
      reviewDescription: 'Exceptional professionalism during a high-stakes corporate summit in downtown. Vikram secured all entrances, navigated through heavy traffic seamlessly, and maintained sharp situational awareness throughout the entire 8-hour detail.',
      createdAt: DateTime(2026, 4, 20),
      bookingId: 'BK-2026-9041',
      customFormattedDate: '20 Apr 2026',
    ),
    ReviewModel(
      id: 'rev_2',
      from: UserModel(
        id: 'usr_sara',
        name: 'Sara Khan',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.customer,
      ),
      to: UserModel(
        id: 'usr_vikram',
        name: 'Vikram Singh',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.guard,
      ),
      rating: 5.0,
      reviewDescription: 'Impeccable tactical escort. Punctual, courteous, and discreet. The Cadillac B6 armored vehicle was in spotless condition, and I felt completely protected attending an international gala.',
      createdAt: DateTime(2026, 4, 15),
      bookingId: 'BK-2026-8812',
      customFormattedDate: '15 Apr 2026',
    ),
    ReviewModel(
      id: 'rev_3',
      from: UserModel(
        id: 'usr_alex',
        name: 'Alexander Vance',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.customer,
      ),
      to: UserModel(
        id: 'usr_david',
        name: 'David Sterling',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.guard,
      ),
      rating: 4.8,
      reviewDescription: 'Outstanding airport tarmac escort and executive route planning. David cleared Terminal 4 VIP corridors in advance and ensured our private transit was zero-delay.',
      createdAt: DateTime(2026, 4, 5),
      bookingId: 'BK-2026-7490',
      customFormattedDate: '05 Apr 2026',
    ),
    ReviewModel(
      id: 'rev_4',
      from: UserModel(
        id: 'usr_elena',
        name: 'Elena Rostova',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.customer,
      ),
      to: UserModel(
        id: 'usr_carlos',
        name: 'Carlos Sterling',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.guard,
      ),
      rating: 5.0,
      reviewDescription: 'Top-tier close protection specialist. Carlos demonstrated military-grade discipline and was always three steps ahead with venue emergency exits and perimeter safety.',
      createdAt: DateTime(2026, 3, 28),
      bookingId: 'BK-2026-6204',
      customFormattedDate: '28 Mar 2026',
    ),
  ];
}

