import '/core/constants/api/json_keys.dart';
import '../enums/discount_type.enum.dart';

/// Payload for creating or updating a [MembershipPlan].
class MembershipPlanRequest {
  final String name;
  final List<String> description;
  final double pricePerMonth;
  final double? pricePerYear;
  final double discount;
  final DiscountType discountType;
  final double? discountUpto;
  final bool isPopular;
  final bool isActive;

  const MembershipPlanRequest({
    required this.name,
    required this.pricePerMonth,
    this.description = const [],
    this.pricePerYear,
    this.discount = 0,
    this.discountType = DiscountType.percentage,
    this.discountUpto,
    this.isPopular = false,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    final benefits = description
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return <String, dynamic>{
      JsonKeys.name: name.trim(),
      JsonKeys.description: benefits,
      JsonKeys.pricePerMonth: pricePerMonth,
      JsonKeys.pricePerYear: pricePerYear,
      JsonKeys.discount: discount,
      JsonKeys.discountType: discountType.apiValue,
      // A cap only makes sense for percentage discounts (enforced by a DB check).
      JsonKeys.discountUpto:
          discountType.isPercentage && discount > 0 ? discountUpto : null,
      JsonKeys.isPopular: isPopular,
      JsonKeys.isActive: isActive,
    };
  }
}
