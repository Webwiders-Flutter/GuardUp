import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/booking/booking.dart';
import 'package:guardup/features/chat/chat.dart';
import 'package:guardup/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/logger/app_logger.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';

class _NavItemData {
  final String label;
  final SvgGenImage svg;
  final int branchIndex;

  const _NavItemData({
    required this.label,
    required this.svg,
    required this.branchIndex,
  });
}

class MainNavigationScreen extends StatefulWidget {
  final StatefulNavigationShell? navigationShell;

  const MainNavigationScreen({super.key, this.navigationShell});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _internalIndex = 0;

  int get _currentIndex =>
      widget.navigationShell?.currentIndex ?? _internalIndex;

  List<_NavItemData> _getNavItems(BuildContext context) {
    final l10n = context.l10n;
    return [
      _NavItemData(label: l10n.navHome, svg: Assets.svg.home, branchIndex: 0),
      _NavItemData(
        label: l10n.navBookings,
        svg: Assets.svg.calender,
        branchIndex: 1,
      ),
      _NavItemData(label: l10n.navChat, svg: Assets.svg.chat, branchIndex: 2),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        AppLogger.i('AppLifecycleState.resumed');
        break;
      case AppLifecycleState.inactive:
        AppLogger.i('AppLifecycleState.inactive');
        break;
      case AppLifecycleState.paused:
        AppLogger.i('AppLifecycleState.paused');
        break;
      case AppLifecycleState.detached:
        AppLogger.i('AppLifecycleState.detached');
        break;
      case AppLifecycleState.hidden:
        AppLogger.i('AppLifecycleState.hidden');
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTap(int branchIndex) {
    if (widget.navigationShell != null) {
      widget.navigationShell!.goBranch(
        branchIndex,
        initialLocation: branchIndex == widget.navigationShell!.currentIndex,
      );
    } else {
      setState(() {
        _internalIndex = branchIndex;
      });
    }
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
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.transparent,
        body:
            widget.navigationShell ??
            IndexedStack(
              index: currentIndex,
              children: [
                Center(
                  child: Text(
                    context.l10n.navHome,
                    style: context.textTheme.headlineMedium?.copyWith(
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                const BookingsScreen(),
                const ConversationsScreen(),
                const NotificationsScreen(),
                const ProfileScreen(),
              ],
            ),
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
                          item.svg.svg(
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              activeColor,
                              BlendMode.srcIn,
                            ),
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
