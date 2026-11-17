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
    // Falls back to SYSTEM if the database gains a type this build doesn't know yet.
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

  /// Factory providing realistic sample data for skeleton loading or previews.
  factory NotificationModel.fake({
    String id = 'fake-notification',
    String userId = 'fake-user-id',
    NotificationType type = NotificationType.newUserRegistration,
    String title = 'New registration: Rahul Sharma',
    String? titleHi,
    String body = 'Rahul Sharma (Bodyguard) has submitted their profile and is awaiting review.',
    String? bodyHi,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    bool isRead = false,
    String? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      titleHi: titleHi,
      body: body,
      bodyHi: bodyHi,
      data: data,
      imageUrl: imageUrl,
      isRead: isRead,
      readAt: readAt,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// List of realistic fake notifications for skeleton loaders or previews.
  static List<NotificationModel> fakeList({int count = 6}) {
    final sampleData =
        <
          ({
            NotificationType type,
            String title,
            String body,
            bool isRead,
            Duration ago,
          })
        >[
          (
            type: NotificationType.newUserRegistration,
            title: 'New registration: Rahul Sharma',
            body: 'Rahul Sharma (Bodyguard) has submitted their profile and is awaiting review.',
            isRead: false,
            ago: const Duration(minutes: 10),
          ),
          (
            type: NotificationType.newUserRegistration,
            title: 'New registration: Shield Security Pvt Ltd',
            body: 'Shield Security Pvt Ltd (Company) has submitted their profile and is awaiting review.',
            isRead: false,
            ago: const Duration(hours: 1),
          ),
          (
            type: NotificationType.accountApproved,
            title: 'Account approved',
            body: 'Your profile has been verified. Welcome to GuardUp!',
            isRead: true,
            ago: const Duration(hours: 3),
          ),
          (
            type: NotificationType.accountBlocked,
            title: 'Account suspended',
            body: 'Your GuardUp account has been suspended. Please contact support.',
            isRead: true,
            ago: const Duration(hours: 6),
          ),
          (
            type: NotificationType.system,
            title: 'System maintenance scheduled',
            body: 'Platform maintenance is scheduled tonight from 2:00 AM to 4:00 AM.',
            isRead: true,
            ago: const Duration(days: 1),
          ),
          (
            type: NotificationType.accountRejected,
            title: 'Application not approved',
            body: 'Your application could not be approved. Please contact support for details.',
            isRead: true,
            ago: const Duration(days: 2),
          ),
        ];

    final now = DateTime.now();
    return List.generate(count, (index) {
      final sample = sampleData[index % sampleData.length];
      return NotificationModel.fake(
        id: 'fake-notification-$index',
        type: sample.type,
        title: sample.title,
        body: sample.body,
        isRead: sample.isRead,
        createdAt: now.subtract(sample.ago),
        updatedAt: now.subtract(sample.ago),
      );
    });
  }
}
