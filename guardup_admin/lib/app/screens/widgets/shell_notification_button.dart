import 'package:flutter/material.dart';

import '/features/notifications/presentation/widgets/notification_icon.widget.dart';

/// Top-bar notification button showing live unread badge count.
class ShellNotificationButton extends StatelessWidget {
  const ShellNotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotificationIconWidget();
  }
}
