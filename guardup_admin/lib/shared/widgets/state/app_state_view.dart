import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/localization.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
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
      defaultColor: (ctx) => ctx.colors.secondary,
      defaultBackgroundColor: (ctx) =>
          ctx.colors.secondary.withValues(alpha: 0.15),
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
      defaultColor: (ctx) => ctx.colors.secondary,
      defaultBackgroundColor: (ctx) =>
          ctx.colors.secondary.withValues(alpha: 0.12),
      defaultMessage: (ctx) => 'Loading...',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final config = _configs[type] ?? _configs[AppViewType.empty]!;

    final resolvedMessage = message ?? config.defaultMessage(context);
    final resolvedSubtitle = subtitle ?? config.defaultSubtitle(context);
    final resolvedActionText = actionText ?? config.defaultActionText(context);
    final resolvedActionIcon = showActionIcon
        ? (actionIcon ?? config.defaultActionIcon)
        : null;

    final resolvedPadding =
        padding ??
        (isCompact
            ? EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              )
            : EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xxxl,
              ));

    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0.0, end: 1.0),
        builder: (context, animValue, child) {
          return Opacity(
            opacity: animValue,
            child: Transform.translate(
              offset: Offset(0, (1.0 - animValue) * 10),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: resolvedPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? (isCompact ? 360.0 : 440.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildVisualElement(context, config),
                (isCompact ? 14 : 20).h,
                if (resolvedMessage.isNotEmpty)
                  Text(
                    resolvedMessage,
                    style:
                        (isCompact
                                ? theme.textTheme.titleSmall
                                : theme.textTheme.titleMedium)
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                              letterSpacing: -0.2,
                            ),
                    textAlign: TextAlign.center,
                  ),
                if (resolvedSubtitle != null &&
                    resolvedSubtitle.isNotEmpty) ...[
                  (isCompact ? 4 : 8).h,
                  Text(
                    resolvedSubtitle,
                    style:
                        (isCompact
                                ? theme.textTheme.bodySmall
                                : theme.textTheme.bodyMedium)
                            ?.copyWith(
                              color: colors.onSurfaceSecondary,
                              height: 1.45,
                            ),
                    textAlign: TextAlign.center,
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
    if (customIllustration != null) {
      return customIllustration!;
    }

    if (lottieAsset != null) {
      return SizedBox(
        width: lottieWidth ?? (isCompact ? 140.0 : 200.0),
        child: Lottie.asset(lottieAsset!, repeat: repeat),
      );
    }

    return _buildIconBadge(context, config);
  }

  Widget _buildIconBadge(BuildContext context, _ViewStateConfig config) {
    final iconSize = isCompact ? 24.0 : 36.0;
    final innerSize = isCompact ? 52.0 : 76.0;
    final outerHaloPadding = isCompact ? 6.0 : 10.0;

    final primaryColor = iconColor ?? config.defaultColor(context);
    final bgColor =
        iconBackgroundColor ?? config.defaultBackgroundColor(context);

    if (type == AppViewType.loading) {
      return Container(
        width: innerSize + (outerHaloPadding * 2),
        height: innerSize + (outerHaloPadding * 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor.withValues(alpha: 0.35),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        padding: EdgeInsets.all(outerHaloPadding),
        child: Center(
          child: SizedBox(
            width: iconSize + 6,
            height: iconSize + 6,
            child: CircularProgressIndicator(
              strokeWidth: isCompact ? 2.5 : 3.2,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(outerHaloPadding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withValues(alpha: 0.05),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Container(
        width: innerSize,
        height: innerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.22),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.12),
              blurRadius: 18,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon ?? config.defaultIcon,
            size: iconSize,
            color: primaryColor,
          ),
        ),
      ),
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

    final buttonSize = isCompact ? ButtonSize.small : ButtonSize.medium;

    return Padding(
      padding: (isCompact ? 16 : 24).tPadding,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          if (hasSecondary)
            AppButton(
              onPressed: onSecondaryAction,
              text: secondaryActionText,
              leading: secondaryActionIcon != null
                  ? Icon(secondaryActionIcon, size: isCompact ? 16 : 18)
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
                  ? Icon(primaryIcon, size: isCompact ? 16 : 18)
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
