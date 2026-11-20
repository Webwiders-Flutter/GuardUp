import 'dart:math' as math;
import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/assets.gen.dart';

part 'plan.model.freezed.dart';
part 'plan.model.g.dart';

/// Represents a membership tier available in GuardUp.
///
/// Matches the `membership_plans` table in Supabase.
@freezed
abstract class PlanModel with _$PlanModel {
  const PlanModel._();

  const factory PlanModel({
    required String id,
    required String name,
    @Default([]) List<String> description,
    @JsonKey(name: 'price_per_month') required double pricePerMonth,
    @JsonKey(name: 'price_per_year') double? pricePerYear,
    @Default(0.0) double discount,
    @JsonKey(name: 'discount_type') @Default('PERCENTAGE') String discountType,
    @JsonKey(name: 'discount_upto') double? discountUpto,
    @JsonKey(name: 'is_popular') @Default(false) bool isPopular,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'display_order') @Default(0) int displayOrder,
    String? badge,
  }) = _PlanModel;

  /// Backwards-compatibility getter for [name].
  String get title => name;

  /// Backwards-compatibility getter for [pricePerMonth].
  double get monthlyPrice => pricePerMonth;

  /// Backwards-compatibility getter for [discount] as integer percentage.
  int get discountPercentage => discount.round();

  /// Backwards-compatibility getter for [description].
  List<String> get features => description;

  /// Feature icon reflecting plan status.
  SvgGenImage get featureIcon =>
      isPopular ? Assets.svg.starChecked : Assets.svg.checked;

  /// Calculates the savings amount for a given base booking amount.
  double calculateSavings(double bookingAmount) {
    if (discountType.toUpperCase() == 'PERCENTAGE') {
      final calculated = (bookingAmount * discount) / 100.0;
      if (discountUpto != null && discountUpto! > 0) {
        return math.min(calculated, discountUpto!);
      }
      return calculated;
    }
    return discount;
  }

  /// Calculates the final payable amount after applying plan discount.
  double calculatePayable(double bookingAmount) {
    return math.max(0.0, bookingAmount - calculateSavings(bookingAmount));
  }

  factory PlanModel.fromJson(Map<String, dynamic> json) =>
      _$PlanModelFromJson(_sanitizeJson(json));

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
      'price_per_month': double.tryParse(
            (json['price_per_month'] ?? json['monthlyPrice'] ?? '0').toString(),
          ) ??
          0.0,
      'price_per_year': json['price_per_year'] != null
          ? double.tryParse(json['price_per_year'].toString())
          : null,
      'discount': double.tryParse(
            (json['discount'] ?? json['discountPercentage'] ?? '0').toString(),
          ) ??
          0.0,
      'discount_upto': json['discount_upto'] != null
          ? double.tryParse(json['discount_upto'].toString())
          : null,
      'badge': json['badge'] ?? (isPop ? '★ MOST POPULAR' : null),
    };
  }

  /// Production default plans matching the exact GuardUp database records.
  static List<PlanModel> get fakeData => [
    const PlanModel(
      id: '59caafd7-f530-4bf2-b53d-929601f37962',
      name: 'Silver Shield',
      description: [
        '10% off every booking, up to ₹500 per booking',
        'Access to all verified bodyguards',
        'Standard customer support',
      ],
      pricePerMonth: 499.00,
      discount: 10.00,
      discountType: 'PERCENTAGE',
      discountUpto: 500.00,
      isPopular: false,
      displayOrder: 1000,
    ),
    const PlanModel(
      id: '8e85404f-763e-458b-ab18-03502ec85d60',
      name: 'Gold Sentinel',
      description: [
        '20% off every booking, up to ₹1,500 per booking',
        'Access to all verified bodyguards and security companies',
        'Priority customer support',
        'Priority matching for urgent bookings',
      ],
      pricePerMonth: 999.00,
      discount: 20.00,
      discountType: 'PERCENTAGE',
      discountUpto: 1500.00,
      isPopular: true,
      badge: '★ MOST POPULAR',
      displayOrder: 2000,
    ),
    const PlanModel(
      id: '2dcb905e-0882-4f2c-9051-c8a483532147',
      name: 'Platinum Elite',
      description: [
        '30% off every booking, no upper limit',
        'Access to all verified bodyguards and security companies',
        'Dedicated 24/7 support line',
        'Priority matching for urgent bookings',
        'Free cancellation up to 2 hours before a booking',
      ],
      pricePerMonth: 1999.00,
      discount: 30.00,
      discountType: 'PERCENTAGE',
      isPopular: false,
      displayOrder: 3000,
    ),
  ];
}
