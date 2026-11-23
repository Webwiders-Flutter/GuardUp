import 'package:flutter/material.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:guardup/gen/assets.gen.dart';
import 'package:quick_container/quick_container.dart';

import '../../../data/model/body_guard.model.dart';
import '../../../data/model/service_item.model.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/sections/wrapper_card.dart';

/// Tab content widget displaying bodyguard bio, key operational details,
/// and manageable security services.
class BodyguardAboutWidget extends StatefulWidget {
  final BodyGuardModel? bodyguard;
  final String? bio;
  final num? hourlyRate;
  final int? experienceYears;
  final String? location;
  final String? languages;
  final String? certifications;
  final List<ServiceItemModel>? services;
  final VoidCallback? onEditBio;
  final VoidCallback? onEditKeyDetails;
  final VoidCallback? onEditServices;

  const BodyguardAboutWidget({
    super.key,
    this.bodyguard,
    this.bio,
    this.hourlyRate,
    this.experienceYears,
    this.location,
    this.languages,
    this.certifications,
    this.services,
    this.onEditBio,
    this.onEditKeyDetails,
    this.onEditServices,
  });

  @override
  State<BodyguardAboutWidget> createState() => _BodyguardAboutWidgetState();
}

class _BodyguardAboutWidgetState extends State<BodyguardAboutWidget> {
  final _isBioExpandedNotifier = ValueNotifier<bool>(false);

  static const String _defaultBio =
      'I am a professional and certified bodyguard with extensive experience '
      'in personal protection, executive security, and close protection. '
      'I am trained in situational awareness, conflict management, and tactical defense.';

  @override
  void dispose() {
    _isBioExpandedNotifier.dispose();
    super.dispose();
  }

  Widget _buildEditPencilButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: QuickContainer(
        shape: QuickContainerShape.circle,
        color: context.colors.surfaceContainerHigh.withValues(alpha: 0.6),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
        p: AppSpacing.xs,
        child: Icon(
          Icons.edit_outlined,
          size: AppSizes.iconXs,
          color: context.colors.primary,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required SvgGenImage icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon.svg(
          width: AppSizes.iconSmd,
          height: AppSizes.iconSmd,
          colorFilter: ColorFilter.mode(
            context.colors.primary,
            BlendMode.srcIn,
          ),
        ),
        AppSpacing.sm.w,
        Text(
          label,
          style: context.textTheme.bodySmall?.colour(
            context.colors.onSurfaceVariant,
          ),
        ),
        AppSpacing.md.w,
        Expanded(
          child: Text(
            value,
            style: context.textTheme.bodySmall?.semiBold(),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bioText = widget.bio?.isNotEmpty == true
        ? widget.bio!
        : (widget.bodyguard?.bio.isNotEmpty == true
              ? widget.bodyguard!.bio
              : _defaultBio);

    final selectedServices = widget.services ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacing.sm.h,
        // ---------------------------------------------------------------------
        // 1. Bio Card
        // ---------------------------------------------------------------------
        WrapperCard(
          padding: AppSpacing.lg.allPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isBioExpandedNotifier,
                      builder: (context, isExpanded, _) {
                        return Text(
                          bioText,
                          maxLines: isExpanded ? null : 4,
                          overflow: isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.lineHeight(1.8),
                        );
                      },
                    ),
                  ),
                  AppSpacing.sm.w,
                  _buildEditPencilButton(onTap: widget.onEditBio ?? () {}),
                ],
              ),
              AppSpacing.sm.h,
              ValueListenableBuilder<bool>(
                valueListenable: _isBioExpandedNotifier,
                builder: (context, isExpanded, _) {
                  return GestureDetector(
                    onTap: () => _isBioExpandedNotifier.value =
                        !_isBioExpandedNotifier.value,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isExpanded ? 'Show Less' : 'Read More',
                          style: context.textTheme.labelMedium?.colour(
                            context.colors.primary,
                          ),
                        ),
                        AppSpacing.xxs.w,
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.chevron_right_rounded,
                          size: AppSizes.iconXs,
                          color: context.colors.primary,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        AppSpacing.xl.h,

        // ---------------------------------------------------------------------
        // 2. Key Details Section
        // ---------------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Key Details',
              style: context.textTheme.titleMedium?.semiBold(),
            ),
            _buildEditPencilButton(onTap: widget.onEditKeyDetails ?? () {}),
          ],
        ),
        AppSpacing.md.h,
        WrapperCard(
          padding: AppSpacing.lg.allPadding,
          child: Column(
            children: [
              _buildDetailRow(
                context: context,
                icon: Assets.svg.work,
                label: 'Experience',
                value:
                    widget.experienceYears != null &&
                        widget.experienceYears! > 0
                    ? '${widget.experienceYears}+ Years'
                    : '0 Years',
              ),
              AppSpacing.md.h,
              _buildDetailRow(
                context: context,
                icon: Assets.svg.dollar,
                label: 'Hourly Rate',
                value: widget.hourlyRate != null && widget.hourlyRate! > 0
                    ? '${widget.hourlyRate!.toUsd} / hr'
                    : '\$0.00 / hr',
              ),
              AppSpacing.md.h,
              _buildDetailRow(
                context: context,
                icon: Assets.svg.location,
                label: 'Service Areas',
                value: widget.location?.isNotEmpty == true
                    ? widget.location!
                    : 'Not specified',
              ),
              AppSpacing.md.h,
              _buildDetailRow(
                context: context,
                icon: Assets.svg.language,
                label: 'Languages',
                value: widget.languages?.isNotEmpty == true
                    ? widget.languages!
                    : 'Not specified',
              ),
              AppSpacing.md.h,
              _buildDetailRow(
                context: context,
                icon: Assets.svg.certificate,
                label: 'Certifications',
                value: widget.certifications?.isNotEmpty == true
                    ? widget.certifications!
                    : 'Not specified',
              ),
            ],
          ),
        ),
        AppSpacing.xl.h,

        // ---------------------------------------------------------------------
        // 3. Services Section
        // ---------------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Services', style: context.textTheme.titleMedium?.semiBold()),
            _buildEditPencilButton(onTap: widget.onEditServices ?? () {}),
          ],
        ),
        AppSpacing.md.h,

        // Selected Service Chips
        if (selectedServices.isNotEmpty)
          Wrap(
            spacing: AppSpacing.smd,
            runSpacing: AppSpacing.smd,
            children: selectedServices.map((service) {
              return QuickContainer(
                radius: AppRadius.sm,
                gradient: context.colors.primaryGradient,
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.35),
                  width: 1,
                ),
                px: AppSpacing.md,
                py: AppSpacing.xs,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon(
                    //   service.icon,
                    //   size: AppSizes.iconXs,
                    //   color: context.colors.primary,
                    // ),
                    // AppSpacing.xs.w,
                    Text(
                      service.name,
                      style: context.textTheme.labelMedium?.semiBold().colour(
                        Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        else if (widget.bodyguard?.serviceTypes.isNotEmpty == true)
          Wrap(
            spacing: AppSpacing.smd,
            runSpacing: AppSpacing.smd,
            children: widget.bodyguard!.serviceTypes.map((service) {
              return QuickContainer(
                radius: AppRadius.sm,
                color: context.colors.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.35),
                  width: 1,
                ),
                px: AppSpacing.md,
                py: AppSpacing.xs,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      service.icon,
                      size: AppSizes.iconXs,
                      color: context.colors.primary,
                    ),
                    AppSpacing.xs.w,
                    Text(
                      service.label,
                      style: context.textTheme.labelMedium?.semiBold().colour(
                        context.colors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        else
          Text(
            'No services selected yet. Tap the edit icon to add services.',
            style: context.textTheme.bodySmall?.colour(
              context.colors.onSurfaceVariant,
            ),
          ),
        AppSpacing.xl.h,
      ],
    );
  }
}
