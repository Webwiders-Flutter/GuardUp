import 'package:flutter/material.dart';

import '/gen/assets.gen.dart';

/// GuardUp brand logo.
///
/// By default renders the square shield mark (used in the sidebar, login,
/// headers and favicon). Set [full] to render the full logo with the
/// "GUARDUP" wordmark, which is best on dark backgrounds.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40, this.full = false});

  /// Height of the logo. The width follows the image's aspect ratio.
  final double size;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final asset = full ? Assets.images.appLogo : Assets.images.appLogoMark;
    return asset.image(
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'GuardUp',
    );
  }
}
