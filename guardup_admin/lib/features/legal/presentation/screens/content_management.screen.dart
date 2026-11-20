import 'package:guardup_admin/shared/widgets/editor/app_content_editor.dart';
import 'package:guardup_admin/shared/widgets/editor/app_content_editor_controller.dart';

import '/core/error/api_exception.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/localization.extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../../../users/data/enums/user_role.enum.dart';
import '/features/legal/data/enums/content_type.enum.dart';
import '/features/legal/data/models/legal_content.model.dart';
import '/features/legal/di/legal_content.providers.dart';
import '/features/legal/presentation/controllers/legal_content.controller.dart';

import 'package:flutter/services.dart';

import '/core/enums/language.enum.dart';
import '/shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedbacks/widgets/app_popup.dart';
import '../../../../shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/features/legal/presentation/screens/public_legal.screen.dart';

class ContentManagementScreen extends ConsumerStatefulWidget {
  /// Base route (redirects to the Terms page).
  static const route = '/content';

  /// `/content/<type>`, e.g. `/content/privacy-policy`.
  static String location(ContentType type) => '$route/${type.slug}';

  final ContentType initialType;

  const ContentManagementScreen({
    super.key,
    this.initialType = ContentType.terms,
  });

  @override
  ConsumerState<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState
    extends ConsumerState<ContentManagementScreen> {
  ProviderListenable<AsyncValue<LegalContentModel?>> get provider =>
      legalContentControllerProvider;
  LegalContentController get controller =>
      ref.read(legalContentControllerProvider.notifier);

  late final ValueNotifier<ContentType> _selectedTypeNotifier;
  final ValueNotifier<UserRoleType> _selectedRoleNotifier = ValueNotifier(
    UserRoleType.customer,
  );
  final ValueNotifier<LanguageType> _selectedLanguageNotifier = ValueNotifier(
    LanguageType.english,
  );
  final ValueNotifier<bool> _hasUnsavedChangesNotifier = ValueNotifier(false);

  late final AppContentEditorController _editorController;
  String _lastSavedHtml = '';

  @override
  void initState() {
    super.initState();
    _selectedTypeNotifier = ValueNotifier(widget.initialType);
    _editorController = AppContentEditorController();
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      // Initial load for starting selection
      _loadDocumentContent(
        type: _selectedTypeNotifier.value,
        role: _selectedRoleNotifier.value,
        language: _selectedLanguageNotifier.value,
        preserveUnsaved: false,
      );
    });

    _editorController.addListener(_onEditorContentChanged);
  }

  @override
  void didUpdateWidget(covariant ContentManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialType != widget.initialType ||
        widget.initialType != _selectedTypeNotifier.value) {
      _applySwitch(
        widget.initialType,
        _selectedRoleNotifier.value,
        _selectedLanguageNotifier.value,
      );
    }
  }

  @override
  void dispose() {
    _editorController.removeListener(_onEditorContentChanged);
    _editorController.dispose();
    _selectedTypeNotifier.dispose();
    _selectedRoleNotifier.dispose();
    _selectedLanguageNotifier.dispose();
    _hasUnsavedChangesNotifier.dispose();
    super.dispose();
  }

  // ── Document Loading & Change Tracking ──────────────────────────────────────

  Future<void> _loadDocumentContent({
    required ContentType type,
    required UserRoleType role,
    required LanguageType language,
    required bool preserveUnsaved,
  }) async {
    try {
      final model = await controller.getContent(
        type: type,
        role: role,
        language: language,
      );

      _lastSavedHtml = model.contentHtml.trim();
      _editorController.removeListener(_onEditorContentChanged);

      _editorController.setHtml(model.contentHtml);
      _hasUnsavedChangesNotifier.value = false;
      _editorController.addListener(_onEditorContentChanged);
    } catch (e) {
      if (e is ApiException) {
        AppSnackbar.error(e.message);
        return;
      }
      if (mounted) {
        AppSnackbar.error('Failed to load document content: $e');
      }
    }
  }

  void _onEditorContentChanged() {
    final currentHtml = _editorController.toHtml().trim();
    final isModified = currentHtml != _lastSavedHtml;
    if (_hasUnsavedChangesNotifier.value != isModified) {
      _hasUnsavedChangesNotifier.value = isModified;
    }
  }

  // ── Safe Switching with Unsaved Changes Guard ───────────────────────────────

  Future<void> _requestSwitch({
    ContentType? targetType,
    UserRoleType? targetRole,
    LanguageType? targetLanguage,
  }) async {
    final newType = targetType ?? _selectedTypeNotifier.value;
    final newRole = targetRole ?? _selectedRoleNotifier.value;
    final newLanguage = targetLanguage ?? _selectedLanguageNotifier.value;

    // If identical target, do nothing
    if (newType == _selectedTypeNotifier.value &&
        newRole == _selectedRoleNotifier.value &&
        newLanguage == _selectedLanguageNotifier.value) {
      return;
    }

    // If no unsaved changes, switch immediately
    if (!_hasUnsavedChangesNotifier.value) {
      _applySwitch(newType, newRole, newLanguage);
      return;
    }

    // Prompt user to save first or force switch
    final currentDocName =
        '${_selectedTypeNotifier.value.label} (${_selectedRoleNotifier.value.label(context.l10n)} - ${_selectedLanguageNotifier.value.nativeName})';

    final result = await AppPopup.show(
      context: context,
      title: 'Unsaved Changes Detected',
      message:
          'You have unsaved changes in "$currentDocName". Please save and publish your modifications first, or force switch to discard your changes.',
      variant: PopupVariant.warning,
      icon: Icons.warning_amber_rounded,
      buttons: [
        AppButton(
          text: 'Cancel',
          type: ButtonType.secondaryOff,
          onPressed: () =>
              context.pop(const PopupResult(action: PopupAction.dismiss)),
        ),
        AppButton(
          text: 'Force Switch',
          type: ButtonType.danger,
          leading: const Icon(Icons.swap_horiz_rounded, size: AppSpacing.lg),
          onPressed: () =>
              context.pop(const PopupResult(action: PopupAction.cancel)),
        ),
        AppButton(
          text: 'Publish & Switch',
          type: ButtonType.primary,
          leading: const Icon(Icons.publish_rounded, size: AppSpacing.lg),
          onPressed: () =>
              context.pop(const PopupResult(action: PopupAction.confirm)),
        ),
      ],
    );

    if (result == null || result.action == PopupAction.dismiss) {
      // User cancelled: keep current document and edits
      return;
    }

    if (result.action == PopupAction.confirm) {
      // User chose to publish current changes first
      await _executePublish();
    }

    // Perform switch (either forced or after successful publish)
    _applySwitch(newType, newRole, newLanguage);
  }

  void _applySwitch(
    ContentType newType,
    UserRoleType newRole,
    LanguageType newLanguage,
  ) {
    _selectedTypeNotifier.value = newType;
    _selectedRoleNotifier.value = newRole;
    _selectedLanguageNotifier.value = newLanguage;

    _loadDocumentContent(
      type: newType,
      role: newRole,
      language: newLanguage,
      preserveUnsaved: false,
    );
  }

  // ── Publish Action ──────────────────────────────────────────────────────────

  Future<void> _handlePublish() async {
    final type = _selectedTypeNotifier.value;
    final role = _selectedRoleNotifier.value;
    final language = _selectedLanguageNotifier.value;
    final docTitle =
        '${type.label} for ${role.label(context.l10n)} (${language.nativeName})';

    final confirm = await AppPopup.show(
      context: context,
      title: 'Publish $docTitle?',
      message:
          'This will publish these changes live across the platform for all ${role.label(context.l10n)} users viewing in ${language.nativeName}.',
      variant: PopupVariant.info,
      icon: Icons.publish_rounded,
      buttons: [
        AppButton(
          text: 'Cancel',
          type: ButtonType.secondaryOff,
          onPressed: () =>
              context.pop(const PopupResult(action: PopupAction.cancel)),
        ),
        AppButton(
          text: 'Confirm & Publish',
          type: ButtonType.primary,
          leading: const Icon(
            Icons.check_circle_outline_rounded,
            size: AppSpacing.lg,
          ),
          onPressed: () =>
              context.pop(const PopupResult(action: PopupAction.confirm)),
        ),
      ],
    );

    if (confirm?.action != PopupAction.confirm) return;

    await _executePublish();
  }

  Future<void> _executePublish() async {
    final type = _selectedTypeNotifier.value;
    final role = _selectedRoleNotifier.value;
    final language = _selectedLanguageNotifier.value;
    final html = _editorController.toHtml();

    try {
      final updated = await controller.publishContent(
        type: type,
        role: role,
        language: language,
        contentHtml: html,
      );

      if (!mounted) return;

      _lastSavedHtml = updated.contentHtml.trim();
      _hasUnsavedChangesNotifier.value = false;

      AppSnackbar.success(
        '${type.label} published successfully for ${role.label(context.l10n)} (${language.nativeName})!',
      );
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException) {
        AppSnackbar.error(e.message);
        return;
      }
      AppSnackbar.error('Failed to publish content. Please try again.');
    }
  }

  // ── Build Method ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLoading = ref.watch(provider.select((value) => value.isLoading));

    return Scaffold(
      backgroundColor: colors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Bar ──────────────────────────────────────────
              _buildTopHeader(colors, isLoading),

              AppSpacing.xl.h,

              // ── Role & Language Target Scopes ────────────────────────
              _buildScopeControlsCard(colors, isLoading),

              AppSpacing.lg.h,

              // ── Rich Content Editor ──────────────────────────────────
              ValueListenableBuilder<ContentType>(
                valueListenable: _selectedTypeNotifier,
                builder: (context, selectedType, _) {
                  return ValueListenableBuilder<UserRoleType>(
                    valueListenable: _selectedRoleNotifier,
                    builder: (context, selectedRole, _) {
                      return ValueListenableBuilder<LanguageType>(
                        valueListenable: _selectedLanguageNotifier,
                        builder: (context, selectedLanguage, _) {
                          return AppContentEditor(
                            key: ValueKey(
                              '${selectedType.name}_${selectedRole.name}_${selectedLanguage.code}',
                            ),
                            controller: _editorController,
                            title:
                                '${selectedType.label} — ${selectedRole.label(context.l10n)} [${selectedLanguage.nativeName}]',
                            minHeight: 560,
                            showStatusBar: true,
                            showToolbar: true,
                            isLoading: isLoading,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Header with Only Publish Button & Unsaved Indicator ─────────────────

  Widget _buildTopHeader(dynamic colors, bool isLoading) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ValueListenableBuilder<ContentType>(
            valueListenable: _selectedTypeNotifier,
            builder: (context, selectedType, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedType.label,
                    style: context.textTheme.headlineSmall?.bold().colour(
                      colors.onSurface,
                    ),
                  ),
                  (AppSpacing.xs / 2).h,
                  Text(
                    'Manage ${selectedType.label} for each user role and language.',
                    style: context.textTheme.bodyMedium?.colour(
                      colors.onSurfaceSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        AppSpacing.md.w,

        // Live Unsaved / Published Status Indicator
        ValueListenableBuilder<bool>(
          valueListenable: _hasUnsavedChangesNotifier,
          builder: (context, hasUnsaved, _) {
            if (hasUnsaved) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: colors.warningLight,
                  borderRadius: AppRadius.fullRadius,
                  border: Border.all(
                    color: colors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: AppSpacing.sm,
                      height: AppSpacing.sm,
                      decoration: BoxDecoration(
                        color: colors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppSpacing.xs.w,
                    Text(
                      'Unsaved Changes',
                      style: context.textTheme.bodySmall?.semiBold().colour(
                        colors.warning,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Consumer(
              builder: (context, ref, _) {
                final lastPublishedAt = ref.watch(
                  provider.select((value) => value.value?.lastPublishedAt),
                );
                final timeText = lastPublishedAt != null
                    ? lastPublishedAt.timeAgo
                    : 'Up to date';

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.successLight,
                    borderRadius: AppRadius.fullRadius,
                    border: Border.all(
                      color: colors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: AppSpacing.md + 2,
                        color: colors.success,
                      ),
                      AppSpacing.xs.w,
                      Text(
                        'Published ($timeText)',
                        style: context.textTheme.bodySmall?.medium().colour(
                          colors.success,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        AppSpacing.md.w,

        // Only Publish Button (with unsaved changes visual cue)
        ValueListenableBuilder<bool>(
          valueListenable: _hasUnsavedChangesNotifier,
          builder: (context, hasUnsaved, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                AppButton(
                  text: hasUnsaved ? 'Publish Changes *' : 'Publish',
                  type: hasUnsaved
                      ? ButtonType.primary
                      : ButtonType.secondaryOff,
                  size: ButtonSize.normal,
                  fullWidth: false,
                  leading: Icon(
                    hasUnsaved
                        ? Icons.cloud_upload_rounded
                        : Icons.check_circle_outline_rounded,
                    size: AppSpacing.lg,
                  ),
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handlePublish,
                ),
                if (hasUnsaved)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: AppSpacing.sm + 2,
                      height: AppSpacing.sm + 2,
                      decoration: BoxDecoration(
                        color: colors.warning,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildScopeControlsCard(dynamic colors, bool isLoading) {
    return IgnorePointer(
      ignoring: isLoading,
      child: QuickContainer(
        p: AppSpacing.md,
        radius: AppRadius.md,
        color: colors.surface,
        border: Border.all(color: colors.borderLight.withValues(alpha: 0.7)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Role Selection (Admin removed) ─────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.supervised_user_circle_outlined,
                            size: AppSpacing.md + 2,
                            color: colors.onSurfaceSecondary,
                          ),
                          AppSpacing.xs.w,
                          Text(
                            'TARGET USER ROLE',
                            style: context.textTheme.labelSmall
                                ?.semiBold()
                                .colour(colors.onSurfaceSecondary)
                                .textSpacing(0.8),
                          ),
                        ],
                      ),
                      AppSpacing.xs.h,
                      ValueListenableBuilder<UserRoleType>(
                        valueListenable: _selectedRoleNotifier,
                        builder: (context, selectedRole, _) {
                          return Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: UserRoleType.values
                                .where((x) => !x.isAdmin)
                                .map((role) {
                                  final isSelected = role == selectedRole;
                                  return ChoiceChip(
                                    selected: isSelected,
                                    onSelected: (val) {
                                      if (val) _requestSwitch(targetRole: role);
                                    },
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
                                    selectedColor: colors.primary,
                                    backgroundColor: colors.backgroundLight,
                                    side: BorderSide(
                                      color: isSelected
                                          ? colors.primary
                                          : colors.borderLight,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: AppSpacing.xs / 2,
                                    ),
                                  );
                                })
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: SizedBox(
                    height: (AppSpacing.xxl * 2) - AppSpacing.xs,
                    child: VerticalDivider(
                      color: colors.borderLight.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                ),

                // ── Language Selection (English / Hindi) ───────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.translate_rounded,
                          size: AppSpacing.md + 2,
                          color: colors.onSurfaceSecondary,
                        ),
                        AppSpacing.xs.w,
                        Text(
                          'DOCUMENT LANGUAGE',
                          style: context.textTheme.labelSmall
                              ?.semiBold()
                              .colour(colors.onSurfaceSecondary)
                              .textSpacing(0.8),
                        ),
                      ],
                    ),
                    AppSpacing.xs.h,
                    ValueListenableBuilder<LanguageType>(
                      valueListenable: _selectedLanguageNotifier,
                      builder: (context, selectedLanguage, _) {
                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: LanguageType.values.map((language) {
                            final isSelected = language == selectedLanguage;
                            return ChoiceChip(
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  _requestSwitch(targetLanguage: language);
                                }
                              },
                              showCheckmark: false,
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    language.apiValue,
                                    style: context.textTheme.labelSmall
                                        ?.bold()
                                        .colour(
                                          isSelected
                                              ? colors.white
                                              : colors.onSurfaceSecondary,
                                        ),
                                  ),
                                  AppSpacing.xs.w,
                                  Text(
                                    language.nativeName,
                                    style: context.textTheme.bodySmall
                                        ?.semiBold()
                                        .colour(
                                          isSelected
                                              ? colors.white
                                              : colors.onSurface,
                                        ),
                                  ),
                                ],
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
              ],
            ),

            AppSpacing.md.h,
            Divider(
              color: colors.borderLight.withValues(alpha: 0.6),
              height: 1,
            ),
            AppSpacing.sm.h,

            // ── Dynamic Live Public Link Bar ───────────────────────
            ValueListenableBuilder<ContentType>(
              valueListenable: _selectedTypeNotifier,
              builder: (context, type, _) {
                return ValueListenableBuilder<UserRoleType>(
                  valueListenable: _selectedRoleNotifier,
                  builder: (context, role, _) {
                    return ValueListenableBuilder<LanguageType>(
                      valueListenable: _selectedLanguageNotifier,
                      builder: (context, lang, _) {
                        final relativePath = PublicLegalScreen.location(
                          contentType: type,
                          role: role,
                          language: lang,
                        );
                        final fullUrl = PublicLegalScreen.fullUrl(
                          contentType: type,
                          role: role,
                          language: lang,
                        );

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.backgroundLight.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: AppRadius.smRadius,
                            border: Border.all(
                              color: colors.borderLight.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.public_rounded,
                                size: AppSpacing.md + 2,
                                color: colors.secondary,
                              ),
                              AppSpacing.xs.w,
                              Text(
                                'Public URL:',
                                style: context.textTheme.labelSmall?.semiBold(),
                              ),
                              AppSpacing.xs.w,
                              Expanded(
                                child: SelectableText(
                                  fullUrl,
                                  style: context.textTheme.bodySmall
                                      ?.colour(colors.onSurfaceSecondary)
                                      .size(AppSpacing.md - 2),
                                  maxLines: 1,
                                ),
                              ),
                              AppSpacing.sm.w,
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: fullUrl),
                                  );
                                  AppSnackbar.success(
                                    'Public URL copied to clipboard: $relativePath',
                                  );
                                },
                                borderRadius: AppRadius.xsRadius,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs + 2,
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.copy_rounded,
                                        size: AppSpacing.md,
                                        color: colors.secondary,
                                      ),
                                      AppSpacing.xs.w,
                                      Text(
                                        'Copy Link',
                                        style: context.textTheme.labelSmall
                                            ?.semiBold()
                                            .colour(colors.secondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
