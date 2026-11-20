import 'package:flutter/widgets.dart';

/// Tracks pointer hover in a [ValueNotifier] and rebuilds only [builder].
///
/// Replaces the repeated `MouseRegion + ValueNotifier<bool> + dispose`
/// boilerplate in hoverable rows, tiles and triggers (rules.md §18). Pass any
/// subtree that does not depend on hover as [child] so it is built once.
class AppHoverBuilder extends StatefulWidget {
  const AppHoverBuilder({
    super.key,
    required this.builder,
    this.child,
    this.cursor = MouseCursor.defer,
    this.enabled = true,
    this.onHoverChanged,
  });

  final ValueWidgetBuilder<bool> builder;
  final Widget? child;
  final MouseCursor cursor;

  /// When false the hover value stays `false` and the cursor is not applied.
  final bool enabled;

  final ValueChanged<bool>? onHoverChanged;

  @override
  State<AppHoverBuilder> createState() => _AppHoverBuilderState();
}

class _AppHoverBuilderState extends State<AppHoverBuilder> {
  final ValueNotifier<bool> _hoveredNotifier = ValueNotifier<bool>(false);

  @override
  void didUpdateWidget(covariant AppHoverBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _hoveredNotifier.value) _setHovered(false);
  }

  @override
  void dispose() {
    _hoveredNotifier.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (_hoveredNotifier.value == value) return;
    _hoveredNotifier.value = value;
    widget.onHoverChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled ? widget.cursor : MouseCursor.defer,
      onEnter: (_) {
        if (widget.enabled) _setHovered(true);
      },
      onExit: (_) => _setHovered(false),
      child: ValueListenableBuilder<bool>(
        valueListenable: _hoveredNotifier,
        builder: widget.builder,
        child: widget.child,
      ),
    );
  }
}
