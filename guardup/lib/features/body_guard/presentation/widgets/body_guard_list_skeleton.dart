import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/spacing.extension.dart';
import '/shared/widgets/misc/skeleton_effect.dart';
import '../../data/model/body_guard.model.dart';
import 'body_guard_card.dart';

/// Shimmer placeholder for a bodyguard list while the first page loads.
///
/// Use as `initialLoaderBuilder` of `AppPagination<BodyGuardModel>` (same
/// pattern as the notifications list).
class BodyGuardListSkeleton extends StatelessWidget {
  /// Number of placeholder cards.
  final int itemCount;

  const BodyGuardListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final samples = BodyGuardModel.fakeData;

    return Skeletonizer(
      effect: SkeletonEffect.adaptiveShimmer(context),
      enabled: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding: index == itemCount - 1
                  ? EdgeInsets.zero
                  : AppSpacing.md.bPadding,
              child: BodyGuardCard(
                bodyguard: samples[index % samples.length],
                role: samples[index % samples.length].user.role,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
