import 'dart:async';

import 'package:flutter/widgets.dart';

import '/app/routes/app_router.dart';
import '/core/di/injection_container.dart';
import '/core/services/notification/push_notification_service.dart';
import '/features/auth/auth.dart';
import '/features/notifications/presentation/notification_navigator.dart';

/// Opens tapped push notifications (app in background, or launched from a
/// notification) with [NotificationNavigator].
///
/// A tap is handled once the session is known and the router has left the
/// splash route, so the target opens on top of the home screen instead of
/// being replaced by the start-up redirect. Taps while signed out are
/// dropped: the user signs in first.
class NotificationTapHandler extends StatefulWidget {
  const NotificationTapHandler({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationTapHandler> createState() => _NotificationTapHandlerState();
}

class _NotificationTapHandlerState extends State<NotificationTapHandler> {
  StreamSubscription<Map<String, dynamic>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = PushNotificationService.onNotificationTap.listen(_onTap);
    final pending = PushNotificationService.takePendingTap();
    if (pending != null) _onTap(pending);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _onTap(Map<String, dynamic> data) async {
    final authBloc = sl<AuthBloc>();
    final authState = authBloc.state.isUnknown
        ? await authBloc.stream.firstWhere((state) => !state.isUnknown)
        : authBloc.state;
    if (!authState.isAuthenticated) return;

    await _leftSplash();
    if (!mounted) return;
    NotificationNavigator.openPush(data);
  }

  /// Completes once the router is past the splash route (or after a timeout).
  Future<void> _leftSplash() async {
    final delegate = AppRouter.router.routerDelegate;
    bool onSplash() =>
        delegate.currentConfiguration.uri.path == SplashScreen.route;
    if (!onSplash()) return;

    final completer = Completer<void>();
    void listener() {
      if (!onSplash() && !completer.isCompleted) completer.complete();
    }

    delegate.addListener(listener);
    try {
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {},
      );
    } finally {
      delegate.removeListener(listener);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
