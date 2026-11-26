import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/utils/json_converters/json_converters.dart';
import '/gen/assets.gen.dart';
import '../enum/discount_type.enum.dart';
import '../fixtures/payments.fixtures.dart';

part 'membership_plan.model.freezed.dart';
part 'membership_plan.model.g.dart';

DiscountType _discountTypeFromJson(dynamic value) {
  if (value == null) return DiscountType.percentage;
  return DiscountType.fromApi(value);
}

String _discountTypeToJson(DiscountType type) => type.apiValue;

@freezed
sealed class MembershipPlanModel with _$MembershipPlanModel {
  const MembershipPlanModel._();

  const factory MembershipPlanModel({
    required String id,
    required String name,
    @Default(<String>[]) List<String> description,
    @DoubleConverter()
    @JsonKey(name: 'price_per_month')
    required double pricePerMonth,
    @NullableDoubleConverter()
    @JsonKey(name: 'price_per_year')
    double? pricePerYear,
    @DoubleConverter() @Default(0.0) double discount,
    @JsonKey(
      name: 'discount_type',
      fromJson: _discountTypeFromJson,
      toJson: _discountTypeToJson,
    )
    @Default(DiscountType.percentage)
    DiscountType discountType,
    @NullableDoubleConverter()
    @JsonKey(name: 'discount_upto')
    double? discountUpto,
    @JsonKey(name: 'is_popular') @Default(false) bool isPopular,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'display_order') @Default(0) int displayOrder,
    String? badge,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _MembershipPlanModel;

  factory MembershipPlanModel.fromJson(Map<String, dynamic> json) =>
      _$MembershipPlanModelFromJson(_sanitizeJson(json));

  static Map<String, dynamic> _sanitizeJson(Map<String, dynamic> json) {
    final rawDescription = json['description'];
    List<dynamic> descList = const [];
    if (rawDescription is List) {
      descList = rawDescription;
    } else if (rawDescription is String && rawDescription.isNotEmpty) {
      descList = [rawDescription];
    }

    final isPop = (json['is_popular'] as bool?) ?? false;

    return {
      ...json,
      'name': (json['name'] ?? json['title'] ?? '').toString(),
      'description': descList,
      'price_per_month':
          double.tryParse(
            (json['price_per_month'] ?? json['monthlyPrice'] ?? '0').toString(),
          ) ??
          0.0,
      'price_per_year': json['price_per_year'] != null
          ? double.tryParse(json['price_per_year'].toString())
          : null,
      'discount':
          double.tryParse(
            (json['discount'] ?? json['discountPercentage'] ?? '0').toString(),
          ) ??
          0.0,
      'discount_upto': json['discount_upto'] != null
          ? double.tryParse(json['discount_upto'].toString())
          : null,
      'badge': json['badge'] ?? (isPop ? '★ MOST POPULAR' : null),
    };
  }

  // Compatibility getters for PlanModel
  String get title => name;
  double get monthlyPrice => pricePerMonth;
  int get discountPercentage => discount.round();
  List<String> get features => description;
  SvgGenImage get featureIcon =>
      isPopular ? Assets.svg.starChecked : Assets.svg.checked;

  bool get hasDiscount => discount > 0;
  bool get hasYearlyPrice => pricePerYear != null;

  double calculateSavings(double bookingAmount) {
    if (discountType.isPercentage) {
      final calculated = (bookingAmount * discount) / 100.0;
      if (discountUpto != null && discountUpto! > 0) {
        return math.min(calculated, discountUpto!);
      }
      return calculated;
    }
    return discount;
  }

  double calculatePayable(double bookingAmount) {
    return math.max(0.0, bookingAmount - calculateSavings(bookingAmount));
  }

  @Deprecated(
    'Use membershipPlanPlaceholders from data/fixtures/payments.fixtures.dart',
  )
  static List<MembershipPlanModel> get fakeData => membershipPlanPlaceholders;
}
