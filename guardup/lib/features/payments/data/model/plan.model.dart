import '/gen/assets.gen.dart';

/// Represents a membership tier available in GuardUp.
class PlanModel {
  final String id;
  final String title;
  final double monthlyPrice;
  final int discountPercentage;
  final String? badge;
  final bool isActive;
  final SvgGenImage? featureIcon;
  final List<String> features;

  const PlanModel({
    required this.id,
    required this.title,
    required this.monthlyPrice,
    required this.discountPercentage,
    this.badge,
    this.isActive = false,
    this.featureIcon,
    required this.features,
  });

  /// Calculates the savings amount for a given base booking amount.
  double calculateSavings(double bookingAmount) {
    return (bookingAmount * discountPercentage) / 100.0;
  }

  /// Calculates the final payable amount after applying plan discount.
  double calculatePayable(double bookingAmount) {
    return bookingAmount - calculateSavings(bookingAmount);
  }

  /// Default production plans matching the exact GuardUp membership tiers and screenshots.
  static List<PlanModel> get fakePlans => [
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
