import 'package:freezed_annotation/freezed_annotation.dart';

import '../enum/user_role.enum.dart';

part 'user.model.freezed.dart';
part 'user.model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    @JsonKey(includeToJson: false) required String id,
    required String name,
    String? profileImageUrl,
    UserRole? role,
  }) = _UserModel;

  /// Creates a [UserModel] for request payloads (omitting the server-generated [id]).
  factory UserModel.fromRequest({
    required String name,
    String? profileImageUrl,
    UserRole? role,
  }) =>
      UserModel(
        id: '',
        name: name,
        profileImageUrl: profileImageUrl,
        role: role,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
