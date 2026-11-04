import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:quick_container/quick_container.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../bloc/legal_content/legal_content_bloc.dart';
import '../../bloc/legal_content/legal_content_event.dart';
import '../../bloc/legal_content/legal_content_state.dart';
import '../../data/enum/content_type.enum.dart';
import '../../data/model/legal_content.model.dart';

/// Screen displaying rich legal content (Privacy Policy, Terms & Conditions, About Us, etc.)
/// Powered by [LegalContentBloc] and animated with [Skeletonizer] during loading.
class LegalContentScreen extends StatelessWidget {
  final ContentType type;

  const LegalContentScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LegalContentBloc()..add(LegalContentRequested(type)),
      child: _LegalContentView(type: type),
    );
  }
}

class _LegalContentView extends StatelessWidget {
  final ContentType type;

  const _LegalContentView({required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        title: type.label(context.l10n),
      ),
      body: BlocBuilder<LegalContentBloc, LegalContentState>(
        builder: (context, state) {
          final contentState = state.contentState;
          final isLoading = contentState.isLoading;

          if (contentState.isFailure) {
            return Center(
              child: Text(
                contentState.errorMessageOrNull ?? 'Failed to load content',
                style: context.textTheme.bodyMedium?.colour(
                  context.colors.error,
                ),
              ),
            );
          }

          // Use static fake data for Skeletonizer preview while loading
          final data =
              contentState.dataOrNull ?? LegalContentModel.staticContent(type);

          // If structured clauses exist, render as individual sleek cards with Skeletonizer
          if (data.clauses.isNotEmpty) {
            return Skeletonizer(
              enabled: isLoading,
              child: SingleChildScrollView(
                padding: context.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data.headerDescription != null) ...[
                      _HeaderCard(
                        title: data.id == 'master-service-governance'
                            ? 'Master Service Governance'
                            : data.title,
                        subtitle: data.subtitle,
                        description: data.headerDescription!,
                      ),
                      AppSpacing.md.h,
                    ],
                    ...data.clauses.map(
                      (clause) => Padding(
                        padding: AppSpacing.md.bPadding,
                        child: _ClauseCard(clause: clause),
                      ),
                    ),
                    AppSpacing.xl.h,
                  ],
                ),
              ),
            );
          }

          // Fallback to HTML widget
          return Skeletonizer(
            enabled: isLoading,
            child: SingleChildScrollView(
              padding: context.screenPadding,
              child: WrapperCard(
                child: Html(
                  data: data.contentHtml,
                  style: {
                    'body': Style(
                      color: context.colors.onSurface,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(14.0),
                      lineHeight: const LineHeight(1.6),
                    ),
                    'h2': Style(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: FontSize(18.0),
                      margin: Margins.only(top: 16, bottom: 8),
                    ),
                    'h3': Style(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: FontSize(16.0),
                      margin: Margins.only(top: 14, bottom: 6),
                    ),
                    'p': Style(
                      color: context.colors.onSurfaceVariant,
                      lineHeight: const LineHeight(1.5),
                      margin: Margins.only(bottom: 12),
                    ),
                    'strong': Style(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String description;

  const _HeaderCard({
    required this.title,
    this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return QuickContainer(
      p: AppSpacing.lg,
      radius: AppRadius.lg,
      color: context.colors.surfaceContainer.withValues(alpha: 0.72),
      border: Border.all(color: context.colors.outlineVariant, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuickContainer(
                w: 38,
                h: 38,
                radius: AppRadius.sm,
                color: context.colors.primary.withValues(alpha: 0.15),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.35),
                  width: 1,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.shield_rounded,
                  color: context.colors.primary,
                  size: 20,
                ),
              ),
              AppSpacing.md.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.bold().colour(
                        context.colors.primary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      AppSpacing.xxs.h,
                      Text(
                        subtitle!,
                        style: context.textTheme.labelSmall?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.md.h,
          _buildHighlightedDescription(context, description),
        ],
      ),
    );
  }

  Widget _buildHighlightedDescription(BuildContext context, String text) {
    const highlightWord = 'GuardUp Global';
    if (!text.contains(highlightWord)) {
      return Text(
        text,
        style: context.textTheme.bodySmall
            ?.lineHeight(1.5),
      );
    }

    final parts = text.split(highlightWord);
    return AppRichText(
      spans: [
        AppTextSpan(
          text: parts[0],
          style: context.textTheme.bodySmall
              ?.lineHeight(1.5),
        ),
        AppTextSpan(
          text: highlightWord,
          style: context.textTheme.bodySmall
              ?.bold()
              .colour(context.colors.primary)
              .lineHeight(1.5),
        ),
        if (parts.length > 1)
          AppTextSpan(
            text: parts[1],
            style: context.textTheme.bodySmall
                ?.lineHeight(1.5),
          ),
      ],
    );
  }
}

class _ClauseCard extends StatelessWidget {
  final LegalClause clause;

  const _ClauseCard({required this.clause});

  @override
  Widget build(BuildContext context) {
    return QuickContainer(
      p: AppSpacing.lg,
      radius: AppRadius.lg,
      color: context.colors.surfaceContainer.withValues(alpha: 0.72),
      border: Border.all(color: context.colors.outlineVariant, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                clause.clauseNumber,
                style: context.textTheme.labelSmall
                    ?.bold()
                    .colour(context.colors.primary)
                    .textSpacing(0.8),
              ),
              Text(
                clause.tag,
                style: context.textTheme.labelSmall?.colour(
                  context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppSpacing.xs.h,
          Text(
            clause.title,
            style: context.textTheme.titleMedium?.bold(),
          ),
          AppSpacing.sm.h,
          Text(
            clause.content,
            style: context.textTheme.bodySmall
                ?.colour(context.colors.onSurfaceVariant)
                .lineHeight(1.5),
          ),
        ],
      ),
    );
  }
}
