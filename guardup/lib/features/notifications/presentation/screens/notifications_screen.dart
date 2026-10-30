import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/constants/notification_type.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/deep_link_handler.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/datetime_extensions.dart';
import 'package:guardup/core/utils/missing_docs_formatter.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:guardup/features/notifications/presentation/bloc/notification_event.dart';
import 'package:guardup/features/notifications/presentation/bloc/notification_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(
      const FetchNotificationsEvent(isRefresh: true),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationBloc>().add(const FetchNotificationsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.mainBackgroundColor,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
        title: AppText(
          context.l10n.notifications,
          color: AppColors.whiteColor,
          fontSize: 18,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: AppColors.mainBackgroundColor,
                    title: AppText(
                      context.l10n.confirm,
                      color: AppColors.whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    content: AppText(
                      context.l10n.confirmClearAllNotifications,
                      color: AppColors.whiteColor,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: AppText(
                          context.l10n.cancel,
                          color: AppColors.whiteColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: AppText(
                          context.l10n.clearAll,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true && mounted) {
                context.read<NotificationBloc>().add(
                  ClearAllNotificationsEvent(),
                );
              }
            },
            child: AppText(context.l10n.clearAll, color: AppColors.primary),
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.status == NotificationStatus.loading &&
              state.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context.read<NotificationBloc>().add(
                const FetchNotificationsEvent(isRefresh: true),
              );
            },
            child: state.notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: AppText(
                            context.l10n.noNotificationsAvailable,
                            color: AppColors.textHintLight,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.hasReachedMax
                        ? state.notifications.length
                        : state.notifications.length + 1,
                    itemBuilder: (context, index) {
                      if (index >= state.notifications.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }

                      final notification = state.notifications[index];

                      String displayTitle = notification.displayTitle(
                        context.l10n.localeName,
                      );
                      final rawBody = notification.displayBody(
                        context.l10n.localeName,
                      );
                      final isSocial = [
                        'like',
                        'follow',
                        'comment',
                      ].contains(notification.type);
                      String displayBody = isSocial
                          ? (rawBody.isEmpty && notification.type == 'like'
                                ? (context.isArabic
                                      ? 'اضغط لرؤية من أعجب بمقطع الفيديو الخاص بك'
                                      : 'Tap to see who liked your video')
                                : rawBody)
                          : MissingDocsFormatter.format(
                              rawBody,
                              isArabic: context.isArabic,
                            );

                      return Dismissible(
                        key: Key(notification.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: AppColors.mainBackgroundColor,
                                title: AppText(
                                  context.l10n.confirm,
                                  color: AppColors.whiteColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                content: AppText(
                                  context.l10n.confirmDeleteNotification,
                                  color: AppColors.whiteColor,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: AppText(
                                      context.l10n.cancel,
                                      color: AppColors.whiteColor,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: AppText(
                                      context.l10n.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (_) {
                          context.read<NotificationBloc>().add(
                            DeleteNotificationEvent(
                              notificationId: notification.id,
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            if (!notification.isRead) {
                              context.read<NotificationBloc>().add(
                                MarkNotificationAsReadEvent(
                                  notificationId: notification.id,
                                ),
                              );
                            }

                            final type = NotificationType.fromString(
                              notification.type,
                            );
                            switch (type) {
                              case NotificationType.supportTicket:
                              case NotificationType.ticket:
                                final ticketId =
                                    notification.otherData['ticketId'] ??
                                    notification.otherData['ticket_id'] ??
                                    notification.otherData['id'];
                                if (ticketId != null &&
                                    ticketId.toString().isNotEmpty) {
                                  DeepLinkHandler.handle(
                                    context,
                                    'skyviora://ticket/$ticketId',
                                  );
                                } else {
                                  context.pushNamed(AppRouter.myTickets);
                                }
                                break;
                              case NotificationType.general:
                                final deepLink =
                                    notification.otherData['deep_link'] ??
                                    notification.otherData['url'] ??
                                    notification.otherData['link'];
                                if (deepLink != null &&
                                    deepLink.toString().isNotEmpty) {
                                  DeepLinkHandler.handle(
                                    context,
                                    deepLink.toString(),
                                  );
                                }
                                break;
                              case NotificationType.unknown:
                                break;
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: notification.isRead
                                  ? Colors.transparent
                                  : AppColors.primary.withValues(alpha: 0.05),
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.whiteColor.withValues(
                                    alpha: 0.05,
                                  ),
                                  width: 1,
                                ),
                                left: BorderSide(
                                  color: notification.isRead
                                      ? Colors.transparent
                                      : AppColors.primary,
                                  width: 3,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 16.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(
                                    top: 5,
                                    right: 12,
                                  ),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: notification.isRead
                                        ? Colors.transparent
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: notification.isRead
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: AppText(
                                              displayTitle,
                                              color: notification.isRead
                                                  ? AppColors.whiteColor
                                                        .withValues(alpha: 0.8)
                                                  : AppColors.whiteColor,
                                              fontWeight: notification.isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.bold,
                                              fontSize: 15,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          AppText(
                                            notification.createdAt.timeAgo(
                                              context,
                                            ),
                                            color: AppColors.textHintLight,
                                            fontSize: 12,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      AppText(
                                        displayBody,
                                        color: notification.isRead
                                            ? AppColors.textHintLight
                                                  .withValues(alpha: 0.7)
                                            : AppColors.textHintLight,
                                        fontSize: 13,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
