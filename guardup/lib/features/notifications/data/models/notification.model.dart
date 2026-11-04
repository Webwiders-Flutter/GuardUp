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

  /// Display formatted relative time (e.g. '5 min ago', 'Yesterday, 6:45 PM')
  String get timeAgoFormatted {
    if (data.containsKey('timeAgo')) {
      return data['timeAgo'] as String;
    }
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day) {
      if (difference.inMinutes < 60) {
        final mins = difference.inMinutes.clamp(1, 59);
        return '$mins min ago';
      }
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? "hr" : "hrs"} ago';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (createdAt.year == yesterday.year &&
        createdAt.month == yesterday.month &&
        createdAt.day == yesterday.day) {
      final hour = createdAt.hour > 12
          ? createdAt.hour - 12
          : (createdAt.hour == 0 ? 12 : createdAt.hour);
      final minute = createdAt.minute.toString().padLeft(2, '0');
      final period = createdAt.hour >= 12 ? 'PM' : 'AM';
      return 'Yesterday, $hour:$minute $period';
    }

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Whether this notification was created today.
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  /// Factory providing realistic sample data for skeleton loading or previews.
  factory NotificationModel.fake({
    String id = 'fake-notification',
    String userId = 'fake-user-id',
    NotificationType type = NotificationType.bookingRequest,
    String title = 'New Booking Request',
    String? titleHi,
    String body = 'Rahul Sharma has requested a booking for Apr 28, 2025 at 10:00 AM (3 hours).',
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

  /// List of realistic fake notifications matching the GuardUp design mockup.
  static List<NotificationModel> get fakeData {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    return [
      NotificationModel.fake(
        id: 'notif_1',
        type: NotificationType.bookingRequest,
        title: 'New Booking Request',
        body: 'Rahul Sharma has requested a booking for Apr 28, 2025 at 10:00 AM (3 hours).',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 5)),
        data: const {'timeAgo': '5 min ago'},
      ),
      NotificationModel.fake(
        id: 'notif_2',
        type: NotificationType.customerMessage,
        title: 'New Customer Message',
        body: 'You have received a new message from Sara Khan.',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 25)),
        data: const {'timeAgo': '25 min ago'},
      ),
      NotificationModel.fake(
        id: 'notif_3',
        type: NotificationType.payoutProcessed,
        title: 'Payout Processed',
        body: 'Your payout of \$250 has been processed successfully to your bank account.',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 1)),
        data: const {'timeAgo': '1 hr ago'},
      ),
      NotificationModel.fake(
        id: 'notif_4',
        type: NotificationType.documentVerified,
        title: 'Document Verified',
        body: 'Your security license has been approved and verified.',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 2)),
        data: const {'timeAgo': '2 hrs ago'},
      ),
      NotificationModel.fake(
        id: 'notif_5',
        type: NotificationType.profileUpdate,
        title: 'Profile Update',
        body: 'Your profile has been updated succesfully.',
        isRead: true,
        createdAt: DateTime(yesterday.year, yesterday.month, yesterday.day, 18, 45),
        data: const {'timeAgo': 'Yesterday, 6:45 PM'},
      ),
      NotificationModel.fake(
        id: 'notif_6',
        type: NotificationType.bookingReminder,
        title: 'Booking Reminder',
        body: 'You have a confirmed booking tomorrow at 11:00 AM.',
        isRead: true,
        createdAt: DateTime(yesterday.year, yesterday.month, yesterday.day, 14, 30),
        data: const {'timeAgo': 'Yesterday, 2:30 PM'},
      ),
    ];
  }

  /// List of realistic fake notifications for skeleton loaders or previews.
  static List<NotificationModel> fakeList({int count = 6}) {
    final list = fakeData;
    return List.generate(count, (index) => list[index % list.length]);
  }
}
