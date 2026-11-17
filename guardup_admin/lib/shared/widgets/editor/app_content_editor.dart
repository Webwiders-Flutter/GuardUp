import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'app_content_preview.dart';

import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '../feedbacks/widgets/app_popup.dart';
import '../feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/misc/app_chip.dart';
import 'app_content_editor_controller.dart';

enum ContentEditorViewMode { editor, preview }

/// Enterprise-grade Rich Content Editor for legal & administrative content.
///
/// Designed specifically for managing:
/// - Terms and Conditions
/// - Privacy Policy
/// - About Us & Company Information
/// - Help Center & Knowledge Base articles
///
/// Features:
/// - 100% theme-driven via [context.colors] and [context.textTheme]
/// - Dual mode: Visual Editor (WYSIWYG) and Live Formatted Preview with matched typography
/// - Compact, proportional enterprise toolbar with optimized icon and button sizing
/// - Rich formatting: Headings (H1/H2/H3), Bold, Italic, Underline, Strike, Alignment, Lists, Quotes, Code, Links
/// - Real-time document statistics (word count, character count, estimated reading time)
/// - Fullscreen expansion mode for distraction-free policy authoring
/// - Copy-to-clipboard for clean HTML export
class AppContentEditor extends StatefulWidget {
  final AppContentEditorController? controller;
  final String? initialHtml;
  final String? placeholder;
  final String? title;
  final bool readOnly;
  final double minHeight;
  final double? maxHeight;
  final bool showHeader;
  final bool showToolbar;
  final bool showStatusBar;
  final bool isLoading;
  final ValueChanged<String>? onHtmlChanged;
  final VoidCallback? onChanged;
  final List<Widget>? customHeaderActions;

  const AppContentEditor({
    super.key,
    this.controller,
    this.initialHtml,
    this.placeholder,
    this.title,
    this.readOnly = false,
    this.minHeight = 420.0,
    this.maxHeight,
    this.showHeader = true,
    this.showToolbar = true,
    this.showStatusBar = true,
    this.isLoading = false,
    this.onHtmlChanged,
    this.onChanged,
    this.customHeaderActions,
  });

  @override
  State<AppContentEditor> createState() => _AppContentEditorState();
}

class _AppContentEditorState extends State<AppContentEditor> {
  late final AppContentEditorController _controller;
  late final FocusNode _focusNode;
  bool _ownsController = false;

  final ValueNotifier<ContentEditorViewMode> _viewModeNotifier = ValueNotifier(
    ContentEditorViewMode.editor,
  );
  final ValueNotifier<bool> _isFullscreenNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(canRequestFocus: false);

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownsController = true;
      _controller = AppContentEditorController(initialHtml: widget.initialHtml);
    }

    _controller.quillController.skipRequestKeyboard = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.canRequestFocus = true;
        _controller.quillController.skipRequestKeyboard = false;
      }
    });

    _controller.addListener(_handleControllerChange);
  }

  void _handleControllerChange() {
    widget.onChanged?.call();
    if (widget.onHtmlChanged != null) {
      widget.onHtmlChanged!(_controller.toHtml());
    }
  }

  @override
  void dispose() {
    _viewModeNotifier.dispose();
    _isFullscreenNotifier.dispose();
    _controller.removeListener(_handleControllerChange);
    _focusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _copyHtmlToClipboard() {
    final html = _controller.toHtml();
    Clipboard.setData(ClipboardData(text: html));
    AppSnackbar.success('HTML content copied to clipboard');
  }

  Future<void> _clearEditor() async {
    if (_controller.isEmpty) return;

    final confirm = await AppPopup.show(
      context: context,
      title: 'Clear Content?',
      message: 'Are you sure you want to clear all text and formatting?',
      variant: PopupVariant.danger,
      icon: Icons.delete_outline_rounded,
      buttons: [
        AppButton(
          text: 'Cancel',
          type: ButtonType.secondaryOff,
          onPressed: () =>
              context.pop(const PopupResult(action: PopupAction.cancel)),
        ),
        AppButton(
          text: 'Clear All',
          type: ButtonType.danger,
          onPressed: () =>
              context.pop(const PopupResult(action: PopupAction.confirm)),
        ),
      ],
    );

    if (confirm?.action == PopupAction.confirm) {
      _controller.clear();
      if (mounted) {
        AppSnackbar.info('Editor content cleared');
      }
    }
  }

  Future<void> _toggleFullscreen(BuildContext context) async {
    if (_isFullscreenNotifier.value) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    _isFullscreenNotifier.value = true;
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Fullscreen Editor',
      barrierColor: context.colors.black.withValues(alpha: 0.6),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: context.colors.backgroundLight,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildEditorContainer(dialogContext, isFullscreen: true),
            ),
          ),
        );
      },
    );

    if (mounted) {
      _isFullscreenNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<bool>(
      valueListenable: _isFullscreenNotifier,
      builder: (context, isFullscreen, _) {
        if (isFullscreen) {
          return Container(
            height: widget.minHeight,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: colors.borderLight.withValues(alpha: 0.8),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fullscreen_rounded, size: 32, color: colors.primary),
                AppSpacing.sm.h,
                Text(
                  'Editing in Fullscreen Mode',
                  style: context.textTheme.titleSmall?.semiBold().colour(
                    colors.onSurface,
                  ),
                ),
                AppSpacing.xs.h,
                Text(
                  'Click Exit Fullscreen in the overlay to return here.',
                  style: context.textTheme.bodySmall?.colour(
                    colors.onSurfaceSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return _buildEditorContainer(context, isFullscreen: false);
      },
    );
  }

  Widget _buildEditorContainer(
    BuildContext context, {
    required bool isFullscreen,
  }) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: colors.borderLight.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.mdRadius,
        child: Stack(
          children: [
            Opacity(
              opacity: widget.isLoading ? 0.55 : 1.0,
              child: IgnorePointer(
                ignoring: widget.isLoading,
                child: ValueListenableBuilder<ContentEditorViewMode>(
                  valueListenable: _viewModeNotifier,
                  builder: (context, currentMode, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: isFullscreen
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      children: [
                        // ── 1. Top Header & Mode Bar ──────────────────────────────
                        if (widget.showHeader) _buildHeader(context),

                        // ── 2. Quill Formatting Toolbar ───────────────────────────
                        if (widget.showToolbar &&
                            !widget.readOnly &&
                            currentMode == ContentEditorViewMode.editor)
                          _buildToolbar(context),

                        // ── 3. Content Body (Editor / Preview) ───────────────────
                        if (isFullscreen)
                          Expanded(
                            child: _buildBody(
                              context,
                              currentMode,
                              isFullscreen,
                            ),
                          )
                        else
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: widget.minHeight,
                              maxHeight: widget.maxHeight ?? double.infinity,
                            ),
                            child: _buildBody(
                              context,
                              currentMode,
                              isFullscreen,
                            ),
                          ),

                        // ── 4. Bottom Status & Metrics Bar ────────────────────────
                        if (widget.showStatusBar) _buildStatusBar(context),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (widget.isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  backgroundColor: context.colors.transparent,
                  valueColor: AlwaysStoppedAnimation(context.colors.secondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Header Bar ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: colors.borderLight.withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title & Icon (Refined & Balanced)
          QuickContainer(
            p: AppSpacing.xs + 2,
            radius: AppRadius.sm,
            color: colors.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.article_outlined,
              size: 18,
              color: colors.primary,
            ),
          ),
          AppSpacing.sm.w,
          Expanded(
            child: Text(
              widget.title ?? 'Content Editor',
              style: context.textTheme.titleMedium?.semiBold().size(16.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          AppSpacing.md.w,

          // View Mode Selector (Editor, Preview - Balanced Tabs)
          _buildModeSelector(context),

          AppSpacing.sm.w,

          // Copy HTML Action (Balanced)
          Tooltip(
            message: 'Copy HTML to Clipboard',
            child: InkWell(
              onTap: _copyHtmlToClipboard,
              borderRadius: AppRadius.smRadius,
              child: QuickContainer(
                p: AppSpacing.xs + 2,
                radius: AppRadius.sm,
                color: colors.surface,
                border: Border.all(
                  color: colors.borderLight.withValues(alpha: 0.8),
                ),
                child: Icon(
                  Icons.copy_rounded,
                  size: 17,
                  color: colors.onSurfaceSecondary,
                ),
              ),
            ),
          ),

          // Clear Button (Balanced)
          if (!widget.readOnly) ...[
            AppSpacing.xs.w,
            Tooltip(
              message: 'Clear Content',
              child: InkWell(
                onTap: _clearEditor,
                borderRadius: AppRadius.smRadius,
                child: QuickContainer(
                  p: AppSpacing.xs + 2,
                  radius: AppRadius.sm,
                  color: colors.error.withValues(alpha: 0.08),
                  border: Border.all(
                    color: colors.error.withValues(alpha: 0.25),
                  ),
                  child: Icon(
                    Icons.delete_sweep_outlined,
                    size: 17,
                    color: colors.error,
                  ),
                ),
              ),
            ),
          ],

          // Fullscreen Toggle (Balanced)
          AppSpacing.xs.w,
          ValueListenableBuilder<bool>(
            valueListenable: _isFullscreenNotifier,
            builder: (context, isFullscreen, _) {
              return Tooltip(
                message: isFullscreen ? 'Exit Fullscreen' : 'Expand Fullscreen',
                child: InkWell(
                  onTap: () => _toggleFullscreen(context),
                  borderRadius: AppRadius.smRadius,
                  child: QuickContainer(
                    p: AppSpacing.xs + 2,
                    radius: AppRadius.sm,
                    color: colors.surface,
                    border: Border.all(
                      color: colors.borderLight.withValues(alpha: 0.8),
                    ),
                    child: Icon(
                      isFullscreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      size: 17,
                      color: colors.onSurfaceSecondary,
                    ),
                  ),
                ),
              );
            },
          ),

          // Custom Header Actions
          if (widget.customHeaderActions != null) ...[
            AppSpacing.xs.w,
            ...widget.customHeaderActions!,
          ],
        ],
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<ContentEditorViewMode>(
      valueListenable: _viewModeNotifier,
      builder: (context, currentMode, _) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.smRadius,
            border: Border.all(
              color: colors.borderLight.withValues(alpha: 0.8),
            ),
          ),
          padding: const EdgeInsets.all(2.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modePill(
                context,
                currentMode: currentMode,
                mode: ContentEditorViewMode.editor,
                label: 'Editor',
                icon: Icons.edit_note_rounded,
              ),
              _modePill(
                context,
                currentMode: currentMode,
                mode: ContentEditorViewMode.preview,
                label: 'Preview',
                icon: Icons.visibility_outlined,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modePill(
    BuildContext context, {
    required ContentEditorViewMode currentMode,
    required ContentEditorViewMode mode,
    required String label,
    required IconData icon,
  }) {
    final colors = context.colors;
    final isSelected = currentMode == mode;

    return InkWell(
      onTap: () => _viewModeNotifier.value = mode,
      borderRadius: AppRadius.xsRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md - 2,
          vertical: AppSpacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.transparent,
          borderRadius: AppRadius.xsRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colors.onPrimary : colors.onSurfaceSecondary,
            ),
            AppSpacing.xs.w,
            Text(
              label,
              style: context.textTheme.bodyMedium
                  ?.semiBold()
                  .size(13.5)
                  .colour(
                    isSelected ? colors.onPrimary : colors.onSurfaceSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Toolbar (Balanced & Proportional) ──────────────────────────────────────────

  Widget _buildToolbar(BuildContext context) {
    final colors = context.colors;

    final buttonStyle = IconButton.styleFrom(
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.all(4),
      minimumSize: const Size(34, 34),
      maximumSize: const Size(38, 38),
      iconSize: 19,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundLight.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: colors.borderLight.withValues(alpha: 0.7),
            width: 1.0,
          ),
        ),
      ),
      child: QuillSimpleToolbar(
        controller: _controller.quillController,
        config: QuillSimpleToolbarConfig(
          toolbarSize: 36,
          showFontFamily: false,
          showFontSize: false,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: true,
          showColorButton: true,
          showBackgroundColorButton: true,
          showClearFormat: true,
          showAlignmentButtons: true,
          showHeaderStyle: true,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: true,
          showCodeBlock: true,
          showQuote: true,
          showIndent: true,
          showLink: true,
          showUndo: true,
          showRedo: true,
          showSearchButton: true,
          showSubscript: false,
          showSuperscript: false,
          showInlineCode: true,
          buttonOptions: QuillSimpleToolbarButtonOptions(
            base: QuillToolbarBaseButtonOptions(
              iconSize: 19,
              iconButtonFactor: 1.0,
              iconTheme: QuillIconTheme(
                iconButtonSelectedData: IconButtonData(
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                    maxWidth: 38,
                    maxHeight: 38,
                  ),
                  padding: const EdgeInsets.all(4),
                  iconSize: 19,
                  visualDensity: VisualDensity.standard,
                  style: buttonStyle.copyWith(
                    padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
                    minimumSize: const WidgetStatePropertyAll(Size(34, 34)),
                    maximumSize: const WidgetStatePropertyAll(Size(38, 38)),
                    backgroundColor: WidgetStatePropertyAll(
                      colors.secondary.withValues(alpha: 0.15),
                    ),
                    foregroundColor: WidgetStatePropertyAll(colors.secondary),
                  ),
                ),
                iconButtonUnselectedData: IconButtonData(
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                    maxWidth: 38,
                    maxHeight: 38,
                  ),
                  padding: const EdgeInsets.all(4),
                  iconSize: 19,
                  visualDensity: VisualDensity.standard,
                  style: buttonStyle.copyWith(
                    padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
                    minimumSize: const WidgetStatePropertyAll(Size(34, 34)),
                    maximumSize: const WidgetStatePropertyAll(Size(38, 38)),
                    foregroundColor: WidgetStatePropertyAll(
                      colors.onSurfaceSecondary,
                    ),
                  ),
                ),
              ),
            ),
            undoHistory: const QuillToolbarHistoryButtonOptions(iconSize: 19),
            redoHistory: const QuillToolbarHistoryButtonOptions(iconSize: 19),
            bold: const QuillToolbarToggleStyleButtonOptions(iconSize: 19),
            italic: const QuillToolbarToggleStyleButtonOptions(iconSize: 19),
            underLine: const QuillToolbarToggleStyleButtonOptions(iconSize: 19),
            strikeThrough: const QuillToolbarToggleStyleButtonOptions(
              iconSize: 19,
            ),
            inlineCode: const QuillToolbarToggleStyleButtonOptions(
              iconSize: 19,
            ),
            quote: const QuillToolbarToggleStyleButtonOptions(iconSize: 19),
            codeBlock: const QuillToolbarToggleStyleButtonOptions(iconSize: 19),
            clearFormat: const QuillToolbarClearFormatButtonOptions(
              iconSize: 19,
            ),
            color: const QuillToolbarColorButtonOptions(iconSize: 19),
            backgroundColor: const QuillToolbarColorButtonOptions(iconSize: 19),
            linkStyle: const QuillToolbarLinkStyleButtonOptions(iconSize: 19),
            listNumbers: const QuillToolbarToggleStyleButtonOptions(
              iconSize: 19,
            ),
            listBullets: const QuillToolbarToggleStyleButtonOptions(
              iconSize: 19,
            ),
            toggleCheckList: const QuillToolbarToggleCheckListButtonOptions(
              iconSize: 19,
            ),
            indentIncrease: const QuillToolbarIndentButtonOptions(iconSize: 19),
            indentDecrease: const QuillToolbarIndentButtonOptions(iconSize: 19),
            selectAlignmentButtons:
                const QuillToolbarSelectAlignmentButtonOptions(iconSize: 19),
            search: const QuillToolbarSearchButtonOptions(iconSize: 19),
            selectHeaderStyleButtons:
                const QuillToolbarSelectHeaderStyleButtonsOptions(iconSize: 19),
            selectHeaderStyleDropdownButton:
                QuillToolbarSelectHeaderStyleDropdownButtonOptions(
                  iconSize: 19,
                  textStyle:
                      context.textTheme.bodyMedium?.semiBold().colour(
                        colors.onSurface,
                      ) ??
                      const TextStyle(fontWeight: FontWeight.w600),
                  iconTheme: QuillIconTheme(
                    iconButtonUnselectedData: IconButtonData(
                      constraints: const BoxConstraints(
                        minWidth: 112,
                        minHeight: 34,
                        maxWidth: 145,
                        maxHeight: 38,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      style: buttonStyle.copyWith(
                        minimumSize: const WidgetStatePropertyAll(
                          Size(112, 34),
                        ),
                        maximumSize: const WidgetStatePropertyAll(
                          Size(145, 38),
                        ),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    iconButtonSelectedData: IconButtonData(
                      constraints: const BoxConstraints(
                        minWidth: 112,
                        minHeight: 34,
                        maxWidth: 145,
                        maxHeight: 38,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      style: buttonStyle.copyWith(
                        minimumSize: const WidgetStatePropertyAll(
                          Size(112, 34),
                        ),
                        maximumSize: const WidgetStatePropertyAll(
                          Size(145, 38),
                        ),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  // ── Content Body (Editor / Preview) ─────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    ContentEditorViewMode mode,
    bool isFullscreen,
  ) {
    switch (mode) {
      case ContentEditorViewMode.editor:
        return _buildVisualEditor(context, isFullscreen);
      case ContentEditorViewMode.preview:
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _buildLivePreview(context),
        );
    }
  }

  DefaultStyles _buildEditorStyles(BuildContext context) {
    final colors = context.colors;
    final baseStyles = DefaultStyles.getInstance(context);
    final textTheme = context.textTheme;

    return baseStyles.merge(
      DefaultStyles(
        h1: DefaultTextBlockStyle(
          textTheme.headlineMedium?.bold().lineHeight(1.3) ??
              const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          HorizontalSpacing.zero,
          const VerticalSpacing(AppSpacing.lg, AppSpacing.sm),
          VerticalSpacing.zero,
          null,
        ),
        h2: DefaultTextBlockStyle(
          textTheme.titleLarge?.semiBold().lineHeight(1.3) ??
              const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          HorizontalSpacing.zero,
          const VerticalSpacing(AppSpacing.md + 2, AppSpacing.sm - 2),
          VerticalSpacing.zero,
          null,
        ),
        h3: DefaultTextBlockStyle(
          textTheme.titleMedium?.semiBold().lineHeight(1.3) ??
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          HorizontalSpacing.zero,
          const VerticalSpacing(AppSpacing.md, AppSpacing.xs),
          VerticalSpacing.zero,
          null,
        ),
        paragraph: DefaultTextBlockStyle(
          textTheme.bodyMedium?.lineHeight(1.6) ??
              const TextStyle(fontSize: 15, height: 1.6),
          HorizontalSpacing.zero,
          const VerticalSpacing(0, AppSpacing.sm),
          VerticalSpacing.zero,
          null,
        ),
        placeHolder: DefaultTextBlockStyle(
          textTheme.bodyMedium
                  ?.lineHeight(1.6)
                  .colour(colors.onSurfaceSecondary.withValues(alpha: 0.5)) ??
              const TextStyle(fontSize: 15, height: 1.6),
          HorizontalSpacing.zero,
          VerticalSpacing.zero,
          VerticalSpacing.zero,
          null,
        ),
        quote: DefaultTextBlockStyle(
          textTheme.bodyMedium
                  ?.italic()
                  .lineHeight(1.55)
                  .colour(colors.onSurfaceSecondary) ??
              const TextStyle(fontStyle: FontStyle.italic),
          HorizontalSpacing.zero,
          const VerticalSpacing(AppSpacing.sm, AppSpacing.sm),
          VerticalSpacing.zero,
          BoxDecoration(
            border: Border(
              left: BorderSide(color: colors.secondary, width: 3.5),
            ),
          ),
        ),
        lists: DefaultListBlockStyle(
          textTheme.bodyMedium?.lineHeight(1.6) ??
              const TextStyle(fontSize: 15, height: 1.6),
          HorizontalSpacing.zero,
          const VerticalSpacing(3, 3),
          VerticalSpacing.zero,
          null,
          null,
        ),
        bold:
            textTheme.bodyMedium?.bold() ??
            const TextStyle(fontWeight: FontWeight.bold),
        italic:
            textTheme.bodyMedium?.italic() ??
            const TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildVisualEditor(BuildContext context, bool isFullscreen) {
    final colors = context.colors;
    final editorStyles = _buildEditorStyles(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      },
      child: Container(
        color: colors.surface,
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: DefaultTextStyle(
              style:
                  context.textTheme.bodyMedium?.lineHeight(1.6) ??
                  DefaultTextStyle.of(context).style,
              child: QuillEditor.basic(
                controller: _controller.quillController,
                focusNode: _focusNode,
                config: QuillEditorConfig(
                  customStyles: editorStyles,
                  placeholder:
                      widget.placeholder ??
                      'Write legal clauses, terms, or policy details here...',
                  autoFocus: false,
                  expands: isFullscreen,
                  scrollable: true,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreview(BuildContext context) {
    return AppContentPreview(
      html: _controller.toHtml(),
      emptyTitle: 'Document is empty',
      emptyMessage: 'Switch to Editor mode to write and format content.',
      maxWidth: 860.0,
    );
  }

  // ── Bottom Status Bar ───────────────────────────────────────────────────────

  Widget _buildStatusBar(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final colors = context.colors;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 1,
          ),
          decoration: BoxDecoration(
            color: colors.backgroundLight,
            border: Border(
              top: BorderSide(
                color: colors.borderLight.withValues(alpha: 0.8),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              // Word count chip
              AppChip(
                color: colors.info,
                title: '${_controller.wordCount} Words',
                size: AppChipSize.small,
              ),
              AppSpacing.xs.w,

              // Character count chip
              AppChip(
                color: colors.onSurfaceSecondary,
                title: '${_controller.charCount} Chars',
                size: AppChipSize.small,
              ),
              AppSpacing.xs.w,

              // Reading time chip
              AppChip(
                color: colors.secondary,
                title: _controller.readTimeEstimate,
                icon: Icons.schedule_rounded,
                size: AppChipSize.small,
              ),

              const Spacer(),

              // Read-only indicator
              if (widget.readOnly)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: AppSpacing.md,
                      color: colors.warning,
                    ),
                    AppSpacing.xs.w,
                    Text(
                      'Read-Only',
                      style: context.textTheme.labelSmall?.semiBold().colour(
                        colors.warning,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'HTML 5 Document',
                  style: context.textTheme.labelSmall
                      ?.size(AppSpacing.md - 2.5)
                      .colour(colors.onSurfaceSecondary.withValues(alpha: 0.7)),
                ),
            ],
          ),
        );
      },
    );
  }
}
