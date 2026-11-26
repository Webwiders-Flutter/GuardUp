import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/auth/auth.dart';
import '../fixtures/rating_and_reviews.fixtures.dart';

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
  @Deprecated('Use reviewFixtures from data/fixtures/rating_and_reviews.fixtures.dart')
  static List<ReviewModel> get fakeData => reviewFixtures;
}
