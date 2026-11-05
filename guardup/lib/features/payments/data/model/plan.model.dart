import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/assets.gen.dart';

part 'plan.model.freezed.dart';

/// Represents a membership tier available in GuardUp.
@freezed
abstract class PlanModel with _$PlanModel {
  const PlanModel._();

  const factory PlanModel({
    required String id,
    required String title,
    required double monthlyPrice,
    required int discountPercentage,
    String? badge,
    @Default(false) bool isActive,
    SvgGenImage? featureIcon,
    @Default([]) List<String> features,
  }) = _PlanModel;

  /// Calculates the savings amount for a given base booking amount.
  double calculateSavings(double bookingAmount) {
    return (bookingAmount * discountPercentage) / 100.0;
  }

  /// Calculates the final payable amount after applying plan discount.
  double calculatePayable(double bookingAmount) {
    return bookingAmount - calculateSavings(bookingAmount);
  }

  /// Default production plans matching the exact GuardUp membership tiers and screenshots.
  static List<PlanModel> get fakeData => [
    PlanModel(
      id: 'silver_shield',
      title: 'Silver Shield',
      monthlyPrice: 9.99,
      discountPercentage: 10,
      featureIcon: Assets.svg.checked,
      features: const [
        '10% standard discount on all escort hours',
        'Direct encrypted comms with operative',
      ],
    ),
    PlanModel(
      id: 'gold_sentinel',
      title: 'Gold Sentinel',
      monthlyPrice: 14.99,
      discountPercentage: 20,
      badge: '★ MOST POPULAR',
      featureIcon: Assets.svg.starChecked,
      features: const [
        'Priority rapid-escort dispatch under 10 mins',
        'Exclusive tier-1 vetted operative pool',
        'Zero cancellation charges on immediate dispatches',
      ],
    ),
    PlanModel(
      id: 'black_diamond',
      title: 'Black Diamond',
      monthlyPrice: 19.99,
      discountPercentage: 30,
      featureIcon: Assets.svg.checked,
      features: const [
        'Dedicated armed escort & close-quarter details',
        '24/7 Security Operations Center direct command line',
        'Paramount priority over all standard bookings',
      ],
    ),
  ];
}
