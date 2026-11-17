import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/constants/api/json_keys.dart';

part 'user_device.model.freezed.dart';
part 'user_device.model.g.dart';

@freezed
sealed class UserDeviceModel with _$UserDeviceModel {
  const factory UserDeviceModel({
    String? id,
    @JsonKey(name: JsonKeys.userId) required String userId,
    required String token,
    @Default('unknown') String platform,
    @Default('en') @JsonKey(name: JsonKeys.languageCode) String languageCode,
    @Default(true) @JsonKey(name: JsonKeys.isActive) bool isActive,
    @JsonKey(name: JsonKeys.createdAt) String? createdAt,
    @JsonKey(name: JsonKeys.lastActiveAt) String? lastActiveAt,
  }) = _UserDeviceModel;

  factory UserDeviceModel.fromJson(Map<String, dynamic> json) =>
      _$UserDeviceModelFromJson(json);
}
