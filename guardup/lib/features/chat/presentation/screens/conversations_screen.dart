import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/extensions/number.extension.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '/core/di/injection_container.dart';
import '/features/auth/auth.dart';
import 'guard_chat_list_screen.dart';
import '../../data/models/conversation.model.dart';
import '../widgets/conversation_card.dart';
import '/features/chat/presentation/screens/chat_screen.dart';

/// Screen displaying active chat conversations with real-time search and infinite pagination.
class ConversationsScreen extends StatefulWidget {
  static const route = '/chat';

  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _searchController = TextEditingController();
  late final _paginationController = PaginationController<ConversationModel>(
    initialState: PaginationState<ConversationModel>(
      items: ConversationModel.fakeData,
      total: ConversationModel.fakeData.length,
      status: ApiState.success(null),
    ),
  );

  @override
  void dispose() {
    _searchController.dispose();
    _paginationController.dispose();
    super.dispose();
  }

  void _handleOpenConversation(ConversationModel conversation) {
    context.push(ChatScreen.route, extra: conversation);
  }

  @override
  Widget build(BuildContext context) {
    final role = (sl.isRegistered<AuthBloc>()
            ? sl<AuthBloc>().state.sessionRole
            : null) ??
        UserRole.customer;

    if (role == UserRole.guard) {
      return const GuardChatListScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.xl.h,

            // Search Bar using AppTextField.search
            Padding(
              padding: context.horizontalEdgeInsets,
              child: AppTextField.search(
                controller: _searchController,
                size: .small,
                decoration: InputDecoration(
                  hintText: context.l10n.searchConversationsHint,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.xl.toBorderRadius,
                    borderSide: BorderSide(
                      color: context.colors.outlineVariant,
                    ),
                  ),
                  fillColor: context.colors.onPrimary,
                    ),
                    style: TextStyle(color: context.colors.onSurface),
              ),
            ),
            AppSpacing.xxl.h,

            // Paginated Conversations List using AppPagination
            Expanded(
              child: AppPagination<ConversationModel>.list(
                controller: _paginationController,
                padding: context.horizontalEdgeInsets + AppSpacing.md.bPadding,
                separatorBuilder: (context, index) => AppSpacing.md.h,
                emptyBuilder: (context) => Center(
                  child: Padding(
                    padding: AppSpacing.xxl.allPadding,
                    child: Text(
                      context.l10n.noConversationsFound,
                      style: context.textTheme.bodyMedium?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                itemBuilder: (context, conversation, index) {
                  return ConversationCard(
                    conversation: conversation,
                    onTap: () => _handleOpenConversation(conversation),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
