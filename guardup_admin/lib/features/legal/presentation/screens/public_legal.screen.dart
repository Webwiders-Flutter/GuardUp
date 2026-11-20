import 'package:flutter/material.dart';

import '/shared/widgets/misc/app_logo.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/enums/language.enum.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/legal/data/enums/content_type.enum.dart';
import '/features/legal/data/models/legal_content.model.dart';
import '/features/legal/di/legal_content.providers.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/editor/app_content_preview.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';

/// Public, unauthenticated view screen for platform legal policies, terms, and agreements.
///
/// Responsive and theme-compliant layout for viewing:
/// - Terms & Conditions
/// - Privacy Policy
/// - About Us
/// - Delete Account
/// - Support
///
/// Features dynamic selection across all [ContentType], [UserRoleType], and [LanguageType]
/// with synchronized browser URL routing, fast caching, and one-click link sharing.
class PublicLegalScreen extends ConsumerStatefulWidget {
  /// Prefix of every public (unauthenticated) legal page.
  static const pathPrefix = '/public';

  /// Route pattern of this screen.
  static const route = '$pathPrefix/:contentType/:role/:language';

  /// Relative location of a public legal page.
  static String location({
    ContentType contentType = ContentType.terms,
    UserRoleType role = UserRoleType.customer,
    LanguageType language = LanguageType.english,
  }) => '$pathPrefix/${contentType.slug}/${role.slug}/${language.code}';

  /// Absolute URL (with the current origin) of a public legal page, for
  /// sharing outside the console.
  static String fullUrl({
    ContentType contentType = ContentType.terms,
    UserRoleType role = UserRoleType.customer,
    LanguageType language = LanguageType.english,
  }) {
    final path = location(
      contentType: contentType,
      role: role,
      language: language,
    );
    return '${Uri.base.origin}$path';
  }

  final ContentType initialContentType;
  final UserRoleType initialRole;
  final LanguageType initialLanguage;

  const PublicLegalScreen({
    super.key,
    this.initialContentType = ContentType.terms,
    this.initialRole = UserRoleType.customer,
    this.initialLanguage = LanguageType.english,
  });

  @override
  ConsumerState<PublicLegalScreen> createState() => _PublicLegalScreenState();
}

class _PublicLegalScreenState extends ConsumerState<PublicLegalScreen> {
  late final ValueNotifier<ContentType> _contentTypeNotifier;
  late final ValueNotifier<UserRoleType> _roleNotifier;
  late final ValueNotifier<LanguageType> _languageNotifier;

  @override
  void initState() {
    super.initState();
    _contentTypeNotifier = ValueNotifier(widget.initialContentType);
    _roleNotifier = ValueNotifier(widget.initialRole);
    _languageNotifier = ValueNotifier(widget.initialLanguage);
  }

  @override
  void didUpdateWidget(covariant PublicLegalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialContentType != widget.initialContentType) {
      _contentTypeNotifier.value = widget.initialContentType;
    }
    if (oldWidget.initialRole != widget.initialRole) {
      _roleNotifier.value = widget.initialRole;
    }
    if (oldWidget.initialLanguage != widget.initialLanguage) {
      _languageNotifier.value = widget.initialLanguage;
    }
  }

  @override
  void dispose() {
    _contentTypeNotifier.dispose();
    _roleNotifier.dispose();
    _languageNotifier.dispose();
    super.dispose();
  }

  void _onSelectionChanged({
    ContentType? type,
    UserRoleType? role,
    LanguageType? language,
  }) {
    final nextType = type ?? _contentTypeNotifier.value;
    final nextRole = role ?? _roleNotifier.value;
    final nextLang = language ?? _languageNotifier.value;

    if (nextType == _contentTypeNotifier.value &&
        nextRole == _roleNotifier.value &&
        nextLang == _languageNotifier.value) {
      return;
    }

    _contentTypeNotifier.value = nextType;
    _roleNotifier.value = nextRole;
    _languageNotifier.value = nextLang;

    // Synchronize browser URL
    final targetPath = PublicLegalScreen.location(
      contentType: nextType,
      role: nextRole,
      language: nextLang,
    );
    context.go(targetPath);
  }

  void _copyCurrentLink() {
    final url = PublicLegalScreen.fullUrl(
      contentType: _contentTypeNotifier.value,
      role: _roleNotifier.value,
      language: _languageNotifier.value,
    );

    Clipboard.setData(ClipboardData(text: url));
    AppSnackbar.success('Public document link copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Enterprise Brand Navigation Header ────────────────────
            _buildTopBrandBar(context),

            // ── Main Responsive Document Viewer ───────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Document Header & Interactive Controls ──────
                        _buildDocumentHeroCard(context),

                        AppSpacing.xl.h,

                        // ── Live Document Content Body ──────────────────
                        _buildDocumentBody(context),

                        AppSpacing.xxl.h,

                        // ── Public Footer & Quick Navigation ────────────
                        _buildPublicFooter(context),
                      ],
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

  // ── Enterprise Brand Navigation Header ──────────────────────────────────────

  Widget _buildTopBrandBar(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.borderLight.withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              // Brand mark box & app name
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: (AppSpacing.md * 3) + 4),
                  AppSpacing.md.w,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'GuardUp Admin',
                            style: context.textTheme.titleMedium
                                ?.bold()
                                .colour(colors.primary)
                                .textSpacing(-0.2),
                          ),
                          AppSpacing.xs.w,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs + 2,
                              vertical: AppSpacing.xs / 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.secondary.withValues(alpha: 0.12),
                              borderRadius: AppRadius.xsRadius,
                            ),
                            child: Text(
                              'LEGAL',
                              style: context.textTheme.labelSmall
                                  ?.size(AppSpacing.sm + 2)
                                  .bold()
                                  .colour(colors.secondary),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Public Terms & Documentation',
                        style: context.textTheme.bodySmall
                            ?.size(AppSpacing.md)
                            .medium()
                            .colour(colors.onSurfaceSecondary),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // Quick Share / Copy Link Action
              AppButton(
                text: 'Share Link',
                type: ButtonType.secondaryOff,
                size: ButtonSize.small,
                fullWidth: false,
                leading: const Icon(Icons.link_rounded, size: AppSpacing.lg),
                onPressed: _copyCurrentLink,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Document Hero Card with In-Preview Ribbon Controls ───────────────────────

  Widget _buildDocumentHeroCard(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Role Platform Scope Selector
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROLE',
                  style: context.textTheme.labelSmall
                      ?.semiBold()
                      .colour(colors.onSurfaceSecondary)
                      .textSpacing(0.6),
                ),
                AppSpacing.xs.h,
                ValueListenableBuilder<UserRoleType>(
                  valueListenable: _roleNotifier,
                  builder: (context, activeRole, _) {
                    return Wrap(
                      spacing: AppSpacing.xs + 2,
                      runSpacing: AppSpacing.xs,
                      children: UserRoleType.platformRoles.map((role) {
                        final isSelected = role == activeRole;
                        return ChoiceChip(
                          selected: isSelected,
                          onSelected: (_) => _onSelectionChanged(role: role),
                          showCheckmark: false,
                          avatar: Icon(
                            role.icon,
                            size: AppSpacing.md + 2,
                            color: isSelected
                                ? colors.onPrimary
                                : colors.onSurfaceSecondary,
                          ),
                          label: Text(role.label(context.l10n)),
                          labelStyle: context.textTheme.bodySmall
                              ?.semiBold()
                              .colour(
                                isSelected
                                    ? colors.onPrimary
                                    : colors.onSurface,
                              ),
                          selectedColor: colors.secondary,
                          backgroundColor: colors.backgroundLight,
                          side: BorderSide(
                            color: isSelected
                                ? colors.secondary
                                : colors.borderLight,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xs / 2,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          AppSpacing.md.w,

          // Language Selector (English / Hindi)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'DOCUMENT LANGUAGE',
                style: context.textTheme.labelSmall
                    ?.semiBold()
                    .colour(colors.onSurfaceSecondary)
                    .textSpacing(0.6),
              ),
              AppSpacing.xs.h,
              ValueListenableBuilder<LanguageType>(
                valueListenable: _languageNotifier,
                builder: (context, activeLang, _) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.xs / 2),
                    decoration: BoxDecoration(
                      color: colors.backgroundLight,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: colors.borderLight.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: LanguageType.values.map((lang) {
                        final isSelected = lang == activeLang;
                        return InkWell(
                          onTap: () => _onSelectionChanged(language: lang),
                          borderRadius: AppRadius.smRadius,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs + 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primary
                                  : colors.transparent,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  lang.apiValue.toUpperCase(),
                                  style: context.textTheme.labelSmall
                                      ?.bold()
                                      .colour(
                                        isSelected
                                            ? colors.onPrimary
                                            : colors.onSurfaceSecondary,
                                      ),
                                ),
                                AppSpacing.xs.w,
                                Text(
                                  lang.nativeName,
                                  style: context.textTheme.bodySmall
                                      ?.semiBold()
                                      .colour(
                                        isSelected
                                            ? colors.onPrimary
                                            : colors.onSurface,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Document Body & Content Stream ──────────────────────────────────────────

  Widget _buildDocumentBody(BuildContext context) {
    return ValueListenableBuilder<ContentType>(
      valueListenable: _contentTypeNotifier,
      builder: (context, type, _) {
        return ValueListenableBuilder<UserRoleType>(
          valueListenable: _roleNotifier,
          builder: (context, role, _) {
            return ValueListenableBuilder<LanguageType>(
              valueListenable: _languageNotifier,
              builder: (context, lang, _) {
                final documentAsync = ref.watch(
                  legalContentByKeyProvider((
                    type: type,
                    role: role,
                    language: lang,
                  )),
                );

                return documentAsync.when(
                  loading: () => _buildLoadingSkeleton(context),
                  error: (error, _) => _buildErrorCard(context, error),
                  data: (model) => _buildDocumentView(context, model),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentView(BuildContext context, LegalContentModel model) {
    final colors = context.colors;
    final type = _contentTypeNotifier.value;
    final role = _roleNotifier.value;
    final language = _languageNotifier.value;

    final lastPublished = model.lastPublishedAt;
    final dateString = lastPublished != null
        ? 'Last updated on ${lastPublished.ddMMMMyyyy}'
        : 'Official Published Document';

    final headerMetaWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role & Language Tag Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: role.color(context).withValues(alpha: 0.12),
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: role.color(context).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    role.icon,
                    size: AppSpacing.md,
                    color: role.color(context),
                  ),
                  AppSpacing.xs.w,
                  Text(
                    role.label(context.l10n),
                    style: context.textTheme.labelSmall?.semiBold().colour(
                      role.color(context),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.sm.w,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.secondary.withValues(alpha: 0.12),
                borderRadius: AppRadius.smRadius,
              ),
              child: Text(
                language.nativeName,
                style: context.textTheme.labelSmall?.semiBold().colour(
                  colors.secondary,
                ),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.schedule_rounded,
              size: AppSpacing.md,
              color: colors.onSurfaceSecondary,
            ),
            AppSpacing.xs.w,
            Text(
              dateString,
              style: context.textTheme.bodySmall?.colour(
                colors.onSurfaceSecondary,
              ),
            ),
          ],
        ),

        AppSpacing.md.h,

        // Big Title
        Text(
          type.label,
          style: context.textTheme.headlineMedium?.bold().textSpacing(-0.4),
        ),

        AppSpacing.lg.h,
        Divider(color: colors.borderLight.withValues(alpha: 0.7), height: 1),
      ],
    );

    return AppContentPreview(
      html: model.contentHtml,
      header: headerMetaWidget,
      emptyTitle: 'Document Under Preparation',
      emptyMessage:
          'The ${type.label} for ${role.label(context.l10n)} in ${language.nativeName} is currently being updated by the legal team. Please check back shortly.',
      maxWidth: 960.0,
      isCard: true,
    );
  }

  // ── Skeleton & Error States ─────────────────────────────────────────────────

  Widget _buildLoadingSkeleton(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: AppSpacing.xxl + AppSpacing.md,
            width: AppSpacing.xxl + AppSpacing.md,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          AppSpacing.lg.h,
          Text(
            'Retrieving Official Document...',
            style: context.textTheme.titleSmall?.semiBold().colour(
              colors.onSurface,
            ),
          ),
          AppSpacing.xs.h,
          Text(
            'Fetching latest verified policies from the platform repository.',
            style: context.textTheme.bodySmall?.colour(
              colors.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: AppSpacing.xxxl,
            color: colors.error,
          ),
          AppSpacing.md.h,
          Text(
            'Unable to Load Document',
            style: context.textTheme.titleMedium?.semiBold().colour(
              colors.onSurface,
            ),
          ),
          AppSpacing.xs.h,
          Text(
            'There was an error communicating with the document server. Please try again.',
            style: context.textTheme.bodySmall?.colour(
              colors.onSurfaceSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.lg.h,
          AppButton(
            text: 'Retry Loading',
            type: ButtonType.secondaryOff,
            size: ButtonSize.small,
            fullWidth: false,
            leading: const Icon(Icons.refresh_rounded, size: AppSpacing.lg),
            onPressed: () {
              ref.invalidate(
                legalContentByKeyProvider((
                  type: _contentTypeNotifier.value,
                  role: _roleNotifier.value,
                  language: _languageNotifier.value,
                )),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Public Footer & Cross-links ─────────────────────────────────────────────

  Widget _buildPublicFooter(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: colors.borderLight.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '© ${DateTime.now().year} GuardUp. All rights reserved.',
                style: context.textTheme.bodySmall?.colour(
                  colors.onSurfaceSecondary,
                ),
              ),
              AppSpacing.md.w,
              Text(
                '•',
                style: context.textTheme.bodySmall?.colour(colors.borderDark),
              ),
              AppSpacing.md.w,
              Text(
                'Official Regulatory Documentation',
                style: context.textTheme.bodySmall?.colour(
                  colors.onSurfaceSecondary,
                ),
              ),
            ],
          ),
          AppSpacing.sm.h,
          Text(
            'Questions or concerns regarding our platform terms? Contact compliance@guardup.com',
            style: context.textTheme.labelSmall?.colour(
              colors.onSurfaceSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
