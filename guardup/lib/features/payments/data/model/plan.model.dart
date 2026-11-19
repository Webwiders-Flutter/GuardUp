import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '/gen/assets.gen.dart';

/// Represents a membership tier available in GuardUp.
///
/// Matches the `membership_plans` table in Supabase.
@immutable
class PlanModel {
  final String id;
  final String name;
  final List<String> description;
  final double pricePerMonth;
  final double? pricePerYear;
  final double discount;
  final String discountType;
  final double? discountUpto;
  final bool isPopular;
  final bool isActive;
  final int displayOrder;
  final String? badge;
  final SvgGenImage? featureIcon;

  const PlanModel({
    required this.id,
    required this.name,
    this.description = const [],
    required this.pricePerMonth,
    this.pricePerYear,
    this.discount = 0.0,
    this.discountType = 'PERCENTAGE',
    this.discountUpto,
    this.isPopular = false,
    this.isActive = true,
    this.displayOrder = 0,
    this.badge,
    this.featureIcon,
  });

  /// Backwards-compatibility getter for [name].
  String get title => name;

  /// Backwards-compatibility getter for [pricePerMonth].
  double get monthlyPrice => pricePerMonth;

  /// Backwards-compatibility getter for [discount] as integer percentage.
  int get discountPercentage => discount.round();

  /// Backwards-compatibility getter for [description].
  List<String> get features => description;

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

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final rawDescription = json['description'];
    List<String> descList = const [];
    if (rawDescription is List) {
      descList = rawDescription.map((e) => e.toString()).toList();
    } else if (rawDescription is String && rawDescription.isNotEmpty) {
      descList = [rawDescription];
    }

    final isPop = (json['is_popular'] as bool?) ?? false;
    final nameVal = (json['name'] ?? json['title'] ?? '').toString();

    return PlanModel(
      id: (json['id'] ?? '').toString(),
      name: nameVal,
      description: descList,
      pricePerMonth: double.tryParse(
            (json['price_per_month'] ?? json['monthlyPrice'] ?? '0').toString(),
          ) ??
          0.0,
      pricePerYear: json['price_per_year'] != null
          ? double.tryParse(json['price_per_year'].toString())
          : null,
      discount: double.tryParse(
            (json['discount'] ?? json['discountPercentage'] ?? '0').toString(),
          ) ??
          0.0,
      discountType: (json['discount_type'] ?? 'PERCENTAGE').toString(),
      discountUpto: json['discount_upto'] != null
          ? double.tryParse(json['discount_upto'].toString())
          : null,
      isPopular: isPop,
      isActive: (json['is_active'] ?? json['isActive'] ?? true) as bool,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      badge: isPop
          ? '★ MOST POPULAR'
          : (json['badge'] as String?),
      featureIcon: isPop ? Assets.svg.starChecked : Assets.svg.checked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price_per_month': pricePerMonth,
      'price_per_year': pricePerYear,
      'discount': discount,
      'discount_type': discountType,
      'discount_upto': discountUpto,
      'is_popular': isPopular,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }

  PlanModel copyWith({
    String? id,
    String? name,
    List<String>? description,
    double? pricePerMonth,
    double? pricePerYear,
    double? discount,
    String? discountType,
    double? discountUpto,
    bool? isPopular,
    bool? isActive,
    int? displayOrder,
    String? badge,
    SvgGenImage? featureIcon,
  }) {
    return PlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      pricePerYear: pricePerYear ?? this.pricePerYear,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      discountUpto: discountUpto ?? this.discountUpto,
      isPopular: isPopular ?? this.isPopular,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      badge: badge ?? this.badge,
      featureIcon: featureIcon ?? this.featureIcon,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          pricePerMonth == other.pricePerMonth &&
          discount == other.discount &&
          isPopular == other.isPopular &&
          isActive == other.isActive &&
          listEquals(description, other.description);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      pricePerMonth.hashCode ^
      discount.hashCode ^
      isPopular.hashCode ^
      isActive.hashCode ^
      description.hashCode;

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
