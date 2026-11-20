import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/core/extensions/datetime.extension.dart';
import 'package:guardup/shared/widgets/buttons/app_button.dart';
import 'package:guardup/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '/shared/widgets/misc/skeleton_effect.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/sections/app_appbar.dart';

import 'package:quick_container/quick_container.dart';

import '../../bloc/notifications/notifications_bloc.dart';
import '../../bloc/notifications/notifications_event.dart';
import '../../bloc/notifications/notifications_state.dart';
import '../../bloc/unread_count/unread_notification_count_cubit.dart';
import '../../data/enums/notification_type.enum.dart';
import '../../data/models/notification.model.dart';
import '../widgets/notification_card.dart';
import '/features/booking/presentation/screens/bookings_screen.dart';
import '/features/payments/presentation/screens/my_wallet_screen.dart';

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
  late final NotificationsBloc _notificationsBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _notificationsBloc = sl<NotificationsBloc>();

    _paginationController = PaginationController<NotificationModel>(
      initialState: _notificationsBloc.state.paginationState,
      onRefresh: () async {
        _notificationsBloc.add(
          const NotificationsFetchRequested(refresh: true),
        );
      },
      onLoadMore: () async {
        _notificationsBloc.add(const NotificationsLoadMoreRequested());
      },
    );

    // Initial fetch
    _notificationsBloc.add(const NotificationsFetchRequested(refresh: true));

    _tabController.addListener(_onTabControllerChanged);
  }

  NotificationCategory _categoryForIndex(int index) {
    return switch (index) {
      1 => NotificationCategory.booking,
      2 => NotificationCategory.payment,
      3 => NotificationCategory.account,
      _ => NotificationCategory.all,
    };
  }

  void _onTabSelected(int index) {
    final category = _categoryForIndex(index);
    _notificationsBloc.add(NotificationsCategoryChanged(category));
    _paginationController.scrollToTop();
  }

  void _onTabControllerChanged() {
    if (_tabController.index !=
        _categoryIndex(_notificationsBloc.state.activeCategory)) {
      _onTabSelected(_tabController.index);
    }
  }

  int _categoryIndex(NotificationCategory category) {
    return switch (category) {
      NotificationCategory.booking => 1,
      NotificationCategory.payment => 2,
      NotificationCategory.account => 3,
      NotificationCategory.all => 0,
    };
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChanged);
    _tabController.dispose();
    _paginationController.dispose();
    super.dispose();
  }

  List<String> _tabs(BuildContext context) => [
    context.l10n.allTab,
    context.l10n.bookingTab,
    context.l10n.paymentTab,
    context.l10n.accountTab,
  ];

  void _handleMarkAllAsRead() {
    _notificationsBloc.add(const NotificationsMarkAllAsReadRequested());
    AppSnackbar.success(context.l10n.allMarkedAsRead);
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      _notificationsBloc.add(NotificationMarkAsReadRequested(notification.id));
    }

    if (notification.type.category == NotificationCategory.booking) {
      context.push(BookingsScreen.route);
    } else if (notification.type.category == NotificationCategory.payment) {
      context.push(MyWalletScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _notificationsBloc,
      child: BlocListener<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          _paginationController.updateState(state.paginationState);
          final expectedIndex = _categoryIndex(state.activeCategory);
          if (_tabController.index != expectedIndex) {
            _tabController.animateTo(expectedIndex);
          }
          if (state.actionError != null) {
            AppSnackbar.error(state.actionError!);
          }
        },
        child: Scaffold(
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
                    onTap: _onTabSelected,
                  ),
                ),
                AppSpacing.md.h,

                // Paginated Notifications List with Skeletonizer shimmer loader
                Expanded(
                  child: AppPagination<NotificationModel>.list(
                    controller: _paginationController,
                    padding:
                        context.horizontalEdgeInsets + AppSpacing.md.bPadding,
                    separatorBuilder: (context, index) => AppSpacing.md.h,
                    initialLoaderBuilder: (context) {
                      final sampleList = NotificationModel.fakeData;
                      return Skeletonizer(
                        effect: SkeletonEffect.adaptiveShimmer(context),
                        enabled: true,
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          padding:
                              context.horizontalEdgeInsets +
                              AppSpacing.md.bPadding,
                          itemCount: 4,
                          separatorBuilder: (context, index) => AppSpacing.md.h,
                          itemBuilder: (context, index) {
                            return NotificationCard(
                              notification:
                                  sampleList[index % sampleList.length],
                            );
                          },
                        ),
                      );
                    },
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
        BlocBuilder<UnreadNotificationCountCubit, int>(
          builder: (context, unreadCount) {
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
