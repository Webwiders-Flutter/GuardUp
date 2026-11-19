import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/notification_type.enum.dart';

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
  static List<NotificationModel> get fakeData {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    return [
      NotificationModel(
        id: 'notif_1',
        userId: 'fake-user-id',
        type: NotificationType.accountApproved,
        title: 'Account Approved',
        body: 'Your profile has been approved by admin. You can now access all services.',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
        data: const {'timeAgo': '5 min ago'},
      ),
      NotificationModel(
        id: 'notif_2',
        userId: 'fake-user-id',
        type: NotificationType.newUserRegistration,
        title: 'Profile Under Review',
        body: 'Your documents have been submitted and are currently awaiting review.',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 25)),
        updatedAt: now.subtract(const Duration(minutes: 25)),
        data: const {'timeAgo': '25 min ago'},
      ),
      NotificationModel(
        id: 'notif_3',
        userId: 'fake-user-id',
        type: NotificationType.system,
        title: 'System Security Notice',
        body: 'GuardUp security protocols and identity verification guidelines have been updated.',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        data: const {'timeAgo': '1 hr ago'},
      ),
      NotificationModel(
        id: 'notif_4',
        userId: 'fake-user-id',
        type: NotificationType.accountUnblocked,
        title: 'Account Restored',
        body: 'Your account access has been fully restored. Welcome back.',
        isRead: true,
        createdAt: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          18,
          45,
        ),
        updatedAt: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          18,
          45,
        ),
        data: const {'timeAgo': 'Yesterday, 6:45 PM'},
      ),
    ];
  }
}
