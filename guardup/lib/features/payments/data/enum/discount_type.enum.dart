import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/utils/json_converters/enum.jsonconverter.dart';

enum DiscountType {
  @JsonValue('PERCENTAGE')
  percentage('PERCENTAGE'),

  @JsonValue('FLAT')
  flat('FLAT');

  final String apiValue;

  const DiscountType(this.apiValue);

  bool get isPercentage => this == DiscountType.percentage;

  static DiscountType fromApi(dynamic value) =>
      DiscountType.values.parse(value, defaultValue: DiscountType.percentage);
}
