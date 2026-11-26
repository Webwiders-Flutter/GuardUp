import '/features/notifications/data/enums/notification_type.enum.dart';
import '../models/notification.model.dart';

/// Placeholders for Skeletonizer shimmering on the notifications screen.
final List<NotificationModel> notificationPlaceholders = [
  NotificationModel(
    id: 'notif_1',
    userId: 'placeholder',
    type: NotificationType.accountApproved,
    title: 'Account Approved',
    body:
        'Your profile has been approved by admin. You can now access all services.',
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    data: const {'timeAgo': '5 min ago'},
  ),
  NotificationModel(
    id: 'notif_2',
    userId: 'placeholder',
    type: NotificationType.newUserRegistration,
    title: 'Profile Under Review',
    body:
        'Your documents have been submitted and are currently awaiting review.',
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    updatedAt: DateTime.now().subtract(const Duration(minutes: 25)),
    data: const {'timeAgo': '25 min ago'},
  ),
  NotificationModel(
    id: 'notif_3',
    userId: 'placeholder',
    type: NotificationType.system,
    title: 'System Security Notice',
    body:
        'GuardUp security protocols and identity verification guidelines have been updated.',
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    data: const {'timeAgo': '1 hr ago'},
  ),
  NotificationModel(
    id: 'notif_4',
    userId: 'placeholder',
    type: NotificationType.accountUnblocked,
    title: 'Account Restored',
    body: 'Your account access has been fully restored. Welcome back.',
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    data: const {'timeAgo': 'Yesterday, 6:45 PM'},
  ),
];
