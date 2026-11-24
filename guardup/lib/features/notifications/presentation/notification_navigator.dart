import 'dart:async';

import '/app/routes/app_router.dart';
import '/core/constants/api/json_keys.dart';
import '/core/di/injection_container.dart';
import '/core/logger/app_logger.dart';
import '/features/auth/presentation/screens/splash_screen.dart';
import '/features/body_guard/presentation/screens/company_bodyguards_screen.dart';
import '/features/body_guard/presentation/screens/guard_detail.screen.dart';
import '/features/notifications/bloc/unread_count/unread_notification_count_cubit.dart';
import '/features/notifications/data/enums/notification_type.enum.dart';
import '/features/notifications/data/repositories/notification_repository.dart';
import '/features/notifications/presentation/screens/notifications_screen.dart';

/// Opens what a notification is about. Used by the notifications list, the
/// foreground banner and push taps (background / terminated), so every entry
/// point behaves the same. See documentation/notifications_and_user_lifecycle.md,
/// "Opening a notification".
///
/// | Notification                                   | Opens                                   |
/// |------------------------------------------------|-----------------------------------------|
/// | `data.route`                                   | that route                              |
/// | company bodyguard event (`data.bodyguard_id`)  | the bodyguard's details                 |
/// | company bodyguard removed (`BODYGUARD_DELETED`)| the company's bodyguards list           |
/// | own account: approved / rejected / blocked /   | the screen for the account's current    |
/// | unblocked / deleted                            | status (router redirect)                |
/// | NEW_USER_REGISTRATION, SYSTEM                  | nothing (push: the notifications list)  |
abstract final class NotificationNavigator {
  /// `data.event` of a company bodyguard removed by an admin.
  static const String _bodyguardDeletedEvent = 'BODYGUARD_DELETED';

  /// Opens the target of a notification from the in-app list. Returns false
  /// when there is nothing to open (the user stays on the list).
  static bool open(NotificationType type, Map<String, dynamic> data) {
    final target = _targetOf(type, data);
    if (target == null) return false;

    final router = AppRouter.router;
    if (target.replace) {
      router.go(target.location);
    } else {
      router.push(target.location, extra: target.extra);
    }
    return true;
  }

  /// Opens a tapped push / foreground banner ([data] is the FCM payload:
  /// `type`, `notification_id` and the notification's data). Marks the
  /// notification read, then opens its target or the notifications list.
  static void openPush(Map<String, dynamic> data) {
    final notificationId = _string(data, JsonKeys.notificationId);
    if (notificationId != null) unawaited(_markRead(notificationId));

    final type =
        NotificationType.tryFromApiValue(_string(data, JsonKeys.type)) ??
        NotificationType.system;
    if (!open(type, data)) {
      AppRouter.router.push(NotificationsScreen.route);
    }
  }

  static ({String location, Object? extra, bool replace})? _targetOf(
    NotificationType type,
    Map<String, dynamic> data,
  ) {
    final route = _string(data, JsonKeys.route);
    if (route != null) return (location: route, extra: null, replace: false);

    // Company-managed bodyguard events (sent to the company with the
    // ACCOUNT_* types): about the bodyguard, not the company's own account.
    final bodyguardId = _string(data, JsonKeys.bodyguardId);
    if (bodyguardId != null) {
      return _string(data, JsonKeys.event) == _bodyguardDeletedEvent
          ? (
              location: CompanyBodyguardsScreen.route,
              extra: null,
              replace: false,
            )
          : (
              location: GuardDetailScreen.route,
              extra: bodyguardId,
              replace: false,
            );
    }

    switch (type) {
      // The user's own account changed: the router redirect from the splash
      // route lands on the screen for the account's current status (home,
      // approval / rejection, blocked, login after a deletion).
      case NotificationType.accountApproved:
      case NotificationType.accountRejected:
      case NotificationType.accountBlocked:
      case NotificationType.accountUnblocked:
      case NotificationType.accountDeleted:
        return (location: SplashScreen.route, extra: null, replace: true);

      // Admin-only, or informational.
      case NotificationType.newUserRegistration:
      case NotificationType.system:
        return null;
    }
  }

  static Future<void> _markRead(String notificationId) async {
    try {
      await sl<NotificationRepository>().markAsRead(
        notificationId: notificationId,
      );
      await sl<UnreadNotificationCountCubit>().refreshCount();
    } catch (e) {
      AppLogger.w(
        'Failed to mark notification $notificationId as read: $e',
        tag: 'NotificationNavigator',
      );
    }
  }

  static String? _string(Map<String, dynamic> data, String key) {
    final value = data[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }
}
