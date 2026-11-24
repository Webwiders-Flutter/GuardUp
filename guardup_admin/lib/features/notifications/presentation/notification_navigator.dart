import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/core/constants/api/json_keys.dart';
import '/features/company_bodyguards/presentation/widgets/company_bodyguard_review.panel.dart';
import '/features/users/presentation/screens/user_details.screen.dart';

/// Opens what a notification is about, from its `data` (the same keys travel
/// in the push payload). Works the same for every notification type: admins
/// receive NEW_USER_REGISTRATION (accounts and company bodyguards), and any
/// other type carrying these keys opens the same way. See
/// documentation/notifications_and_user_lifecycle.md, "Opening a notification".
///
/// | data                                   | opens                                |
/// |----------------------------------------|--------------------------------------|
/// | `route`                                | that admin route                     |
/// | `bodyguard_id` (not a deleted one)     | the company bodyguard review panel   |
/// | `user_id`                              | the user's details side panel        |
/// | nothing of the above (e.g. SYSTEM)     | nothing ([canOpen] is false)         |
abstract final class NotificationNavigator {
  /// `data.event` of a company bodyguard removed by an admin.
  static const String _bodyguardDeletedEvent = 'BODYGUARD_DELETED';

  /// Whether tapping a notification with [data] opens anything.
  static bool canOpen(Map<String, dynamic> data) => _targetOf(data) != null;

  /// Opens the target of a notification. [context] must be below a
  /// Navigator (a page, or [AppRouter.rootNavigatorKey]'s context).
  /// Returns false when the notification has nothing to open.
  static bool open(BuildContext context, Map<String, dynamic> data) {
    final target = _targetOf(data);
    if (target == null) return false;

    switch (target) {
      case _RouteTarget(:final location):
        context.go(location);
      case _BodyguardTarget(:final bodyguardId):
        CompanyBodyguardReviewPanel.show(
          context: context,
          bodyguardId: bodyguardId,
        );
      case _UserTarget(:final userId):
        UserDetailsScreen.showAsSidebar(context: context, userId: userId);
    }
    return true;
  }

  static _Target? _targetOf(Map<String, dynamic> data) {
    final route = _string(data, JsonKeys.route);
    if (route != null) return _RouteTarget(route);

    final bodyguardId = _string(data, JsonKeys.bodyguardId);
    if (bodyguardId != null &&
        _string(data, JsonKeys.event) != _bodyguardDeletedEvent) {
      return _BodyguardTarget(bodyguardId);
    }

    final userId = _string(data, JsonKeys.userId);
    if (userId != null) return _UserTarget(userId);

    return null;
  }

  static String? _string(Map<String, dynamic> data, String key) {
    final value = data[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }
}

sealed class _Target {
  const _Target();
}

final class _RouteTarget extends _Target {
  const _RouteTarget(this.location);
  final String location;
}

final class _BodyguardTarget extends _Target {
  const _BodyguardTarget(this.bodyguardId);
  final String bodyguardId;
}

final class _UserTarget extends _Target {
  const _UserTarget(this.userId);
  final String userId;
}
