import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/features/auth/bloc/auth_bloc.dart';
import 'package:guardup/features/notifications/bloc/unread_count/unread_notification_count_cubit.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';

class _NavItemData {
  final String label;
  final SvgGenImage svg;
  final int branchIndex;
  final double? size;

  const _NavItemData({
    required this.label,
    required this.svg,
    required this.branchIndex,
  }) : size = null;
}

class MainNavigationScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationScreen({super.key, required this.navigationShell});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int get _currentIndex => widget.navigationShell.currentIndex;

  @override
  void initState() {
    super.initState();
    final userId = sl.isRegistered<AuthBloc>()
        ? sl<AuthBloc>().state.user?.id
        : null;
    if (userId != null &&
        userId.isNotEmpty &&
        sl.isRegistered<UnreadNotificationCountCubit>()) {
      sl<UnreadNotificationCountCubit>().loadCount(userId);
    }
  }

  List<_NavItemData> _getNavItems(BuildContext context) {
    final l10n = context.l10n;
    return [
      _NavItemData(label: l10n.navHome, svg: Assets.svg.home, branchIndex: 0),
      _NavItemData(
        label: l10n.navBookings,
        svg: Assets.svg.calender,
        branchIndex: 1,
      ),
      _NavItemData(
        label: l10n.navChat,
        svg: Assets.svg.message,
        branchIndex: 2,
      ),
      _NavItemData(
        label: l10n.navAlerts,
        svg: Assets.svg.notificationBell,
        branchIndex: 3,
      ),
      _NavItemData(
        label: l10n.navProfile,
        svg: Assets.svg.person,
        branchIndex: 4,
      ),
    ];
  }

  void _onTap(int branchIndex) {
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    final navItems = _getNavItems(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (currentIndex != 0) {
          _onTap(0);
          return;
        }
        final popupResult = await AppPopup.showExitConfirmation(context);
        if (popupResult?.action == PopupAction.confirm) {
          unawaited(SystemNavigator.pop());
        }
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: QuickContainer(
          color: context.colors.transparent,
          py: AppSpacing.sm,
          border: Border(
            top: BorderSide(color: context.colors.primary, width: 0.3),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = item.branchIndex == currentIndex;
                final activeColor = isSelected
                    ? context.colors.primary
                    : context.colors.outline;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTap(item.branchIndex),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BlocBuilder<UnreadNotificationCountCubit, int>(
                            bloc: sl.isRegistered<UnreadNotificationCountCubit>()
                                ? sl<UnreadNotificationCountCubit>()
                                : null,
                            builder: (context, unreadCount) {
                              final iconSvg = item.svg.svg(
                                width: item.size ?? 23,
                                height: item.size ?? 23,
                                colorFilter: ColorFilter.mode(
                                  activeColor,
                                  BlendMode.srcIn,
                                ),
                              );

                              if (item.branchIndex == 3 && unreadCount > 0) {
                                return Badge.count(
                                  count: unreadCount,
                                  maxCount: 99,
                                  backgroundColor: context.colors.error,
                                  textColor: Colors.white,
                                  child: iconSvg,
                                );
                              }
                              return iconSvg;
                            },
                          ),
                          AppSpacing.xs.h,
                          Text(
                            item.label,
                            style: context.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: activeColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
