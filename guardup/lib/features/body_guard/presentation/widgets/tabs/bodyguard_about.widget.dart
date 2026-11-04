import 'package:flutter/material.dart';
import 'package:guardup/core/extensions/localization.extension.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:guardup/gen/assets.gen.dart';
import 'package:guardup/shared/widgets/inputs/app_text_field.dart';
import 'package:quick_container/quick_container.dart';

import '../../../data/enum/guard_service.enum.dart';
import '../../../data/model/body_guard.model.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_dropdown.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '/shared/widgets/selection/app_removable_chip.dart';
import '/shared/widgets/selection/selection.controller.dart';

/// Tab content widget displaying bodyguard bio, key operational details,
/// and manageable security services.
class BodyguardAboutWidget extends StatefulWidget {
  final BodyGuardModel? bodyguard;
  final VoidCallback? onEditBio;
  final VoidCallback? onEditKeyDetails;

  const BodyguardAboutWidget({
    super.key,
    this.bodyguard,
    this.onEditBio,
    this.onEditKeyDetails,
  });

  @override
  State<BodyguardAboutWidget> createState() => _BodyguardAboutWidgetState();
}

class _BodyguardAboutWidgetState extends State<BodyguardAboutWidget> {
  late final ValueNotifier<bool> _isBioExpandedNotifier;
  late final ValueNotifier<List<GuardService>> _selectedServicesNotifier;
  late final SelectionController<GuardService> _dropdownController;

  static const String _defaultBio =
      'I am a professional and certified bodyguard with over 8 years of '
      'experience in personal protection, executive security and close protection. '
      'I am trained in situational awareness, conflict management and first aid.';

  @override
  void initState() {
    super.initState();
    _isBioExpandedNotifier = ValueNotifier<bool>(false);

    final initialServices = widget.bodyguard?.serviceTypes.isNotEmpty == true
        ? widget.bodyguard!.serviceTypes
        : [
            GuardService.vipCloseProtection,
            GuardService.armedEscort,
            GuardService.tacticalDriver,
          ];

    _selectedServicesNotifier = ValueNotifier<List<GuardService>>(
      List.from(initialServices),
    );

    _dropdownController = SelectionController<GuardService>.single();
  }

  @override
  void dispose() {
    _isBioExpandedNotifier.dispose();
    _selectedServicesNotifier.dispose();
    _dropdownController.dispose();
    super.dispose();
  }

  void _handleRemoveService(GuardService service) {
    final updated = List<GuardService>.from(_selectedServicesNotifier.value)
      ..remove(service);
    _selectedServicesNotifier.value = updated;
  }

  void _handleAddService(GuardService? service) {
    if (service == null) return;
    if (!_selectedServicesNotifier.value.contains(service)) {
      final updated = List<GuardService>.from(_selectedServicesNotifier.value)
        ..add(service);
      _selectedServicesNotifier.value = updated;
    }
    _dropdownController.clear();
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
          width: 18,
          height: 18,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bioText = widget.bodyguard?.bio.isNotEmpty == true
        ? widget.bodyguard!.bio
        : _defaultBio;

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
                  _buildEditPencilButton(
                    onTap:
                        widget.onEditBio ??
                        () => AppSnackbar.info(
                          'Edit bio tapped',
                          context: context,
                        ),
                  ),
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
                          style: context.textTheme.labelMedium
                              ?.regular()
                              .colour(context.colors.primary),
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
            _buildEditPencilButton(
              onTap:
                  widget.onEditKeyDetails ??
                  () =>
                      AppSnackbar.info('Edit details tapped', context: context),
            ),
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
                value: '${widget.bodyguard?.experienceYears ?? 8}+ Years',
              ),
              AppSpacing.md.h,
              _buildDetailRow(
                context: context,
                icon: Assets.svg.dollar,
                label: 'Hourly Rate',
                value: widget.bodyguard != null
                    ? widget.bodyguard!.formattedHourlyRate
                    : '\$60 / hour',
              ),
              AppSpacing.md.h,
              _buildDetailRow(
                context: context,
                icon: Assets.svg.location,
                label: 'Service Areas',
                value: 'Toronto, ON & Surrounding Areas',
              ),
              AppSpacing.md.h,
              _buildDetailRow(
                context: context,
                icon: Assets.svg.language,
                label: 'Languages',
                value: 'English, Hindi, ',
              ),
              AppSpacing.md.h,
              _buildDetailRow(
                context: context,
                icon: Assets.svg.certificate,
                label: 'Certifications',
                value: 'CPR, First Aid, Security Training',
              ),
            ],
          ),
        ),
        AppSpacing.xl.h,

        // ---------------------------------------------------------------------
        // 3. Services Section
        // ---------------------------------------------------------------------
        Text(
          'Services',
          style: context.textTheme.titleMedium?.semiBold(),
        ),
        AppSpacing.sm.h,

        // Selected Service Chips
        ValueListenableBuilder<List<GuardService>>(
          valueListenable: _selectedServicesNotifier,
          builder: (context, selectedServices, _) {
            final availableServices = GuardService.values
                .where((s) => !selectedServices.contains(s))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selectedServices.isNotEmpty) ...[
                  Wrap(
                    spacing: AppSpacing.smd,
                    runSpacing: AppSpacing.smd,
                    children: selectedServices.map((service) {
                      return AppRemovableChip(
                        text: _formatServiceLabel(service),
                        onRemove: () => _handleRemoveService(service),
                      );
                    }).toList(),
                  ),
                  AppSpacing.md.h,
                ],

                // Dropdown to add more services
                AppDropdown<GuardService>(
                  controller: _dropdownController,
                  hintText: 'Select Service',
                  target: (fieldKey) {
                    return AppTextField(
                      key: fieldKey,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: context.l10n.selectService,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.lg.toBorderRadius,
                          borderSide: BorderSide(
                            color: context.colors.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.lg.toBorderRadius,
                          borderSide: BorderSide(
                            color: context.colors.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.lg.toBorderRadius,
                          borderSide: BorderSide(
                            color: context.colors.outlineVariant,
                          ),
                        ),
                        suffixIcon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: context.colors.onSurfaceVariant,
                        ),
                        fillColor: context.colors.onPrimary,
                      ),
                      );
                  },
                  items: availableServices
                      .map(
                        (s) => SelectableItem<GuardService, String>(
                          id: s,
                          data: _formatServiceLabel(s),
                          icon: Icon(
                            s.icon,
                            size: AppSizes.iconSm,
                            color: context.colors.primary,
                          ),
                        ),
                      )
                      .toList(),
                  onSelected: _handleAddService,
                ),
              ],
            );
          },
        ),
        AppSpacing.xl.h,
      ],
    );
  }

  static String _formatServiceLabel(GuardService service) {
    switch (service) {
      case GuardService.vipCloseProtection:
        return 'VIP Close Protection';
      case GuardService.armedEscort:
        return 'Armed Escort';
      case GuardService.tacticalDriver:
        return 'Tactical Driver';
      case GuardService.eventSecurity:
        return 'Event Security';
      case GuardService.residentialProtection:
        return 'Residential Protection';
      case GuardService.assetProtection:
        return 'Asset Protection';
      case GuardService.surveillanceRecon:
        return 'Surveillance & Recon';
      case GuardService.crisisManagement:
        return 'Crisis Management';
    }
  }
}
