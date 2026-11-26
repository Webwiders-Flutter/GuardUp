import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/utils/json_converters/json_converters.dart';

export '/core/extensions/service.extension.dart';

part 'service.model.freezed.dart';
part 'service.model.g.dart';

/// A row of `public.services` (managed by admins).
///
/// The `code` column was dropped (migration 20261117000002); match services by
/// [id], or by [iconName] / [name] for display (see `ServiceModelX.icon`).
@freezed
abstract class ServiceModel with _$ServiceModel {
  const factory ServiceModel({
    required String id,
    @Default('') String name,
    String? description,
    String? iconName,
    String? iconUrl,
    @Default(true) bool isActive,
    @NullableIntConverter() int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ServiceModel;

  factory ServiceModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceModelFromJson(json);
}

/// Parses embedded `user_services(id, service:services(...))` rows into the
/// services they link to. Rows without an embedded `service` are skipped.
List<ServiceModel>? servicesFromUserServices(dynamic json) {
  final rows = EmbeddedParser.parseList(json, (row) => row);
  if (rows == null) return null;
  return [
    for (final row in rows)
      ?EmbeddedParser.parseObject(row['service'], ServiceModel.fromJson),
  ];
}
