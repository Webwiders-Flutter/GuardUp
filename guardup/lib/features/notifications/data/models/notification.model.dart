import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/notification_type.enum.dart';
import '../fixtures/notifications.fixtures.dart';

part 'notification.model.freezed.dart';
part 'notification.model.g.dart';

@freezed
sealed class NotificationModel with _$NotificationModel {
  const NotificationModel._();

  const factory NotificationModel({
    required String id,
    required String userId,
    @JsonKey(unknownEnumValue: NotificationType.system)
    required NotificationType type,
    required String title,
    String? titleHi,
    required String body,
    String? bodyHi,
    @Default({}) Map<String, dynamic> data,
    String? imageUrl,
    @Default(false) bool isRead,
    String? readAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  /// Helper to return localized title based on current language
  String displayTitle(bool isHindi) {
    if (isHindi && titleHi != null && titleHi!.trim().isNotEmpty) {
      return titleHi!;
    }
    return title;
  }

  /// Helper to return localized body based on current language
  String displayBody(bool isHindi) {
    if (isHindi && bodyHi != null && bodyHi!.trim().isNotEmpty) {
      return bodyHi!;
    }
    return body;
  }

  /// List of realistic fake notifications for skeleton loaders or previews.
  @Deprecated('Use notificationPlaceholders from data/fixtures/notifications.fixtures.dart')
  static List<NotificationModel> get fakeData => notificationPlaceholders;
}
