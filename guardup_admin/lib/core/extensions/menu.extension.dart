import 'package:flutter/material.dart';

import '/core/constants/app_spacing.dart';

/// Where an anchored menu opens relative to its trigger.
enum MenuPlacement {
  /// Below the trigger, left edges aligned (toolbar buttons, profile pill).
  below,

  /// To the right of the trigger, top edges aligned (collapsed sidebar rail).
  end,
}

/// Opens a themed popup menu anchored to the widget that owns this context.
///
/// Lets any trigger (e.g. `AppIconButton`, a profile pill) open a menu without
/// being wrapped in [PopupMenuButton], which would draw its own ink and
/// disable the trigger's own hover states. Call it from the trigger's context:
///
/// ```dart
/// Builder(
///   builder: (anchor) => AppIconButton(
///     icon: Icons.more_vert_rounded,
///     onPressed: () => anchor.showAnchoredMenu(items: [...]),
///   ),
/// )
/// ```
extension AnchoredMenuExtension on BuildContext {
  Future<T?> showAnchoredMenu<T>({
    required List<PopupMenuEntry<T>> items,
    MenuPlacement placement = MenuPlacement.below,
    double gap = AppSpacing.sm,
    BoxConstraints? constraints,
  }) {
    final anchor = findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(this).overlay!.context.findRenderObject()! as RenderBox;

    final origin = switch (placement) {
      MenuPlacement.below => Offset(0, anchor.size.height + gap),
      MenuPlacement.end => Offset(anchor.size.width + gap, 0),
    };
    final topLeft = anchor.localToGlobal(origin, ancestor: overlay);

    return showMenu<T>(
      context: this,
      constraints: constraints,
      position: RelativeRect.fromRect(
        topLeft & anchor.size,
        Offset.zero & overlay.size,
      ),
      items: items,
    );
  }
}
