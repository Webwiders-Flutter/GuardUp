import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'
    show HtmlWidget;

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

/// Reusable enterprise preview widget for formatted HTML documents and policies.
///
/// Ensures consistent typographic presentation across the admin rich editor preview
/// and public-facing legal pages (Terms, Privacy Policy, About Us).
class AppContentPreview extends StatelessWidget {
  /// Raw HTML document string to render.
  final String html;

  /// Custom title for empty document state.
  final String? emptyTitle;

  /// Custom descriptive message for empty document state.
  final String? emptyMessage;

  /// Maximum content width constraint (defaults to 860).
  final double maxWidth;

  /// Optional custom padding inside the content surface.
  final EdgeInsetsGeometry? padding;

  /// Whether to render inside an elevated enterprise paper card.
  final bool isCard;

  /// Optional widget displayed directly above the rendered HTML content.
  final Widget? header;

  /// Optional widget displayed directly below the rendered HTML content.
  final Widget? footer;

  const AppContentPreview({
    super.key,
    required this.html,
    this.emptyTitle,
    this.emptyMessage,
    this.maxWidth = 860.0,
    this.padding,
    this.isCard = true,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trimmed = html.trim();

    if (trimmed.isEmpty) {
      return _buildEmptyState(context);
    }

    Widget contentBody = SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[header!, AppSpacing.lg.h],
          HtmlWidget(
            trimmed,
            textStyle: context.textTheme.bodyMedium
                ?.size(AppSpacing.md + 3)
                .lineHeight(1.6),
            customStylesBuilder: (element) {
              final primaryColorCss = _toCssColor(colors.primary);
              final secondaryColorCss = _toCssColor(colors.secondary);
              final backgroundLightCss = _toCssColor(colors.backgroundLight);

              switch (element.localName) {
                case 'h1':
                  return {
                    'font-size': '24px',
                    'font-weight': '700',
                    'line-height': '1.3',
                    'letter-spacing': '-0.4px',
                    'margin-top': '16px',
                    'margin-bottom': '8px',
                    'color': primaryColorCss,
                  };
                case 'h2':
                  return {
                    'font-size': '19px',
                    'font-weight': '600',
                    'line-height': '1.3',
                    'letter-spacing': '-0.2px',
                    'margin-top': '14px',
                    'margin-bottom': '6px',
                    'color': primaryColorCss,
                  };
                case 'h3':
                  return {
                    'font-size': '16.5px',
                    'font-weight': '600',
                    'line-height': '1.3',
                    'margin-top': '12px',
                    'margin-bottom': '4px',
                    'color': primaryColorCss,
                  };
                case 'p':
                  return {
                    'font-size': '15px',
                    'line-height': '1.6',
                    'margin-top': '0px',
                    'margin-bottom': '8px',
                  };
                case 'blockquote':
                  return {
                    'font-size': '14.5px',
                    'font-style': 'italic',
                    'line-height': '1.55',
                    'margin': '8px 0',
                    'padding-left': '12px',
                    'border-left': '3.5px solid $secondaryColorCss',
                  };
                case 'ul':
                case 'ol':
                  return {
                    'font-size': '15px',
                    'line-height': '1.6',
                    'margin-top': '4px',
                    'margin-bottom': '8px',
                    'padding-left': '24px',
                  };
                case 'li':
                  return {
                    'font-size': '15px',
                    'line-height': '1.6',
                    'margin-bottom': '4px',
                  };
                case 'code':
                  return {
                    'font-size': '13.5px',
                    'padding': '2px 5px',
                    'background-color': backgroundLightCss,
                    'border-radius': '4px',
                  };
              }
              return null;
            },
          ),
          if (footer != null) ...[AppSpacing.xl.h, footer!],
        ],
      ),
    );

    if (isCard) {
      contentBody = Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdRadius,
          color: colors.surface,
          border: Border.all(color: colors.borderLight.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: contentBody,
      );
    } else if (padding != null) {
      contentBody = Padding(padding: padding!, child: contentBody);
    }

    return Container(
      color: colors.backgroundLight.withValues(alpha: 0.4),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: contentBody,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: AppSpacing.xxxl,
            color: colors.onSurfaceSecondary.withValues(alpha: 0.4),
          ),
          AppSpacing.md.h,
          Text(
            emptyTitle ?? 'Document is empty',
            style: context.textTheme.titleSmall?.semiBold().colour(
              colors.onSurfaceSecondary,
            ),
          ),
          AppSpacing.xs.h,
          Text(
            emptyMessage ??
                'No published content available for this selection.',
            style: context.textTheme.bodySmall?.colour(
              colors.onSurfaceSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Converts a theme [Color] into a CSS compatible rgb/rgba string.
  String _toCssColor(Color color) {
    final int argb = color.toARGB32();
    final int r = (argb >> 16) & 0xFF;
    final int g = (argb >> 8) & 0xFF;
    final int b = argb & 0xFF;
    final double a = ((argb >> 24) & 0xFF) / 255.0;
    if (a < 1.0) {
      return 'rgba($r, $g, $b, ${a.toStringAsFixed(2)})';
    }
    return 'rgb($r, $g, $b)';
  }
}
