import 'package:flutter/material.dart';
import 'package:guardup/core/constants/app_radius.dart';
import 'package:guardup/core/extensions/number.extension.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '../../data/models/conversation.model.dart';
import '../widgets/conversation_card.dart';

/// Screen displaying active chat conversations with real-time search and infinite pagination.
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late final TextEditingController _searchController;
  late final PaginationController<ConversationModel> _paginationController;
  late final ValueNotifier<List<ConversationModel>> _allConversationsNotifier;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    final initialList = ConversationModel.fakeConversations;
    _allConversationsNotifier = ValueNotifier<List<ConversationModel>>(
      initialList,
    );

    _paginationController = PaginationController<ConversationModel>(
      initialState: PaginationState<ConversationModel>(
        items: initialList,
        total: initialList.length,
        status: const ApiState.success(null),
      ),
      onRefresh: _handleRefresh,
      onLoadMore: _handleLoadMore,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _paginationController.dispose();
    _allConversationsNotifier.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String query) {
    final trimmed = query.trim().toLowerCase();
    final allItems = _allConversationsNotifier.value;

    final filtered = trimmed.isEmpty
        ? allItems
        : allItems.where((c) {
            final matchesTitle = c.title.toLowerCase().contains(trimmed);
            final matchesSnippet = c.snippet.toLowerCase().contains(trimmed);
            final matchesClearance = c.participants.any(
              (p) => (p.clearanceLevel ?? '').toLowerCase().contains(trimmed),
            );
            return matchesTitle || matchesSnippet || matchesClearance;
          }).toList();

    _paginationController.updateState(
      PaginationState<ConversationModel>(
        items: filtered,
        total: filtered.length,
        status: const ApiState.success(null),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    _handleSearchChanged(_searchController.text);
  }

  Future<void> _handleLoadMore() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
  }

  void _handleOpenConversation(ConversationModel conversation) {
    AppSnackbar.info(
      'Opening conversation with ${conversation.title}',
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.xl.toBorderRadius,
                    borderSide: BorderSide(
                      color: context.colors.outlineVariant,
                    ),
                  ),
                  fillColor: context.colors.surface,
                ),
                onChanged: _handleSearchChanged,
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
