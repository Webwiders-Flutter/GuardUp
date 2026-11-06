import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '../../data/enums/message_status.enum.dart';
import '../../data/models/conversation.model.dart';
import '../../data/models/message.model.dart';

/// Data representation for a bodyguard operative conversation item.
class GuardChatListItem {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isVerified;
  final String time;
  final String missionTag;
  final bool hasActiveDot;
  final bool isActiveEscort;
  final bool isDoubleCheck;
  final bool isGreenCheck;
  final String lastMessage;

  const GuardChatListItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isVerified,
    required this.time,
    required this.missionTag,
    this.hasActiveDot = false,
    this.isActiveEscort = false,
    this.isDoubleCheck = false,
    this.isGreenCheck = false,
    required this.lastMessage,
  });

  static List<GuardChatListItem> get mockGuardList => [
    GuardChatListItem(
      id: 'guard_conv_1',
      name: 'David Sterling',
      avatarUrl: Assets.images.onboardingImage01.path,
      isVerified: true,
      time: '9:40 AM',
      hasActiveDot: true,
      isActiveEscort: true,
      missionTag: 'ACTIVE ESCORT • ESCALADE B6',
      isDoubleCheck: true,
      isGreenCheck: true,
      lastMessage: 'Just got into the elevator, 30 seconds a...',
    ),
    GuardChatListItem(
      id: 'guard_conv_2',
      name: 'Vinay Pandey',
      avatarUrl: Assets.images.profilePicture.path,
      isVerified: false,
      time: 'Yesterday',
      hasActiveDot: false,
      isActiveEscort: false,
      missionTag: '24/7 OPERATIONS HUB',
      isDoubleCheck: false,
      isGreenCheck: false,
      lastMessage: 'Escort corridor cleared. LAX Terminal 4 st',
    ),
    GuardChatListItem(
      id: 'guard_conv_3',
      name: 'Junaid Khan',
      avatarUrl: Assets.images.onboardingImage02.path,
      isVerified: false,
      time: 'Apr 26',
      hasActiveDot: false,
      isActiveEscort: false,
      missionTag: 'UPCOMING MISSION • APR 28',
      isDoubleCheck: true,
      isGreenCheck: false,
      lastMessage: 'Booking confirmed for tomorrow, 9:00',
    ),
    GuardChatListItem(
      id: 'guard_conv_4',
      name: 'Jonny Vance',
      avatarUrl: Assets.images.profilePicture2.path,
      isVerified: false,
      time: 'Apr 22',
      hasActiveDot: false,
      isActiveEscort: false,
      missionTag: 'COMPLETED • SWISS EMBASSY ESCORT',
      isDoubleCheck: false,
      isGreenCheck: false,
      lastMessage: 'Thank you for rating 5 stars! Stay safe and secure.',
    ),
    GuardChatListItem(
      id: 'guard_conv_5',
      name: 'Jordan Massy',
      avatarUrl: Assets.images.profilePicture.path,
      isVerified: false,
      time: 'Apr 22',
      hasActiveDot: false,
      isActiveEscort: false,
      missionTag: 'COMPLETED • SWISS EMBASSY ESCORT',
      isDoubleCheck: false,
      isGreenCheck: false,
      lastMessage: 'Thank you for rating 5 stars! Stay safe and secure.',
    ),
    GuardChatListItem(
      id: 'guard_conv_6',
      name: 'Harry Johnson',
      avatarUrl: Assets.images.onboardingImage01.path,
      isVerified: false,
      time: 'Apr 26',
      hasActiveDot: false,
      isActiveEscort: false,
      missionTag: 'UPCOMING MISSION • APR 28',
      isDoubleCheck: true,
      isGreenCheck: false,
      lastMessage:
          'Booking confirmed for tomorrow, 9:00 AM. Route pre-scanned.',
    ),
  ];
}

/// Screen presenting the specialized bodyguard operative chat list:
/// "GuardUp Bodyguard - Chatlist" with live mission indicators, vehicle tagging,
/// filter quick-action, and luxury aesthetic matching Figma specs.
class GuardChatListScreen extends StatefulWidget {
  const GuardChatListScreen({super.key});

  @override
  State<GuardChatListScreen> createState() => _GuardChatListScreenState();
}

class _GuardChatListScreenState extends State<GuardChatListScreen> {
  final _searchController = TextEditingController();
  final _filterQueryNotifier = ValueNotifier<String>('');
  final _selectedFilterNotifier = ValueNotifier<String>('ALL');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _filterQueryNotifier.value = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterQueryNotifier.dispose();
    _selectedFilterNotifier.dispose();
    super.dispose();
  }

  void _handleOpenConversation(GuardChatListItem item) {
    context.push(
      AppRoutes.chatDetail,
      extra: ConversationModel(
        id: item.id,
        title: item.name,
        avatarUrl: item.avatarUrl,
        isVerified: item.isVerified,
        customFormattedTime: item.missionTag,
        updatedAt: DateTime.now(),
        lastMessage: MessageModel(
          id: 'msg_${item.id}',
          conversationId: item.id,
          senderId: item.isDoubleCheck ? 'me' : 'client',
          content: item.lastMessage,
          status: item.isGreenCheck
              ? MessageStatus.read
              : MessageStatus.delivered,
          createdAt: DateTime.now(),
          isMe: item.isDoubleCheck,
        ),
      ),
    );
  }

  void _handleFilterTap() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                16.h,
                Text(
                  'Filter Missions & Chats',
                  style: context.textTheme.titleMedium?.bold(),
                ),
                16.h,
                for (final option in const [
                  'ALL',
                  'ACTIVE ESCORTS',
                  'UPCOMING MISSIONS',
                  'COMPLETED',
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option,
                      style: context.textTheme.labelMedium?.bold().colour(
                        _selectedFilterNotifier.value == option
                            ? context.colors.primary
                            : context.colors.onSurface,
                      ),
                    ),
                    trailing: _selectedFilterNotifier.value == option
                        ? Icon(
                            Icons.check_rounded,
                            color: context.colors.primary,
                          )
                        : null,
                    onTap: () {
                      _selectedFilterNotifier.value = option;
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            AppSpacing.md.h,

            // 1. Search Bar + Filter Squircle Button Row
            Padding(
              padding: context.horizontalEdgeInsets,
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField.search(
                      controller: _searchController,
                      size: AppInputSize.small,
                      decoration: InputDecoration(
                        hintText:
                            'Search conversations, operatives, missions...',
                        hintStyle: context.textTheme.bodyMedium?.copyWith(
                          fontSize: 12.5,
                          color: context.colors.onSurfaceVariant.withValues(
                            alpha: 0.65,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide(
                            color: context.colors.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide(
                            color: context.colors.primary,
                            width: 1.2,
                          ),
                        ),
                        fillColor: context.colors.onPrimary,
                      ),
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // AppSpacing.sm.w,

                  // Filter squircle icon button
                  // InkWell(
                  //   onTap: _handleFilterTap,
                  //   borderRadius: BorderRadius.circular(AppRadius.lg),
                  //   child: QuickContainer(
                  //     w: 48,
                  //     h: 48,
                  //     borderRadius: BorderRadius.circular(AppRadius.lg),
                  //     color: context.colors.onPrimary,
                  //     border: Border.all(
                  //       color: context.colors.primary.withValues(alpha: 0.6),
                  //       width: 1,
                  //     ),
                  //     alignment: Alignment.center,
                  //     child: Icon(
                  //       Icons.tune_rounded,
                  //       size: 20,
                  //       color: context.colors.primary,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),

            AppSpacing.md.h,

            // 2. Bodyguard Conversations Feed
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  _filterQueryNotifier,
                  _selectedFilterNotifier,
                ]),
                builder: (context, _) {
                  final query = _filterQueryNotifier.value;
                  final selectedCategory = _selectedFilterNotifier.value;

                  final items = GuardChatListItem.mockGuardList.where((item) {
                    // Category filter
                    if (selectedCategory == 'ACTIVE ESCORTS' &&
                        !item.isActiveEscort) {
                      return false;
                    }
                    if (selectedCategory == 'UPCOMING MISSIONS' &&
                        !item.missionTag.contains('UPCOMING')) {
                      return false;
                    }
                    if (selectedCategory == 'COMPLETED' &&
                        !item.missionTag.contains('COMPLETED')) {
                      return false;
                    }

                    // Query filter
                    if (query.isEmpty) return true;
                    return item.name.toLowerCase().contains(query) ||
                        item.missionTag.toLowerCase().contains(query) ||
                        item.lastMessage.toLowerCase().contains(query);
                  }).toList();

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No operative conversations found.',
                        style: context.textTheme.bodyMedium?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: context.horizontalEdgeInsets.add(
                      const EdgeInsets.only(bottom: AppSpacing.xxl),
                    ),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => AppSpacing.md.h,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildGuardConversationCard(context, item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardConversationCard(
    BuildContext context,
    GuardChatListItem item,
  ) {
    return GestureDetector(
      onTap: () => _handleOpenConversation(item),
      behavior: HitTestBehavior.opaque,
      child: QuickContainer(
        w: double.infinity,
        px: 14,
        py: 14,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: context.colors.onPrimary,

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Operative / Client Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 50,
                height: 50,
                child: Image.asset(item.avatarUrl, fit: BoxFit.cover),
              ),
            ),
            AppSpacing.md.w,

            // Middle & Right: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Name + Verified + Timestamp
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.titleSmall
                                    ?.bold()
                                    .colour(context.colors.onSurface),
                              ),
                            ),
                            if (item.isVerified) ...[
                              (AppSpacing.xxs + 2).w,
                              Assets.svg.verifiedShieldBadge.svg(
                                width: 14,
                                height: 14,
                              ),
                            ],
                          ],
                        ),
                      ),

                      Text(
                        item.time,
                        style: context.textTheme.labelSmall
                            ?.copyWith(
                              fontSize: 11,
                              fontWeight: item.hasActiveDot
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            )
                            .colour(
                              item.hasActiveDot
                                  ? context.colors.primary
                                  : context.colors.onSurfaceVariant.withValues(
                                      alpha: 0.8,
                                    ),
                            ),
                      ),
                    ],
                  ),
                  4.h,

                  // Row 2: Mission / Escort Tag (Gold)
                  QuickContainer(
                    px: 8,
                    py: 3,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    color: item.hasActiveDot
                        ? context.colors.primary.withValues(alpha: 0.1)
                        : context.colors.transparent,
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        if (item.hasActiveDot) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          6.w,
                        ],
                        Text(
                          item.missionTag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelSmall
                              ?.copyWith(
                                fontSize: 10,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                              )
                              .colour(context.colors.primary),
                        ),
                      ],
                    ),
                  ),
                  4.h,

                  // Row 3: Message preview + Read receipts
                  Row(
                    children: [
                      if (item.isDoubleCheck) ...[
                        Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: item.isGreenCheck
                              ? context.colors.success
                              : context.colors.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                        5.w,
                      ],
                      Expanded(
                        child: Text(
                          item.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall
                              ?.copyWith(fontSize: 12)
                              .colour(context.colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
