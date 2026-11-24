import 'package:flutter/material.dart';

import '/core/extensions/context.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/users/data/models/bodyguard.model.dart';
import '/shared/widgets/sections/app_image.dart';

/// Round photo of a company-managed bodyguard, or the first letter of its
/// name when it has none.
class CompanyBodyguardAvatar extends StatelessWidget {
  const CompanyBodyguardAvatar({
    super.key,
    required this.bodyguard,
    required this.size,
  });

  final BodyguardModel bodyguard;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = bodyguard.profileImageUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primary.withValues(alpha: 0.1),
      ),
      child: url != null && url.isNotEmpty
          ? ClipOval(
              child: AppImage.network(
                key: ValueKey('${bodyguard.id}_${url}_${bodyguard.updatedAt}'),
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            )
          : Center(
              child: Text(
                bodyguard.name.isNotEmpty
                    ? bodyguard.name.characters.first.toUpperCase()
                    : 'B',
                style: context.textTheme.titleSmall?.bold().colour(
                  colors.primary,
                ),
              ),
            ),
    );
  }
}
