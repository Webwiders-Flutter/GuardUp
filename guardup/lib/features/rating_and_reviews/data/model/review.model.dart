import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../gen/assets.gen.dart';
import '/features/auth/auth.dart';

part 'review.model.freezed.dart';
part 'review.model.g.dart';

/// Represents a client feedback or operative rating record.
@freezed
abstract class ReviewModel with _$ReviewModel {
  const factory ReviewModel({
    required String id,
    required UserModel from,
    required UserModel to,
    required double rating,
    required String reviewDescription,
    required DateTime createdAt,
    String? bookingId,
    String? customFormattedDate,
    String? serviceTag,
    String? customFormattedTimeAgo,
  }) = _ReviewModel;

  factory ReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewModelFromJson(json);

  /// Curated list of verified client reviews matching the GuardUp design.
  static List<ReviewModel> get fakeData => [
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
  ];
}
