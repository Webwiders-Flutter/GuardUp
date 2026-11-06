import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_radius.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '/app/routes/app_routes.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_dropdown.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/misc/app_input_label.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/selection/selection.dart';
import '../../data/enum/guard_service.enum.dart';

/// Screen for bodyguard profile setup / entering professional details.
///
/// Follows GuardUp Development Rules & Architectural Guidelines:
/// - State Management: [ValueNotifier] & [ValueListenableBuilder] over `setState()`.
/// - Localization: all user-facing strings accessed via [context.l10n].
/// - Theming & Tokens: strict adherence to [context.colors], [context.textTheme], and [AppSpacing].
/// - Form Layout: [LayoutBuilder] + [ConstrainedBox] + [IntrinsicHeight] + [Spacer] onboarding pattern.
class BodyGuardCompleteProfileScreen extends StatefulWidget {
  static const route = '/bodyguard-profile';

  const BodyGuardCompleteProfileScreen({super.key});

  @override
  State<BodyGuardCompleteProfileScreen> createState() =>
      _BodyGuardCompleteProfileScreenState();
}

class _BodyGuardCompleteProfileScreenState
    extends State<BodyGuardCompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController(text: 'Vikram Singh');
  final _hourlyRateController = TextEditingController(text: '60');
  final _bioController = TextEditingController();

  final _serviceDropdownController = SelectionController<GuardService>.multi(
    initial: const [
      GuardService.vipCloseProtection,
      GuardService.armedEscort,
      GuardService.tacticalDriver,
    ],
  );

  /// Isolated avatar profile picture notifier matching edit profile UI.
  final ValueNotifier<XFile?> _profileImageNotifier = ValueNotifier<XFile?>(
    null,
  );

  @override
  void dispose() {
    _fullNameController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    _serviceDropdownController.dispose();
    _profileImageNotifier.dispose();
    super.dispose();
  }

  /// Profile picture picker matching edit profile logic exactly.
  Future<void> _handleChangePhoto() async {
    final pickedFile = await AppMediaPickerSheet.show(
      context: context,
      allowCrop: true,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.original,
      ],
      lockAspectRatio: false,
    );

    if (pickedFile != null && mounted) {
      _profileImageNotifier.value = pickedFile;
    }
  }

  void _handleRemoveService(GuardService service) {
    _serviceDropdownController.toggle(service);
  }

  void _handleNext() {
    // if (!(_formKey.currentState?.validate() ?? false)) return;

    // Navigate to next onboarding step (documents upload)
    context.push(AppRoutes.bodyguardUploadDocuments);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        title: sl<AuthBloc>().state.isAuthenticated
            ? context.l10n.addBodyguard
            : context.l10n.profileSetupTitle,
        fontSize: 14,
        
        alignTitle: sl<AuthBloc>().state.isAuthenticated ? .right : .center,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: context.horizontalEdgeInsets,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSpacing.xxl.h,

                        // 1. Profile Picture (Dashed Circular Border Picker)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: _handleChangePhoto,
                                    behavior: HitTestBehavior.opaque,
                                    child: CustomPaint(
                                      painter: _DashedCirclePainter(
                                        color: context.colors.primary,
                                        strokeWidth: 1,
                                        dashLength: 7.5,
                                        gapLength: 6.0,
                                      ),
                                      child: Container(
                                        width: 110,
                                        height: 110,
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: context.colors.onPrimary,
                                          ),
                                          child: ValueListenableBuilder<XFile?>(
                                            valueListenable:
                                                _profileImageNotifier,
                                            builder: (context, profileImage, _) {
                                              if (profileImage != null) {
                                                return ClipOval(
                                                  child: AppImage.xFile(
                                                    xFile: profileImage,
                                                    width: 108,
                                                    height: 108,
                                                    fit: BoxFit.cover,
                                                  ),
                                                );
                                              }

                                              return Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .person_outline_rounded,
                                                    size: 38,
                                                    color:
                                                        context.colors.outline,
                                                  ),
                                                  6.h,
                                                  Text(
                                                    'Add Photo',
                                                    style: context
                                                        .textTheme
                                                        .labelSmall
                                                        ?.regular()
                                                        .copyWith(
                                                          fontSize: 10.0,
                                                          letterSpacing: 0.2,
                                                        )
                                                        .colour(
                                                          context
                                                              .colors
                                                              .primary,
                                                        ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Plus Icon Badge at Bottom Right
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: GestureDetector(
                                      onTap: _handleChangePhoto,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              context.colors.primaryContainer,
                                          border: Border.all(
                                            color: context.colors.surface,
                                            width: 3.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.35,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.add_rounded,
                                          size: 22,
                                          color: context.colors.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.smd.h,
                              Text(
                                context.l10n.uploadPortraitGuidance,
                                style: context.textTheme.labelMedium
                                    ?.regular()
                                    .colour(context.colors.outline),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.xxl.h,

                        // 2. Full Name Field
                        AppFieldLabel(text: context.l10n.fullNameLabel),
                        AppSpacing.sm.h,
                        AppTextField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            hintText: 'Enter Full Name',
                            fillColor: context.colors.onPrimary,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.md.toBorderRadius,
                              borderSide: BorderSide(
                                color: context.colors.outlineVariant,
                              ),
                            ),
                          ),
                          style: TextStyle(color: context.colors.onSurface),
                          textInputAction: TextInputAction.next,
                        ),
                        AppSpacing.xxl.h,

                        // 3. Hourly Rate Field
                        AppFieldLabel(text: context.l10n.hourlyRateLabel),
                        AppSpacing.sm.h,
                        AppTextField(
                          controller: _hourlyRateController,

                          decoration: InputDecoration(
                            hintText: "Enter Hourly Rate",
                            prefix: Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.xs,
                                right: AppSpacing.sm,
                              ),
                              child: Text(
                                r'$',
                                style: context.textTheme.titleMedium
                                    ?.bold()
                                    .colour(context.colors.primary),
                              ),
                            ),
                            suffix: Text(
                              context.l10n.perHour,
                              style: context.textTheme.bodyMedium?.colour(
                                context.colors.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.md.toBorderRadius,
                              borderSide: BorderSide(
                                color: context.colors.outlineVariant,
                              ),
                            ),
                            fillColor: context.colors.onPrimary,
                          ),
                          style: TextStyle(color: context.colors.onSurface),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.required(context, value),
                        ),
                        AppSpacing.xxl.h,

                        // 4. Services Offered Section (Isolated rebuild with ValueListenableBuilder)
                        ValueListenableBuilder(
                          valueListenable: _serviceDropdownController,
                          builder: (context, selectedServices, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    AppFieldLabel(
                                      text: context.l10n.servicesOfferedLabel,
                                    ),
                                    Text(
                                      context.l10n.selectedServicesCount(
                                        selectedServices.length,
                                      ),
                                      style: context.textTheme.labelSmall
                                          ?.bold()
                                          .colour(context.colors.primary),
                                    ),
                                  ],
                                ),
                                if (selectedServices.isNotEmpty) ...[
                                  AppSpacing.lg.h,
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: selectedServices.map((service) {
                                      return AppRemovableChip(
                                        text: service.label,
                                        onRemove: () =>
                                            _handleRemoveService(service),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                AppSpacing.lg.h,
                                AppDropdown<GuardService>(
                                  controller: _serviceDropdownController,
                                  hintText: context.l10n.selectService,
                                  closeOnSelect: true,
                                  target: (fieldKey) {
                                    return AppTextField(
                                      key: fieldKey,
                                      readOnly: true,

                                      decoration: InputDecoration(
                                        hintText: context.l10n.selectService,
                                        suffixIcon: Icon(
                                          Icons.expand_more,
                                          color: context.colors.outline,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              AppRadius.md.toBorderRadius,
                                          borderSide: BorderSide(
                                            color:
                                                context.colors.outlineVariant,
                                          ),
                                        ),
                                        fillColor: context.colors.onPrimary,
                                      ),
                                      style: TextStyle(
                                        color: context.colors.onSurface,
                                      ),
                                    );
                                  },
                                  items: GuardService.values
                                      .where(
                                        (s) => !selectedServices.contains(s),
                                      )
                                      .map(
                                        (e) => DropdownItem<GuardService>(
                                          id: e,
                                          data: e.label,
                                          icon: Icon(
                                            e.icon,
                                            size: AppSizes.iconSmd,
                                            color: context.colors.primary,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            );
                          },
                        ),
                        AppSpacing.xxl.h,

                        // 5. Bio & Background Field
                        AppFieldLabel(text: context.l10n.bioBackgroundLabel),
                        AppSpacing.sm.h,
                        AppTextField(
                          controller: _bioController,

                          decoration: InputDecoration(
                            hintText: context.l10n.bioBackgroundHint,
                            fillColor: context.colors.onPrimary,
                          ),
                          style: TextStyle(color: context.colors.onSurface),
                          maxLines: 4,
                          minLines: 4,
                          textInputAction: TextInputAction.done,
                        ),

                        const Spacer(),
                        AppSpacing.xxl.h,

                        // 6. Next Action Button
                        AppButton(
                          text: context.l10n.next,
                          trailing: Icon(
                            Icons.arrow_forward_rounded,
                            size: AppSizes.iconMd,
                            color: context.colors.onPrimary,
                          ),

                          onPressed: _handleNext,
                        ),
                        AppSpacing.xxl.h,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter that draws a thick, bold circular dashed border.
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const _DashedCirclePainter({
    required this.color,
    this.strokeWidth = 4.5,
    this.dashLength = 10.5,
    this.gapLength = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * math.pi * radius;

    final dashCount = (circumference / (dashLength + gapLength)).floor();
    if (dashCount == 0) return;

    final totalDashLength = dashCount * dashLength;
    final totalGapLength = circumference - totalDashLength;
    final actualGap = totalGapLength / dashCount;

    final dashAngle = dashLength / radius;
    final gapAngle = actualGap / radius;

    // Center one dash segment directly at 12 o'clock
    double currentAngle = -math.pi / 2 - (dashAngle / 2);
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        dashAngle,
        false,
        paint,
      );
      currentAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}
