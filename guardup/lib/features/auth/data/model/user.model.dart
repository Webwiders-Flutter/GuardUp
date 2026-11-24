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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  /// Creates a [UserModel] for request payloads (omitting the server-generated [id]).
  factory UserModel.fromRequest({
    required String name,
    String? profileImageUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserModel(
    id: '',
    name: name,
    profileImageUrl: profileImageUrl,
    role: role,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  static List<UserModel> get fakeData => const [
    UserModel(
      id: 'usr_vikram',
      name: 'Vikram Singh',
      role: UserRole.guard,
      
    ),
    UserModel(
      id: 'usr_marcus',
      name: 'Marcus Sterling',
      role: UserRole.guard,
    ),
    UserModel(
      id: 'usr_customer_1',
      name: 'Sara Khan',
      role: UserRole.customer,
    ),
  ];
}
