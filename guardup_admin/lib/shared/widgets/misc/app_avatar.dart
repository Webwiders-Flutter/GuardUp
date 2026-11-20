import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_layout.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/string.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import 'app_badge.dart';

/// Circular initials avatar with an optional presence dot.
///
/// Initials come from [name] (`"Jane Doe"` → `JD`); a person icon is shown
/// when the name is blank.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.size = AppLayout.avatarMd,
    this.color,
    this.statusColor,
  });

  final String name;
  final double size;

  /// Accent used for the tinted fill, ring and initials. Defaults to
  /// `context.colors.primary`.
  final Color? color;

  /// When set, renders a presence dot in the bottom-right corner.
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.colors.primary;
    final initials = name.initials();

    final avatar = QuickContainer(
      w: size,
      h: size,
      shape: QuickContainerShape.circle,
      alignment: Alignment.center,
      color: accent.withValues(alpha: 0.14),
      border: Border.all(color: accent.withValues(alpha: 0.32)),
      child: initials.isEmpty
          ? Icon(Icons.person_rounded, size: size * 0.5, color: accent)
          : Text(
              initials,
              style: context.textTheme.labelMedium
                  ?.size(size * 0.36)
                  .bold()
                  .colour(accent),
            ),
    );

    if (statusColor == null) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: AppBadge.dot(
            color: statusColor,
            ringColor: context.colors.surface,
          ),
        ),
      ],
    );
  }
}
