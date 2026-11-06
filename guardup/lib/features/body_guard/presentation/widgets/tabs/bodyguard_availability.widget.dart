import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '../../../data/enum/week_day.enum.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '/shared/widgets/selection/selection.controller.dart';

/// Tab content widget allowing bodyguards to manage their active weekly
/// availability hours and designated days off.
class BodyguardAvailabilityWidget extends StatefulWidget {
  final ValueChanged<List<WeekDay>>? onAvailabilityChanged;

  const BodyguardAvailabilityWidget({super.key, this.onAvailabilityChanged});

  @override
  State<BodyguardAvailabilityWidget> createState() =>
      _BodyguardAvailabilityWidgetState();
}

class _BodyguardAvailabilityWidgetState
    extends State<BodyguardAvailabilityWidget> {
  late final _selectionController = SelectionController<WeekDay>.multi(
    initial: const [
      WeekDay.monday,
      WeekDay.tuesday,
      WeekDay.thursday,
      WeekDay.friday,
      WeekDay.sunday,
    ],
    onChanged: widget.onAvailabilityChanged,
  );

  final Map<WeekDay, TextEditingController> _fromControllers = {
    for (final day in WeekDay.values)
      day: TextEditingController(text: '09:00 AM'),
  };

  final Map<WeekDay, TextEditingController> _toControllers = {
    for (final day in WeekDay.values)
      day: TextEditingController(text: '12:00 PM'),
  };

  @override
  void dispose() {
    _selectionController.dispose();
    for (final controller in _fromControllers.values) {
      controller.dispose();
    }
    for (final controller in _toControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime({
    required BuildContext context,
    required TextEditingController controller,
    required TimeOfDay initialTime,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null && mounted) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      controller.text = '${hour.toString().padLeft(2, '0')}:$minute $period';
    }
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final period = parts.length > 1 ? parts[1].toUpperCase() : 'AM';

      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  Widget _buildTimeInputField({
    required BuildContext context,
    required TextEditingController controller,
    required bool isHighlighted,
  }) {
    return SizedBox(
      width: 100,
      child: AppTextField(
        controller: controller,
        readOnly: true,
        size: AppInputSize.small,
        onTap: () => _pickTime(
          context: context,
          controller: controller,
          initialTime: _parseTime(controller.text),
        ),
        style: context.textTheme.labelSmall?.regular().colour(
          context.colors.outlineVariant,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: context.colors.onSurface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 0,
            vertical: AppSpacing.ssm,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 5.0, right: 5),
            child: Icon(
              Icons.access_time_filled,
              size: AppSizes.iconSm,
              color: context.colors.outline,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            maxWidth: 20,
            maxHeight: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDayOffBadge(
    BuildContext context, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: QuickContainer(
        radius: AppRadius.sm,
        color: const Color(0xFF7A7D84),
        px: AppSpacing.lg,
        py: AppSpacing.sm,
        child: Text(
          'Day Off',
          style: context.textTheme.labelSmall?.colour(
            context.colors.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCircle({
    required BuildContext context,
    required bool isSelected,
  }) {
    if (isSelected) {
      return QuickContainer(
        shape: QuickContainerShape.circle,
        color: context.colors.primary,
        p: 2,
        child: Icon(
          Icons.check_rounded,
          size: AppSizes.iconXs,
          color: context.colors.onPrimary,
        ),
      );
    }
    return QuickContainer(
      shape: QuickContainerShape.circle,
      color: context.colors.transparent,
      border: Border.all(
        color: context.colors.onSurfaceVariant.withValues(alpha: 0.6),
        width: 1.5,
      ),
      w: 18,
      h: 18,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacing.md.h,
        // ---------------------------------------------------------------------
        // Header Section
        // ---------------------------------------------------------------------
        Text(
          'Select your Availability',
          style: context.textTheme.titleMedium?.semiBold(),
        ),
        AppSpacing.xxs.h,
        Text(
          'Select Week day and Set time for each selected day',
          style: context.textTheme.bodySmall?.colour(
            context.colors.onSurfaceVariant,
          ),
        ),
        AppSpacing.xl.h,

        // ---------------------------------------------------------------------
        // Weekly Day Cards List
        // ---------------------------------------------------------------------
        ValueListenableBuilder<List<WeekDay>>(
          valueListenable: _selectionController,
          builder: (context, selectedDays, _) {
            return Column(
              children: WeekDay.values.map((day) {
                final isSelected = selectedDays.contains(day);
                final fromController = _fromControllers[day]!;
                final toController = _toControllers[day]!;
                // Tuesday to-time is highlighted to reflect active input focus
                final isTuesdayToTime = day == WeekDay.tuesday;

                return Padding(
                  padding: AppSpacing.md.bPadding,
                  child: WrapperCard(
                    padding: .symmetric(horizontal: 12, vertical: 20),
                    onTap: () => _selectionController.toggle(day),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        05.w,
                        // Left: Checkbox Icon + Weekday Label
                        _buildSelectionCircle(
                          context: context,
                          isSelected: isSelected,
                        ),
                        AppSpacing.sm.w,
                        Expanded(
                          child: Text(
                            day.label,
                            style: context.textTheme.bodyMedium
                                ?.semiBold()
                                .decreaseSize(1),
                          ),
                        ),
                        AppSpacing.xs.w,

                        // Right: Time Inputs or Day Off Badge
                        if (isSelected)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTimeInputField(
                                context: context,
                                controller: fromController,
                                isHighlighted: false,
                              ),
                              Padding(
                                padding: AppSpacing.xs.xPadding,
                                child: Text(
                                  '-',
                                  style: context.textTheme.bodyMedium
                                      ?.bold()
                                      .colour(context.colors.onSurfaceVariant),
                                ),
                              ),
                              _buildTimeInputField(
                                context: context,
                                controller: toController,
                                isHighlighted: isTuesdayToTime,
                              ),
                            ],
                          )
                        else
                          _buildDayOffBadge(
                            context,
                            onTap: () => _selectionController.toggle(day),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        AppSpacing.xl.h,
      ],
    );
  }
}
