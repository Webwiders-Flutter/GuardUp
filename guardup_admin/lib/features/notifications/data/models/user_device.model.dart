import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_device.model.freezed.dart';
part 'user_device.model.g.dart';

@freezed
sealed class UserDeviceModel with _$UserDeviceModel {
  const factory UserDeviceModel({
    String? id,
    required String userId,
    required String token,
    @Default('unknown') String platform,
    @Default('en') String languageCode,
    @Default(true) bool isActive,
    String? createdAt,
    String? lastActiveAt,
  }) = _UserDeviceModel;

  factory UserDeviceModel.fromJson(Map<String, dynamic> json) =>
      _$UserDeviceModelFromJson(json);
}
