import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/extensions/number.extension.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/services/notification/push_notification_service.dart';

/// Data model representing an active in-app foreground notification banner.
class ForegroundBannerData {
  final String title;
  final String body;
  final Map<String, dynamic> data;

  const ForegroundBannerData({
    required this.title,
    required this.body,
    this.data = const {},
  });

  factory ForegroundBannerData.fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title']?.toString() ??
        'New Notification';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';

    return ForegroundBannerData(title: title, body: body, data: message.data);
  }
}

/// A floating in-app notification banner for foreground push alerts.
class ForegroundNotificationBanner extends StatefulWidget {
  final void Function(ForegroundBannerData bannerData)? onTap;
  final Duration displayDuration;

  const ForegroundNotificationBanner({
    super.key,
    this.onTap,
    this.displayDuration = const Duration(seconds: 5),
  });

  @override
  State<ForegroundNotificationBanner> createState() =>
      _ForegroundNotificationBannerState();
}

class _ForegroundNotificationBannerState
    extends State<ForegroundNotificationBanner>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final ValueNotifier<ForegroundBannerData?> _currentBannerNotifier =
      ValueNotifier(null);

  StreamSubscription<RemoteMessage>? _messageSubscription;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 280),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _messageSubscription = PushNotificationService.onForegroundMessage.listen(
      _handleIncomingMessage,
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _autoDismissTimer?.cancel();
    _animController.dispose();
    _pulseController.dispose();
    _currentBannerNotifier.dispose();
    super.dispose();
  }

  void _handleIncomingMessage(RemoteMessage message) {
    final bannerData = ForegroundBannerData.fromRemoteMessage(message);

    if (bannerData.title.trim().isEmpty && bannerData.body.trim().isEmpty) {
      return;
    }

    _autoDismissTimer?.cancel();
    _currentBannerNotifier.value = bannerData;

    _animController.forward(from: 0.0);
    HapticFeedback.mediumImpact();

    _autoDismissTimer = Timer(widget.displayDuration, _dismissBanner);
  }

  void _dismissBanner() {
    _autoDismissTimer?.cancel();
    if (!mounted) return;

    _animController.reverse().then((_) {
      if (mounted) {
        _currentBannerNotifier.value = null;
      }
    });
  }

  void _onBannerTap(ForegroundBannerData data) {
    _dismissBanner();

    if (widget.onTap != null) {
      widget.onTap!(data);
      return;
    }

    final targetRoute = data.data['route']?.toString();
    if (targetRoute != null && targetRoute.isNotEmpty) {
      context.push(targetRoute);
    } else {
      context.push(AppRoutes.notifications);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        if (_animController.value == 0.0 &&
            _currentBannerNotifier.value == null) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<ForegroundBannerData?>(
          valueListenable: _currentBannerNotifier,
          builder: (context, bannerData, _) {
            if (bannerData == null) {
              return const SizedBox.shrink();
            }

            return SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _NotificationPill(
                        data: bannerData,
                        accentColor: context.colors.primary,
                        pulseAnimation: _pulseAnimation,
                        onTap: () => _onBannerTap(bannerData),
                        onDismiss: _dismissBanner,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NotificationPill extends StatelessWidget {
  const _NotificationPill({
    required this.data,
    required this.accentColor,
    required this.pulseAnimation,
    required this.onTap,
    required this.onDismiss,
  });

  final ForegroundBannerData data;
  final Color accentColor;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentBgColor = accentColor.withValues(alpha: 0.12);

    return Material(
      color: colors.surface,
      elevation: 6,
      shadowColor: colors.primary.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.full.toBorderRadius,
        side: BorderSide(color: accentColor.withValues(alpha: 0.35), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.full.toBorderRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.xs + 3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (context, _) {
                        return Container(
                          width: AppSpacing.xl,
                          height: AppSpacing.xl,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(
                              alpha: 0.22 * (1 - pulseAnimation.value),
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: AppSpacing.lg + 4,
                      height: AppSpacing.lg + 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentBgColor,
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        size: AppSpacing.md,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                AppSpacing.sm.w,
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.semiBold().colour(
                          colors.onSurface,
                        ),
                      ),
                      if (data.body.isNotEmpty) ...[
                        Text(
                          data.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall
                              ?.decreaseSize(1)
                              .colour(colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.sm.w,
                InkWell(
                  onTap: onDismiss,
                  borderRadius: AppRadius.full.toBorderRadius,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Icon(
                      Icons.close_rounded,
                      size: AppSpacing.md + 2,
                      color: colors.onSurfaceVariant
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
