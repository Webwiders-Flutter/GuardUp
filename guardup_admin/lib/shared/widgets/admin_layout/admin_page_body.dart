import 'package:flutter/material.dart';

import '/core/constants/app_layout.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

/// Standard body for every page rendered inside the admin shell.
///
/// Gives all screens the same responsive gutter (12 px on phones, 16 px
/// otherwise), an optional [header], an optional [maxWidth] for
/// reading-width pages (forms, settings) and a [Scaffold] host so snackbars
/// and side panels resolve against the page.
///
/// - Table screens: `AdminPageBody(child: AdminTableBuilder(...))` — the
///   table fills the remaining height.
/// - Content screens: `AdminPageBody(scrollable: true, maxWidth: 960, ...)`.
class AdminPageBody extends StatelessWidget {
  const AdminPageBody({
    super.key,
    required this.child,
    this.header,
    this.scrollable = false,
    this.maxWidth,
    this.padding,
  });

  final Widget child;

  /// Usually an [AdminPageHeader]; placed above [child].
  final Widget? header;

  /// Scroll the whole body instead of letting [child] fill the height. Use
  /// for content pages; keep false for tables and other self-scrolling views.
  final bool scrollable;

  /// Constrains and centers the content.
  final double? maxWidth;

  /// Overrides the responsive gutter.
  final EdgeInsetsGeometry? padding;

  /// Gutter for a shell viewport of [width].
  static double gutterFor(double width) {
    return width < AppLayout.compactBreakpoint ? AppSpacing.md : AppSpacing.lg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = gutterFor(constraints.maxWidth);
          final resolvedPadding = padding ?? EdgeInsets.all(gutter);

          Widget content = scrollable
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (header != null) ...[header!, gutter.h],
                    child,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (header != null) ...[header!, gutter.h],
                    Expanded(child: child),
                  ],
                );

          if (maxWidth != null) {
            content = Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth!),
                child: content,
              ),
            );
          }

          return scrollable
              ? SingleChildScrollView(padding: resolvedPadding, child: content)
              : Padding(padding: resolvedPadding, child: content);
        },
      ),
    );
  }
}

/// Title row for content pages: heading, supporting text and trailing
/// [actions]. Wraps the actions under the title on narrow widths.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: context.textTheme.headlineSmall
              ?.bold()
              .textSpacing(-0.3)
              .colour(colors.onSurface),
        ),
        if (subtitle != null) ...[
          AppSpacing.xs.h,
          Text(
            subtitle!,
            style: context.textTheme.bodyMedium?.colour(
              colors.onSurfaceSecondary,
            ),
          ),
        ],
      ],
    );

    if (actions.isEmpty) return heading;

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        heading,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: actions,
        ),
      ],
    );
  }
}
