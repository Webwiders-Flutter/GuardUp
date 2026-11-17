import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Typedefs
// ─────────────────────────────────────────────────────────────────────────────

/// A single header action entry (e.g. duplicate, delete).
/// Uses a record typedef per rules.md §13.
typedef AppSidePanelAction = ({
  String label,
  IconData icon,
  VoidCallback onTap,
  Color? foregroundColor,
});

// ─────────────────────────────────────────────────────────────────────────────
// AppSidePanel – public API
// ─────────────────────────────────────────────────────────────────────────────

/// Enterprise right-side slide-in panel (Supabase / Linear style).
///
/// Opens as a full-height overlay anchored to the right edge of the screen.
/// Provides a structured header, scrollable body, and a pinned footer with
/// Save / Cancel actions.
///
/// Usage:
/// ```dart
/// AppSidePanel.show(
///   context: context,
///   title: 'Add Document Type',
///   subtitle: 'Configure document metadata and localisation',
///   body: MyFormWidget(),
///   onSave: (ctx) async {
///     final ok = await controller.save();
///     return ok; // return false to keep panel open
///   },
/// );
/// ```
final class AppSidePanel {
  AppSidePanel._();

  static int _openCount = 0;

  /// Whether any slide-in side panel is currently open on screen.
  static bool get isOpen => _openCount > 0;

  /// Opens the side panel.
  ///
  /// - [title]          Required header title.
  /// - [subtitle]       Optional descriptive subtitle.
  /// - [body]           Scrollable panel content.
  /// - [actions]        Optional icon-button list in the header
  ///                    (e.g. duplicate, delete). Close is always appended.
  /// - [showCloseAction] Whether to render the default ✕ close icon (true).
  /// - [onSave]         Async callback for the Save button.
  ///                    Return `false` to keep the panel open on failure.
  /// - [onCancel]       Cancel button callback. Defaults to `context.pop()`.
  /// - [saveLabel]      Save button label (default `'Save'`).
  /// - [cancelLabel]    Cancel button label (default `'Cancel'`).
  /// - [showFooter]     Whether to render the footer (default `true`).
  /// - [width]          Panel width in logical pixels (default `480`).
  ///                    Automatically capped at 90% of screen width.
  /// - [isDismissible]  Scrim tap closes the panel (default `true`).
  /// - [padding]        Body content padding override.
  /// - [backgroundColor] Panel background (defaults to `colors.surface`).
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget body,
    String? subtitle,
    List<AppSidePanelAction>? actions,
    bool showCloseAction = true,
    Future<bool> Function(BuildContext context)? onSave,
    VoidCallback? onCancel,
    String saveLabel = 'Save',
    String cancelLabel = 'Cancel',
    bool showFooter = true,
    double width = 480,
    bool isDismissible = true,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
  }) async {
    _openCount++;
    try {
      return await showGeneralDialog<T>(
        context: context,
        barrierDismissible: isDismissible,
        barrierLabel: MaterialLocalizations.of(context)
            .modalBarrierDismissLabel,
        barrierColor: context.colors.transparent,
        transitionDuration: AppDurations.medium,
        pageBuilder: (_, _, _) => const SizedBox.shrink(),
        transitionBuilder: (dialogContext, animation, _, _) {
          final resolvedWidth = width.clamp(0.0, dialogContext.width * 0.9);

          return Scaffold(
            backgroundColor: dialogContext.colors.transparent,
            body: Stack(
              children: [
                // ── Scrim ────────────────────────────────────────────────────
                GestureDetector(
                  onTap: isDismissible ? () => dialogContext.pop() : null,
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (_, _) => BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: animation.value * 2,
                        sigmaY: animation.value * 2,
                      ),
                      child: Container(
                        color: dialogContext.colors.onSurface.withValues(
                          alpha: animation.value * 0.18,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Panel ────────────────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                            reverseCurve: Curves.easeInCubic,
                          ),
                        ),
                    child: SelectionArea(
                      child: _AppSidePanelContent<T>(
                        title: title,
                        subtitle: subtitle,
                        body: body,
                        actions: actions ?? const [],
                        showCloseAction: showCloseAction,
                        onSave: onSave,
                        onCancel: onCancel,
                        saveLabel: saveLabel,
                        cancelLabel: cancelLabel,
                        showFooter: showFooter,
                        width: resolvedWidth,
                        padding: padding,
                        backgroundColor: backgroundColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      if (_openCount > 0) _openCount--;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal panel content
// ─────────────────────────────────────────────────────────────────────────────

class _AppSidePanelContent<T> extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<AppSidePanelAction> actions;
  final bool showCloseAction;
  final Future<bool> Function(BuildContext context)? onSave;
  final VoidCallback? onCancel;
  final String saveLabel;
  final String cancelLabel;
  final bool showFooter;
  final double width;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const _AppSidePanelContent({
    required this.title,
    required this.body,
    required this.actions,
    required this.showCloseAction,
    required this.saveLabel,
    required this.cancelLabel,
    required this.showFooter,
    required this.width,
    this.subtitle,
    this.onSave,
    this.onCancel,
    this.padding,
    this.backgroundColor,
  });

  @override
  State<_AppSidePanelContent<T>> createState() =>
      _AppSidePanelContentState<T>();
}

class _AppSidePanelContentState<T> extends State<_AppSidePanelContent<T>> {
  final ValueNotifier<bool> _isSavingNotifier = ValueNotifier(false);

  @override
  void dispose() {
    _isSavingNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (widget.onSave == null) return;
    _isSavingNotifier.value = true;
    try {
      final shouldClose = await widget.onSave!(context);
      if (shouldClose && mounted) context.pop();
    } finally {
      if (mounted) _isSavingNotifier.value = false;
    }
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final panelBg = widget.backgroundColor ?? colors.surface;

    return Material(
      color: colors.transparent,
      child: Container(
        width: widget.width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: panelBg,
          border: Border(left: BorderSide(color: colors.borderLight)),
          boxShadow: [
            BoxShadow(
              color: colors.onSurface.withValues(alpha: 0.08),
              blurRadius: AppSpacing.xxxl,
              offset: const Offset(-AppSpacing.sm, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────
            _PanelHeader(
              title: widget.title,
              subtitle: widget.subtitle,
              actions: widget.actions,
              showCloseAction: widget.showCloseAction,
            ),

            // ── Top divider ───────────────────────────────────────────
            Divider(height: 1, color: colors.borderLight),

            // ── Scrollable body ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: widget.padding ?? AppSpacing.lg.allPadding,
                child: widget.body,
              ),
            ),

            // ── Footer ────────────────────────────────────────────────
            if (widget.showFooter) ...[
              Divider(height: 1, color: colors.borderLight),
              ValueListenableBuilder<bool>(
                valueListenable: _isSavingNotifier,
                builder: (context, isSaving, _) {
                  return _PanelFooter(
                    saveLabel: widget.saveLabel,
                    cancelLabel: widget.cancelLabel,
                    isSaving: isSaving,
                    showSave: widget.onSave != null,
                    onSave: _handleSave,
                    onCancel: _handleCancel,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header widget
// ─────────────────────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<AppSidePanelAction> actions;
  final bool showCloseAction;

  const _PanelHeader({
    required this.title,
    required this.actions,
    required this.showCloseAction,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleMedium?.bold().colour(
                    colors.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  (AppSpacing.xs / 2).h,
                  Text(
                    subtitle!,
                    style: context.textTheme.bodySmall
                        ?.size(AppSpacing.md + 0.5)
                        .colour(colors.onSurfaceSecondary),
                  ),
                ],
              ],
            ),
          ),

          // Optional extra action icons
          ...actions.map(
            (action) => Padding(
              padding: AppSpacing.xs.lPadding,
              child: Tooltip(
                message: action.label,
                child: _HeaderIconButton(
                  icon: action.icon,
                  color: action.foregroundColor ?? colors.onSurfaceSecondary,
                  onTap: action.onTap,
                ),
              ),
            ),
          ),

          // Thin divider between optional actions and close
          if (actions.isNotEmpty && showCloseAction)
            Container(
              height: AppSpacing.xl,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              color: colors.borderLight,
            ),

          // Close button
          if (showCloseAction)
            Tooltip(
              message: 'Close',
              child: _HeaderIconButton(
                icon: Icons.close_rounded,
                color: colors.onSurfaceSecondary,
                onTap: () => context.pop(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer widget
// ─────────────────────────────────────────────────────────────────────────────

class _PanelFooter extends StatelessWidget {
  final String saveLabel;
  final String cancelLabel;
  final bool isSaving;
  final bool showSave;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _PanelFooter({
    required this.saveLabel,
    required this.cancelLabel,
    required this.isSaving,
    required this.showSave,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return QuickContainer(
      px: AppSpacing.xl,
      py: AppSpacing.md,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppButton(
            text: cancelLabel,
            type: ButtonType.secondaryOff,
            size: ButtonSize.normal,
            fullWidth: false,
            onPressed: onCancel,
          ),
          if (showSave) ...[
            AppSpacing.md.w,
            AppButton(
              text: saveLabel,
              size: ButtonSize.normal,
              fullWidth: false,
              isLoading: isSaving,
              onPressed: onSave,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small icon button used in the header
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdRadius,
      child: QuickContainer(
        p: AppSpacing.xs + 1,
        radius: AppRadius.md,
        child: Icon(icon, size: AppSpacing.xl, color: color),
      ),
    );
  }
}
