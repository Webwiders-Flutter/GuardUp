import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/app/routes/app_routes.dart';
import 'package:guardup/core/extensions/datetime.extension.dart';
import 'package:guardup/shared/widgets/buttons/app_button.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '/shared/widgets/sections/app_appbar.dart';

import 'package:quick_container/quick_container.dart';

import '../../data/models/notification.model.dart';
import '../../data/enums/notification_type.enum.dart';
import '../widgets/notification_card.dart';

/// Notifications screen featuring category tabs, unread count badge,
/// "Mark all as read" action, and paginated notifications grouped by date.
class NotificationsScreen extends StatefulWidget {
  static const route = '/notifications';

  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PaginationController<NotificationModel> _paginationController;
  late final ValueNotifier<int> _unreadCountNotifier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final initialList = NotificationModel.fakeData;
    final unreadCount = initialList.where((n) => !n.isRead).length;
    _unreadCountNotifier = ValueNotifier<int>(unreadCount);

    _paginationController = PaginationController<NotificationModel>(
      initialState: PaginationState<NotificationModel>(
        items: initialList,
        total: initialList.length,
        status: const ApiState.success(null),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paginationController.dispose();
    _unreadCountNotifier.dispose();
    super.dispose();
  }

  List<String> _tabs(BuildContext context) => [
    context.l10n.allTab,
    context.l10n.bookingTab,
    context.l10n.paymentTab,
    context.l10n.accountTab,
  ];

  void _handleMarkAllAsRead() {
    // Clickflow handler: no dynamic mutations needed
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (notification.type.category == NotificationCategory.booking) {
      context.push(AppRoutes.bookings);
    } else if (notification.type.category == NotificationCategory.payment) {
      context.push(AppRoutes.myWallet);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        alignTitle: .left,
        titleWidget: _buildAppBarTitle(context),
        actions: [
          AppButton(
            type: .text,
            text: context.l10n.markAllAsRead,
            foregroundColor: context.colors.onSurfaceTertiary,
            textStyle: context.textTheme.labelMedium,
            padding: AppSpacing.md.rPadding,
            onPressed: _handleMarkAllAsRead,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.sm.h,

            // Filter Tabs via AppTabBar
            Padding(
              padding: context.horizontalEdgeInsets,
              child: AppTabBar.pill(
                controller: _tabController,
                tabNames: _tabs(context),
              ),
            ),
            AppSpacing.md.h,

            // Paginated Notifications List
            Expanded(
              child: AppPagination<NotificationModel>.list(
                controller: _paginationController,
                padding: context.horizontalEdgeInsets + AppSpacing.md.bPadding,
                separatorBuilder: (context, index) => AppSpacing.md.h,
                itemBuilder: (context, notification, index) {
                  final items = _paginationController.value.items;
                  final isFirstOfToday =
                      index == 0 && notification.createdAt.isToday;
                  final isFirstOfYesterday =
                      (index == 0 && !notification.createdAt.isToday) ||
                      (index > 0 &&
                          items[index - 1].createdAt.isToday &&
                          !notification.createdAt.isToday);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isFirstOfToday) ...[
                        Text(
                          context.l10n.todaySection,
                          style: context.textTheme.labelMedium?.colour(
                            context.colors.primary,
                          ),
                        ),
                        AppSpacing.sm.h,
                      ] else if (isFirstOfYesterday) ...[
                        AppSpacing.lg.h,
                        Text(
                          context.l10n.yesterdaySection,
                          style: context.textTheme.labelMedium?.colour(
                            context.colors.primary,
                          ),
                        ),
                        AppSpacing.sm.h,
                      ],
                      NotificationCard(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Notifications Title
        Text(
          context.l10n.notifications,
          style: context.textTheme.titleMedium?.bold(),
        ),
        AppSpacing.sm.w,

        // Unread Count Badge
        ValueListenableBuilder<int>(
          valueListenable: _unreadCountNotifier,
          builder: (context, unreadCount, _) {
            if (unreadCount <= 0) return const SizedBox.shrink();

            return QuickContainer(
              radius: AppRadius.full,
              color: context.colors.surfaceContainerHigh.withValues(alpha: 0.8),
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.5),
                width: 1,
              ),
              px: AppSpacing.sm,
              py: AppSpacing.xxs,
              child: Text(
                context.l10n.unreadCountBadge(unreadCount),
                style: context.textTheme.labelSmall?.colour(
                  context.colors.primary,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
