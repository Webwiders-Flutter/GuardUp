import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '../feedbacks/widgets/app_snackbar.dart';

/// An enterprise-grade widget that displays text with an automatic "Show more"
/// trigger when the text exceeds [maxLines].
///
/// Clicking "Show more" displays the entire content in an executive modal dialog
/// with one-click copy capability.
class AppShowMoreText extends StatelessWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final String showMoreLabel;
  final String dialogTitle;
  final String? dialogSubtitle;
  final VoidCallback? onShowMore;

  const AppShowMoreText({
    super.key,
    required this.text,
    this.maxLines = 2,
    this.style,
    this.showMoreLabel = 'Show more',
    this.dialogTitle = 'Message Details',
    this.dialogSubtitle,
    this.onShowMore,
  });

  void _showFullMessageDialog(BuildContext context) {
    final colors = context.colors;

    showDialog<void>(
      context: context,
      barrierColor: colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: colors.surface,
          surfaceTintColor: colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────────────
                  Row(
                    children: [
                      QuickContainer(
                        p: AppSpacing.sm,
                        radius: AppRadius.md,
                        color: colors.secondary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: AppSpacing.xl,
                          color: colors.secondary,
                        ),
                      ),
                      AppSpacing.md.w,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dialogTitle,
                              style: context.textTheme.titleMedium?.bold(),
                            ),
                            if (dialogSubtitle != null &&
                                dialogSubtitle!.isNotEmpty) ...[
                              (AppSpacing.xs / 2).h,
                              Text(
                                dialogSubtitle!,
                                style: context.textTheme.bodySmall
                                    ?.size(AppSpacing.md - 1)
                                    .colour(colors.onSurfaceSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: AppSpacing.xl,
                          color: colors.onSurfaceSecondary,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  AppSpacing.lg.h,
                  Divider(
                    height: 1,
                    color: colors.borderLight.withValues(alpha: 0.8),
                  ),
                  AppSpacing.md.h,

                  // ── Message Content ──────────────────────────────────
                  Flexible(
                    child: QuickContainer(
                      w: double.infinity,
                      p: AppSpacing.md + 2,
                      radius: AppRadius.md,
                      color: colors.backgroundLight,
                      border: Border.all(
                        color: colors.borderLight.withValues(alpha: 0.8),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          text,
                          style: context.textTheme.bodyMedium
                              ?.size(AppSpacing.md + 2)
                              .lineHeight(1.5),
                        ),
                      ),
                    ),
                  ),

                  AppSpacing.lg.h,

                  // ── Actions ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        text: 'Copy Text',
                        leading: Icon(
                          Icons.copy_rounded,
                          size: AppSpacing.lg,
                          color: colors.onSurface,
                        ),
                        type: ButtonType.secondaryOff,
                        size: ButtonSize.small,
                        fullWidth: false,
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: text));
                          AppSnackbar.success('Message copied to clipboard');
                        },
                      ),
                      AppSpacing.sm.w,
                      AppButton(
                        text: 'Close',
                        type: ButtonType.primary,
                        size: ButtonSize.small,
                        fullWidth: false,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        style ??
        context.textTheme.bodySmall?.size(AppSpacing.md).lineHeight(1.35);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure whether the text exceeds maxLines in available width
        final span = TextSpan(text: text, style: effectiveStyle);
        final tp = TextPainter(
          text: span,
          textDirection: Directionality.of(context),
          maxLines: maxLines,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        final isOverflowing = tp.didExceedMaxLines;

        if (!isOverflowing) {
          return Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: effectiveStyle,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: effectiveStyle,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                text: showMoreLabel,
                type: ButtonType.text,
                padding: EdgeInsets.zero,
                size: ButtonSize.small,
                fullWidth: false,
                foregroundColor: context.colors.secondary,
                onPressed: onShowMore ?? () => _showFullMessageDialog(context),
              ),
            ),
          ],
        );
      },
    );
  }
}
