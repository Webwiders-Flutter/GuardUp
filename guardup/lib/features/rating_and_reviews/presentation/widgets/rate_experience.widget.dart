import 'package:flutter/material.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/data/model/body_guard.model.dart';
import '/features/booking/data/model/booking.model.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_dialog.dart';
import '/shared/widgets/feedbacks/widgets/app_sheet.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_image.dart';
import '../../data/model/review.model.dart';
import '/features/body_guard/data/fixtures/bodyguard.fixtures.dart';

/// Interactive modal widget enabling clients to submit a bodyguard star rating
/// and textual review.
///
/// Supports standard embed, dialog presentation ([RateExperienceWidget.dialog]),
/// and bottom sheet presentation ([RateExperienceWidget.sheet]), as well as static
/// launcher methods [RateExperienceWidget.showDialog] and [RateExperienceWidget.showSheet].
class RateExperienceWidget extends StatefulWidget {
  final BodyGuardModel? bodyguard;
  final BookingModel? booking;
  final String? vettedPercentage;
  final double initialRating;
  final String? initialReview;
  final bool isDialog;
  final void Function(double rating, String review)? onSubmit;

  const RateExperienceWidget({
    super.key,
    this.bodyguard,
    this.booking,
    this.vettedPercentage = '99.8%',
    this.initialRating = 0.0,
    this.initialReview,
    this.isDialog = false,
    this.onSubmit,
  });

  /// Named constructor configured for modal dialog display.
  const RateExperienceWidget.dialog({
    super.key,
    this.bodyguard,
    this.booking,
    this.vettedPercentage = '99.8%',
    this.initialRating = 0.0,
    this.initialReview,
    this.onSubmit,
  }) : isDialog = true;

  /// Named constructor configured for bottom sheet display.
  const RateExperienceWidget.sheet({
    super.key,
    this.bodyguard,
    this.booking,
    this.vettedPercentage = '99.8%',
    this.initialRating = 0.0,
    this.initialReview,
    this.onSubmit,
  }) : isDialog = false;

  /// Displays the rate experience card inside a centered modal dialog.
  static Future<ReviewModel?> showDialog({
    required BuildContext context,
    BodyGuardModel? bodyguard,
    BookingModel? booking,
    String? vettedPercentage,
    double initialRating = 0.0,
    String? initialReview,
    void Function(double rating, String review)? onSubmit,
  }) {
    return AppDialogs.show<ReviewModel?>(
      context: context,
      showHeader: false,
      padding: EdgeInsets.zero,
      backgroundColor: context.colors.transparent,
      child: RateExperienceWidget.dialog(
        bodyguard: bodyguard,
        booking: booking,
        vettedPercentage: vettedPercentage,
        initialRating: initialRating,
        initialReview: initialReview,
        onSubmit: onSubmit,
      ),
    );
  }

  /// Displays the rate experience card inside an interactive bottom sheet.
  static Future<ReviewModel?> showSheet({
    required BuildContext context,
    BodyGuardModel? bodyguard,
    BookingModel? booking,
    String? vettedPercentage,
    double initialRating = 0.0,
    String? initialReview,
    void Function(double rating, String review)? onSubmit,
  }) {
    return AppSheet.show<ReviewModel?>(
      context: context,
      showHeader: false,
      showHandle: true,
      padding: EdgeInsets.zero,
      backgroundColor: context.colors.surface,
      child: RateExperienceWidget.sheet(
        bodyguard: bodyguard,
        booking: booking,
        vettedPercentage: vettedPercentage,
        initialRating: initialRating,
        initialReview: initialReview,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<RateExperienceWidget> createState() => _RateExperienceWidgetState();
}

class _RateExperienceWidgetState extends State<RateExperienceWidget> {
  late final _ratingNotifier = ValueNotifier<double>(widget.initialRating);
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _ratingNotifier.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final rating = _ratingNotifier.value;
    final reviewText = _reviewController.text.trim();

    final targetGuard =
        widget.bodyguard ??
        widget.booking?.bodyguard ??
        bodyguardPlaceholders.first;

    final review = ReviewModel(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      from: const UserModel(
        id: 'usr_me',
        name: 'Client Account',
        role: UserRole.customer,
      ),
      to: UserModel(
        id: targetGuard.userId ?? targetGuard.id,
        name: targetGuard.name,
        profileImageUrl: targetGuard.profileImageUrl,
        role: UserRole.guard,
      ),
      rating: rating > 0 ? rating : 5.0,
      reviewDescription: reviewText.isNotEmpty
          ? reviewText
          : 'Professional, punctual, and reliable bodyguard service.',
      createdAt: DateTime.now(),
      bookingId: widget.booking?.bookingNumber ?? '#9878213',
      serviceTag: widget.booking?.bodyguardSpecialization ?? 'Close Protection',
    );

    widget.onSubmit?.call(review.rating, review.reviewDescription);
    Navigator.of(context).pop(review);
  }

  @override
  Widget build(BuildContext context) {
    final guard =
        widget.bodyguard ??
        widget.booking?.bodyguard ??
        bodyguardPlaceholders.first;
    final avatarUrl = guard.profileImageUrl;
    final isNetworkAvatar = avatarUrl != null && avatarUrl.startsWith('http');
    final guardName = guard.name;
    final guardSpecialization =
        widget.booking?.bodyguardSpecialization ??
        (guard.bio.isNotEmpty
            ? guard.bio
            : 'VIP Protection Specialist, Level IV Tier');

    return QuickContainer(
      radius: widget.isDialog ? AppRadius.round : AppRadius.xl,
      color: context.colors.surfaceDim,
      border: Border.all(
        color: context.colors.primary.withValues(alpha: 0.6),
        width: 1.5,
      ),
      p: AppSpacing.xl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------------------------------------------------------------------
          // 1. Header Title
          // -------------------------------------------------------------------
          Text(
            'Rate Your Experience',
            textAlign: TextAlign.center,
            style: context.textTheme.headlineMedium
                ?.bold()
                .colour(context.colors.primary)
                .decreaseSize(2),
          ),
          AppSpacing.lg.h,

          // -------------------------------------------------------------------
          // 2. Operative Profile Summary Card
          // -------------------------------------------------------------------
          QuickContainer(
            radius: AppRadius.md,
            color: context.colors.surfaceContainerHigh.withValues(alpha: 0.5),
            border: Border.all(
              color: context.colors.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
            p: AppSpacing.sm,
            child: Row(
              children: [
                // Operative Avatar (Squircle)
                isNetworkAvatar
                    ? AppImage.network(
                        imageUrl: avatarUrl,
                        width: AppSizes.avatarSmd,
                        height: AppSizes.avatarSmd,
                        fit: BoxFit.cover,
                        borderRadius: AppRadius.sm.toBorderRadius,
                      )
                    : AppImage.asset(
                        assetPath:
                            avatarUrl ?? Assets.images.profilePicture.path,
                        width: AppSizes.avatarSmd,
                        height: AppSizes.avatarSmd,
                        fit: BoxFit.cover,
                        borderRadius: AppRadius.sm.toBorderRadius,
                      ),
                AppSpacing.md.w,

                // Operative Name & Clearance Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              guardName,
                              style: context.textTheme.bodyMedium?.bold(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppSpacing.xs.w,
                          Icon(
                            Icons.check_circle_rounded,
                            size: AppSizes.iconSm,
                            color: context.colors.success,
                          ),
                        ],
                      ),
                      AppSpacing.xxs.h,
                      Text(
                        guardSpecialization,
                        style: context.textTheme.labelSmall?.regular().colour(
                          context.colors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppSpacing.sm.w,

                // Vetted % Statistic
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vetted',
                      style: context.textTheme.labelSmall?.colour(
                        context.colors.onSurfaceTertiary,
                      ),
                    ),
                    AppSpacing.xxs.h,
                    Text(
                      widget.vettedPercentage ?? '99.8%',
                      style: context.textTheme.labelMedium?.colour(
                        context.colors.onSurfaceTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.xl.h,

          // -------------------------------------------------------------------
          // 3. Interactive Star Rating Selector
          // -------------------------------------------------------------------
          ValueListenableBuilder<double>(
            valueListenable: _ratingNotifier,
            builder: (context, currentRating, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isFilled = currentRating >= starIndex;

                  return GestureDetector(
                    onTap: () => _ratingNotifier.value = starIndex.toDouble(),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.star_rounded,
                      size: AppSizes.iconHuge,
                      color: isFilled
                          ? context.colors.primary
                          : context.colors.outline.withValues(alpha: 0.35),
                    ),
                  );
                }),
              );
            },
          ),
          AppSpacing.xl.h,

          // -------------------------------------------------------------------
          // 4. Write Review Text Field
          // -------------------------------------------------------------------
          AppTextField(
            controller: _reviewController,
            decoration: const InputDecoration(hintText: 'Type here.....'),
            maxLines: 4,
            minLines: 4,
            fillColor: Color(0xFF3C3C3C),
          ),
          AppSpacing.xl.h,

          // -------------------------------------------------------------------
          // 5. Submit CTA Button
          // -------------------------------------------------------------------
          Center(
            child: AppButton(
              text: 'Submit',
              width: 32.wPercent(context),
              size: ButtonSize.normal,
              onPressed: _handleSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
