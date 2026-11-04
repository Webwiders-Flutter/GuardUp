import 'package:flutter/material.dart';
import 'package:guardup/core/extensions/number.extension.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';

import 'package:quick_container/quick_container.dart';

import '../../data/models/conversation.model.dart';
import '../../data/models/message.model.dart';
import '../widgets/chat_message_widget.dart';

/// Screen displaying real-time 1-on-1 operational chat with an assigned operative.
class ChatScreen extends StatefulWidget {
  final ConversationModel? conversation;

  const ChatScreen({super.key, this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messagesNotifier = ValueNotifier<List<MessageModel>>(
    MessageModel.fakeEscortChatMessages,
  );

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesNotifier.dispose();
    super.dispose();
  }

  void _handleSend() {
    _messageController.clear();
  }

  void _handleAttachment() {}

  void _handleVehicleTap(String? badge) {}

  @override
  Widget build(BuildContext context) {
    final operativeName = widget.conversation?.title ?? 'Vikaram Singh';
    final operativeAvatar =
        widget.conversation?.avatarUrl ?? Assets.images.profilePicture2.path;

    return Scaffold(
      appBar: AppAppBar.transparent(
        showBackIcon: true,
        alignTitle: AlignTitle.left,
        height: 64,
        titleWidget: Row(
          children: [
            // Operative Avatar
            ClipRRect(
              borderRadius: AppRadius.full.toBorderRadius,
              child: Image.asset(
                operativeAvatar,
                width: AppSizes.avatarMd,
                height: AppSizes.avatarMd,
                fit: BoxFit.cover,
              ),
            ),
            AppSpacing.sm.w,

            // Name & Status Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          operativeName,
                          style: context.textTheme.titleSmall?.bold(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppSpacing.xs.w,
                      Icon(
                        Icons.verified_rounded,
                        size: AppSizes.iconXs,
                        color: context.colors.primary,
                      ),
                    ],
                  ),
                  Text(
                    context.l10n.activeEscortSubtitle,
                    style: context.textTheme.labelSmall
                        ?.colour(context.colors.primary)
                        .decreaseSize(3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Messages Scroll View
            Expanded(
              child: ValueListenableBuilder<List<MessageModel>>(
                valueListenable: _messagesNotifier,
                builder: (context, messages, _) {
                  return ListView(
                    controller: _scrollController,
                    padding:
                        context.horizontalEdgeInsets + AppSpacing.sm.yPadding,
                    children: [
                      // Centered Date Pill
                      const ChatDateChip(dateText: 'TODAY, 9:40 AM'),
                      AppSpacing.lg.h,

                      // Messages List
                      for (int i = 0; i < messages.length; i++) ...[
                        ChatMessageWidget(
                          message: messages[i],
                          senderAvatarUrl: operativeAvatar,
                          onVehicleBadgeTap: () =>
                              _handleVehicleTap(messages[i].vehicleBadge),
                        ),
                        if (i < messages.length - 1) AppSpacing.md.h,
                      ],
                    ],
                  );
                },
              ),
            ),

            // Bottom Input Bar
            Padding(
              padding: context.horizontalEdgeInsets + AppSpacing.md.yPadding,
              child: AppTextField(
                controller: _messageController,
                size: AppInputSize.large,
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => _handleSend(),
                style: TextStyle(color: context.colors.onSurface),
                decoration: InputDecoration(
                  hintText: context.l10n.typeMessageHint,
                  fillColor: context.colors.surfaceContainer,
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
                    borderSide: BorderSide(color: context.colors.primary),
                  ),
                  prefixIcon: IconButton(
                    icon: Icon(
                      Icons.add_rounded,
                      color: context.colors.onSurfaceTertiary,
                      size: AppSizes.iconMd,
                    ),
                    onPressed: _handleAttachment,
                  ),
                  suffixIcon: Padding(
                    padding: AppSpacing.xs.allPadding,
                    child: InkWell(
                      onTap: _handleSend,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: QuickContainer(
                        w: 48,
                        h: 48,
                        radius: AppRadius.md,
                        color: context.colors.primary,
                        child: Icon(
                          Icons.send_rounded,
                          size: AppSizes.iconLg,
                          color: context.colors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
