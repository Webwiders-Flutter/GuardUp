import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/localization.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';

/// Semantic state types supported by [AppStateView].
enum AppViewType { empty, error, loading, noResults, offline, unauthorized }

/// Visual configuration record for an [AppViewType].
typedef _ViewStateConfig = ({
  IconData defaultIcon,
  Color Function(BuildContext) defaultColor,
  Color Function(BuildContext) defaultBackgroundColor,
  String Function(BuildContext) defaultMessage,
  String? Function(BuildContext) defaultSubtitle,
  String? Function(BuildContext) defaultActionText,
  IconData? defaultActionIcon,
  ButtonType actionButtonType,
});

/// A modern, versatile, and polished state view for empty, error,
/// loading, search results, offline, and permission states.
class AppStateView extends StatelessWidget {
  final AppViewType type;
  final String? message;
  final String? subtitle;
  final IconData? icon;
  final String? lottieAsset;
  final double? lottieWidth;
  final bool repeat;
  final Widget? customIllustration;
  final VoidCallback? onAction;
  final String? actionText;
  final IconData? actionIcon;
  final bool showActionIcon;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;
  final IconData? secondaryActionIcon;
  final bool isCompact;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const AppStateView({
    super.key,
    this.type = AppViewType.empty,
    this.message,
    this.subtitle,
    this.icon,
    this.lottieAsset,
    this.lottieWidth,
    this.repeat = true,
    this.customIllustration,
    this.onAction,
    this.actionText,
    this.actionIcon,
    this.showActionIcon = true,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.secondaryActionIcon,
    this.isCompact = false,
    this.padding,
    this.maxWidth,
    this.iconColor,
    this.iconBackgroundColor,
  }) : assert(
         icon == null || lottieAsset == null,
         'Provide either icon or lottieAsset, not both.',
       ),
       assert(
         customIllustration == null || (icon == null && lottieAsset == null),
         'Provide only one visual element (icon, lottieAsset, or customIllustration).',
       );

  /// Empty state view
  const AppStateView.empty({
    super.key,
    this.message,
    this.subtitle,
    this.icon,
    this.lottieAsset,
    this.lottieWidth,
    this.repeat = true,
    this.customIllustration,
    this.onAction,
    this.actionText,
    this.actionIcon,
    this.showActionIcon = true,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.secondaryActionIcon,
    this.isCompact = false,
    this.padding,
    this.maxWidth,
    this.iconColor,
    this.iconBackgroundColor,
  }) : type = AppViewType.empty,
       assert(
         icon == null || lottieAsset == null,
         'Provide either icon or lottieAsset, not both.',
       ),
       assert(
         customIllustration == null || (icon == null && lottieAsset == null),
         'Provide only one visual element (icon, lottieAsset, or customIllustration).',
       );

  /// Error state view
  const AppStateView.error({
    super.key,
    this.message,
    this.subtitle,
    this.icon,
    this.lottieAsset,
    this.lottieWidth,
    this.repeat = true,
    this.customIllustration,
    this.onAction,
    this.actionText,
    this.actionIcon,
    this.showActionIcon = true,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.secondaryActionIcon,
    this.isCompact = false,
    this.padding,
    this.maxWidth,
    this.iconColor,
    this.iconBackgroundColor,
  }) : type = AppViewType.error,
       assert(
         icon == null || lottieAsset == null,
         'Provide either icon or lottieAsset, not both.',
       ),
       assert(
         customIllustration == null || (icon == null && lottieAsset == null),
         'Provide only one visual element (icon, lottieAsset, or customIllustration).',
       );

  /// Loading state view
  const AppStateView.loading({
    super.key,
    this.message,
    this.subtitle,
    this.icon,
    this.lottieAsset,
    this.lottieWidth,
    this.repeat = true,
    this.customIllustration,
    this.onAction,
    this.actionText,
    this.actionIcon,
    this.showActionIcon = true,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.secondaryActionIcon,
    this.isCompact = false,
    this.padding,
    this.maxWidth,
    this.iconColor,
    this.iconBackgroundColor,
  }) : type = AppViewType.loading,
       assert(
         icon == null || lottieAsset == null,
         'Provide either icon or lottieAsset, not both.',
       ),
       assert(
         customIllustration == null || (icon == null && lottieAsset == null),
         'Provide only one visual element (icon, lottieAsset, or customIllustration).',
       );

  /// No search results view
  const AppStateView.noResults({
    super.key,
    this.message,
    this.subtitle,
    this.icon,
    this.lottieAsset,
    this.lottieWidth,
    this.repeat = true,
    this.customIllustration,
    this.onAction,
    this.actionText,
    this.actionIcon,
    this.showActionIcon = true,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.secondaryActionIcon,
    this.isCompact = false,
    this.padding,
    this.maxWidth,
    this.iconColor,
    this.iconBackgroundColor,
  }) : type = AppViewType.noResults,
       assert(
         icon == null || lottieAsset == null,
         'Provide either icon or lottieAsset, not both.',
       ),
       assert(
         customIllustration == null || (icon == null && lottieAsset == null),
         'Provide only one visual element (icon, lottieAsset, or customIllustration).',
       );

  /// Offline / connection lost state view
  const AppStateView.offline({
    super.key,
    this.message,
    this.subtitle,
    this.icon,
    this.lottieAsset,
    this.lottieWidth,
    this.repeat = true,
    this.customIllustration,
    this.onAction,
    this.actionText,
    this.actionIcon,
    this.showActionIcon = true,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.secondaryActionIcon,
    this.isCompact = false,
    this.padding,
    this.maxWidth,
    this.iconColor,
    this.iconBackgroundColor,
  }) : type = AppViewType.offline,
       assert(
         icon == null || lottieAsset == null,
         'Provide either icon or lottieAsset, not both.',
       ),
       assert(
         customIllustration == null || (icon == null && lottieAsset == null),
         'Provide only one visual element (icon, lottieAsset, or customIllustration).',
       );

  /// Unauthorized / forbidden state view
  const AppStateView.unauthorized({
    super.key,
    this.message,
    this.subtitle,
    this.icon,
    this.lottieAsset,
    this.lottieWidth,
    this.repeat = true,
    this.customIllustration,
    this.onAction,
    this.actionText,
    this.actionIcon,
    this.showActionIcon = true,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.secondaryActionIcon,
    this.isCompact = false,
    this.padding,
    this.maxWidth,
    this.iconColor,
    this.iconBackgroundColor,
  }) : type = AppViewType.unauthorized,
       assert(
         icon == null || lottieAsset == null,
         'Provide either icon or lottieAsset, not both.',
       ),
       assert(
         customIllustration == null || (icon == null && lottieAsset == null),
         'Provide only one visual element (icon, lottieAsset, or customIllustration).',
       );

  static final Map<AppViewType, _ViewStateConfig> _configs = {
    AppViewType.empty: (
      defaultIcon: Icons.inventory_2_outlined,
      defaultColor: (ctx) => ctx.colors.primary,
      defaultBackgroundColor: (ctx) =>
          ctx.colors.primary.withValues(alpha: 0.1),
      defaultMessage: (ctx) => ctx.l10n.noDataFound,
      defaultSubtitle: (ctx) => ctx.l10n.tryRefreshingOrCheckBackLater,
      defaultActionText: (ctx) => ctx.l10n.refresh,
      defaultActionIcon: Icons.refresh_rounded,
      actionButtonType: ButtonType.secondaryPrimary,
    ),
    AppViewType.error: (
      defaultIcon: Icons.error_outline_rounded,
      defaultColor: (ctx) => ctx.colors.error,
      defaultBackgroundColor: (ctx) => ctx.colors.errorLight,
      defaultMessage: (ctx) => ctx.l10n.somethingWentWrong,
      defaultSubtitle: (ctx) => ctx.l10n.pleaseTryAgain,
      defaultActionText: (ctx) => ctx.l10n.retry,
      defaultActionIcon: Icons.replay_rounded,
      actionButtonType: ButtonType.danger,
    ),
    AppViewType.loading: (
      defaultIcon: Icons.hourglass_empty_rounded,
      defaultColor: (ctx) => ctx.colors.primary,
      defaultBackgroundColor: (ctx) =>
          ctx.colors.primary.withValues(alpha: 0.08),
      defaultMessage: (ctx) => 'Loading…',
      defaultSubtitle: (ctx) => null,
      defaultActionText: (ctx) => null,
      defaultActionIcon: null,
      actionButtonType: ButtonType.primary,
    ),
    AppViewType.noResults: (
      defaultIcon: Icons.search_off_rounded,
      defaultColor: (ctx) => ctx.colors.info,
      defaultBackgroundColor: (ctx) => ctx.colors.infoLight,
      defaultMessage: (ctx) => 'No matching results',
      defaultSubtitle: (ctx) => 'Try adjusting your search terms or filters',
      defaultActionText: (ctx) => 'Clear filters',
      defaultActionIcon: Icons.filter_alt_off_rounded,
      actionButtonType: ButtonType.secondaryPrimary,
    ),
    AppViewType.offline: (
      defaultIcon: Icons.wifi_off_rounded,
      defaultColor: (ctx) => ctx.colors.warning,
      defaultBackgroundColor: (ctx) => ctx.colors.warningLight,
      defaultMessage: (ctx) => ctx.l10n.noInternetConnection,
      defaultSubtitle: (ctx) =>
          'Please check your network connection and try again',
      defaultActionText: (ctx) => ctx.l10n.retry,
      defaultActionIcon: Icons.refresh_rounded,
      actionButtonType: ButtonType.primary,
    ),
    AppViewType.unauthorized: (
      defaultIcon: Icons.lock_outline_rounded,
      defaultColor: (ctx) => ctx.colors.warning,
      defaultBackgroundColor: (ctx) => ctx.colors.warningLight,
      defaultMessage: (ctx) => 'Access Restricted',
      defaultSubtitle: (ctx) =>
          'You do not have permission to view this content',
      defaultActionText: (ctx) => ctx.l10n.goBack,
      defaultActionIcon: Icons.arrow_back_rounded,
      actionButtonType: ButtonType.secondaryPrimary,
    ),
  };

  /// Reading width of the message block.
  static const double _maxWidth = 440;
  static const double _compactMaxWidth = 360;

  /// Side of the square icon tile.
  static const double _tileSize = 64;
  static const double _compactTileSize = 48;

  /// Default Lottie widths.
  static const double _lottieWidth = 200;
  static const double _compactLottieWidth = 140;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final config = _configs[type]!;

    final resolvedMessage = message ?? config.defaultMessage(context);
    final resolvedSubtitle = subtitle ?? config.defaultSubtitle(context);
    final resolvedActionText = actionText ?? config.defaultActionText(context);
    final resolvedActionIcon = showActionIcon
        ? (actionIcon ?? config.defaultActionIcon)
        : null;

    final resolvedPadding =
        padding ??
        (isCompact
            ? const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              )
            : const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xxxl,
              ));

    return Center(
      child: SingleChildScrollView(
        padding: resolvedPadding,
        child: TweenAnimationBuilder<double>(
          duration: AppDurations.medium,
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, progress, child) => Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, (1 - progress) * AppSpacing.sm),
              child: child,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? (isCompact ? _compactMaxWidth : _maxWidth),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildVisualElement(context, config),
                (isCompact ? AppSpacing.md : AppSpacing.lg).h,
                if (resolvedMessage.isNotEmpty)
                  Text(
                    resolvedMessage,
                    textAlign: TextAlign.center,
                    style:
                        (isCompact
                                ? context.textTheme.titleSmall
                                : context.textTheme.titleMedium)
                            ?.semiBold()
                            .textSpacing(-0.2)
                            .colour(colors.onSurface),
                  ),
                if (resolvedSubtitle != null &&
                    resolvedSubtitle.isNotEmpty) ...[
                  (isCompact ? AppSpacing.xs : AppSpacing.sm - 2).h,
                  Text(
                    resolvedSubtitle,
                    textAlign: TextAlign.center,
                    style:
                        (isCompact
                                ? context.textTheme.bodySmall
                                : context.textTheme.bodyMedium)
                            ?.lineHeight(1.5)
                            .colour(colors.onSurfaceSecondary),
                  ),
                ],
                _buildActionButtons(
                  context,
                  config,
                  primaryText: resolvedActionText,
                  primaryIcon: resolvedActionIcon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualElement(BuildContext context, _ViewStateConfig config) {
    if (customIllustration != null) return customIllustration!;

    if (lottieAsset != null) {
      return SizedBox(
        width: lottieWidth ?? (isCompact ? _compactLottieWidth : _lottieWidth),
        child: Lottie.asset(lottieAsset!, repeat: repeat),
      );
    }

    return _buildIconTile(context, config);
  }

  /// Rounded-square tile tinted with the state's semantic color.
  Widget _buildIconTile(BuildContext context, _ViewStateConfig config) {
    final accent = iconColor ?? config.defaultColor(context);
    final fill = iconBackgroundColor ?? config.defaultBackgroundColor(context);
    final tileSize = isCompact ? _compactTileSize : _tileSize;
    final iconSize = isCompact
        ? AppLayout.iconXl
        : AppLayout.iconXl + AppSpacing.sm;

    return QuickContainer(
      w: tileSize,
      h: tileSize,
      alignment: Alignment.center,
      radius: isCompact ? AppRadius.md : AppRadius.lg,
      color: fill,
      border: Border.all(color: accent.withValues(alpha: 0.2)),
      child: type == AppViewType.loading
          ? SizedBox.square(
              dimension: iconSize - AppSpacing.xs,
              child: CircularProgressIndicator(
                strokeWidth: isCompact ? 2.5 : 3,
                strokeCap: StrokeCap.round,
                color: accent,
              ),
            )
          : Icon(icon ?? config.defaultIcon, size: iconSize, color: accent),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    _ViewStateConfig config, {
    required String? primaryText,
    required IconData? primaryIcon,
  }) {
    final hasPrimary = onAction != null && primaryText != null;
    final hasSecondary =
        onSecondaryAction != null && secondaryActionText != null;

    if (!hasPrimary && !hasSecondary) return const SizedBox.shrink();

    final buttonSize = isCompact ? ButtonSize.small : ButtonSize.normal;
    final buttonIconSize = isCompact ? AppLayout.iconSm : AppLayout.iconMd;

    return Padding(
      padding: (isCompact ? AppSpacing.lg : AppSpacing.xl).tPadding,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          if (hasSecondary)
            AppButton(
              onPressed: onSecondaryAction,
              text: secondaryActionText,
              leading: secondaryActionIcon != null
                  ? Icon(secondaryActionIcon, size: buttonIconSize)
                  : null,
              type: ButtonType.secondaryPrimary,
              size: buttonSize,
              fullWidth: false,
              borderRadius: AppRadius.mdRadius,
            ),
          if (hasPrimary)
            AppButton(
              onPressed: onAction,
              text: primaryText,
              leading: primaryIcon != null
                  ? Icon(primaryIcon, size: buttonIconSize)
                  : null,
              type: config.actionButtonType,
              size: buttonSize,
              fullWidth: false,
              borderRadius: AppRadius.mdRadius,
            ),
        ],
      ),
    );
  }
}
