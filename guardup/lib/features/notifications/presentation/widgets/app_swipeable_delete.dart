import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';

/// A sleek swipe-to-reveal action widget.
/// Swiping left reveals an action button (e.g. Delete) that the user can click to execute.
class AppSwipeableDelete extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final bool isEnabled;
  final double actionWidth;

  const AppSwipeableDelete({
    super.key,
    required this.child,
    required this.onDelete,
    this.isEnabled = true,
    this.actionWidth = 84.0,
  });

  @override
  State<AppSwipeableDelete> createState() => _AppSwipeableDeleteState();
}

class _AppSwipeableDeleteState extends State<AppSwipeableDelete>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _dragExtent = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    _controller.animateTo(1.0, curve: Curves.easeOut);
    _dragExtent = widget.actionWidth;
  }

  void _close() {
    _controller.animateTo(0.0, curve: Curves.easeOut);
    _dragExtent = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return widget.child;
    }

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Background Delete Button revealed ONLY when swiped
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.value <= 0.001) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: widget.actionWidth,
                  child: Padding(
                    padding: EdgeInsets.only(left: AppSpacing.sm),
                    child: Material(
                      color: context.colors.error,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        onTap: () {
                          _close();
                          widget.onDelete();
                        },
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              AppSpacing.xxs.h,
                              const Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Foreground Card that slides left
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = -_controller.value * widget.actionWidth;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              final newExtent = (_dragExtent - details.primaryDelta!)
                  .clamp(0.0, widget.actionWidth);
              if (newExtent != _dragExtent) {
                _dragExtent = newExtent;
                _controller.value = _dragExtent / widget.actionWidth;
              }
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -300) {
                _open();
              } else if (velocity > 300) {
                _close();
              } else if (_dragExtent > widget.actionWidth / 2) {
                _open();
              } else {
                _close();
              }
            },
            onTap: () {
              if (_controller.value > 0) {
                _close();
              }
            },
            child: Material(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
