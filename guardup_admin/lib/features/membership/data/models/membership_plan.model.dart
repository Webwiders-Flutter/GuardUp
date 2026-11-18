import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/number.extension.dart';
import '/core/utils/json_converters/json_converters.dart';
import '../enums/discount_type.enum.dart';

export '../enums/discount_type.enum.dart';
export 'membership_plan_filters.model.dart';
export 'membership_plan_request.model.dart';

part 'membership_plan.model.freezed.dart';
part 'membership_plan.model.g.dart';

/// A customer membership tier, backed by `public.membership_plans`.
@freezed
sealed class MembershipPlan with _$MembershipPlan {
  const MembershipPlan._();

  const factory MembershipPlan({
    required String id,
    required String name,

    /// Benefits, one line each.
    @Default(<String>[]) List<String> description,
    @DoubleConverter() required double pricePerMonth,
    @NullableDoubleConverter() double? pricePerYear,
    @DoubleConverter() @Default(0) double discount,
    @Default(DiscountType.percentage)
    @JsonKey(unknownEnumValue: DiscountType.percentage)
    DiscountType discountType,

    /// Max discount amount per booking (percentage discounts only).
    @NullableDoubleConverter() double? discountUpto,
    @Default(false) bool isPopular,
    @Default(true) bool isActive,
    @Default(0) int displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MembershipPlan;

  factory MembershipPlan.fromJson(Map<String, dynamic> json) =>
      _$MembershipPlanFromJson(json);

  bool get hasDiscount => discount > 0;

  bool get hasYearlyPrice => pricePerYear != null;

  /// e.g. `20% off (up to $500)`, `$200 off`, or `No discount`.
  String get discountLabel {
    if (!hasDiscount) return 'No discount';
    if (discountType.isPercentage) {
      final percent = discount % 1 == 0
          ? discount.toStringAsFixed(0)
          : discount.toString();
      final cap = discountUpto != null
          ? ' (up to ${discountUpto!.toUsdAmount})'
          : '';
      return '$percent% off$cap';
    }
    return '${discount.toUsdAmount} off';
  }

  /// What 12 months cost when paid monthly.
  double get yearlyPriceAtMonthlyRate => pricePerMonth * 12;

  /// Amount saved by paying yearly instead of monthly; `null` if no saving.
  double? get yearlySavings {
    final yearly = pricePerYear;
    if (yearly == null) return null;
    final savings = yearlyPriceAtMonthlyRate - yearly;
    return savings > 0 ? savings : null;
  }

  /// Yearly saving as a whole-number percentage of the monthly-rate total.
  int? get yearlySavingsPercent {
    final savings = yearlySavings;
    if (savings == null || yearlyPriceAtMonthlyRate <= 0) return null;
    return (savings / yearlyPriceAtMonthlyRate * 100).round();
  }
}
