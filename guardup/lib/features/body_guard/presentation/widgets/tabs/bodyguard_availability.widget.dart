import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quick_container/quick_container.dart';

import '../../../bloc/availability/availability_bloc.dart';
import '../../../data/enum/week_day.enum.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/body_guard/data/model/body_guard.model.dart';
import '/shared/models/record_owner.model.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/wrapper_card.dart';

/// Tab content widget allowing bodyguards to manage their active weekly
/// availability hours and designated days off dynamically via [AvailabilityBloc].
class BodyguardAvailabilityWidget extends StatelessWidget {
  final BodyGuardModel? bodyguard;
  final ValueChanged<List<WeekDay>>? onAvailabilityChanged;

  const BodyguardAvailabilityWidget({
    super.key,
    this.bodyguard,
    this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final owner = (bodyguard != null && bodyguard!.id.isNotEmpty)
        ? ManagedBodyguardOwner(bodyguard!.id)
        : AccountOwner(context.read<AuthBloc>().state.user?.id ?? '')
              as RecordOwner;

    return BlocProvider(
      create: (_) =>
          sl<AvailabilityBloc>(param1: owner)..add(const AvailabilityStarted()),
      child: _BodyguardAvailabilityView(
        owner: owner,
        onAvailabilityChanged: onAvailabilityChanged,
      ),
    );
  }
}

class _BodyguardAvailabilityView extends StatefulWidget {
  final RecordOwner owner;
  final ValueChanged<List<WeekDay>>? onAvailabilityChanged;

  const _BodyguardAvailabilityView({
    required this.owner,
    this.onAvailabilityChanged,
  });

  @override
  State<_BodyguardAvailabilityView> createState() =>
      _BodyguardAvailabilityViewState();
}

class _BodyguardAvailabilityViewState
    extends State<_BodyguardAvailabilityView> {
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
    for (final controller in _fromControllers.values) {
      controller.dispose();
    }
    for (final controller in _toControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(Map<WeekDay, AvailabilityDraft> schedule) {
    for (final day in WeekDay.values) {
      final draft = schedule[day];
      if (draft == null) continue;
      if (_fromControllers[day]!.text != draft.fromTime) {
        _fromControllers[day]!.text = draft.fromTime;
      }
      if (_toControllers[day]!.text != draft.toTime) {
        _toControllers[day]!.text = draft.toTime;
      }
    }
  }

  Future<void> _pickTime({
    required BuildContext context,
    required WeekDay day,
    required bool isFrom,
    required TimeOfDay initialTime,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null && context.mounted) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted = '${hour.toString().padLeft(2, '0')}:$minute $period';

      if (isFrom) {
        _fromControllers[day]!.text = formatted;
        context.read<AvailabilityBloc>().add(
          AvailabilityTimeChanged(day, fromTime: formatted),
        );
      } else {
        _toControllers[day]!.text = formatted;
        context.read<AvailabilityBloc>().add(
          AvailabilityTimeChanged(day, toTime: formatted),
        );
      }
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
    required WeekDay day,
    required bool isFrom,
    required TextEditingController controller,
  }) {
    return SizedBox(
      width: 100,
      child: AppTextField(
        controller: controller,
        readOnly: true,
        size: AppInputSize.small,
        onTap: () => _pickTime(
          context: context,
          day: day,
          isFrom: isFrom,
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
    return MultiBlocListener(
      listeners: [
        BlocListener<AvailabilityBloc, AvailabilityState>(
          listenWhen: (previous, current) =>
              previous.schedule != current.schedule,
          listener: (context, state) {
            _syncControllers(state.schedule);
            widget.onAvailabilityChanged?.call(state.selectedDays);
          },
        ),
        BlocListener<AvailabilityBloc, AvailabilityState>(
          listenWhen: (previous, current) =>
              previous.saveStatus != current.saveStatus,
          listener: (context, state) {
            if (state.saveStatus.isSuccess) {
              if (widget.owner is AccountOwner) {
                context.read<AuthBloc>().add(
                  const AuthProfileRefreshRequested(),
                );
              }
              AppSnackbar.success('Availability updated successfully.');
            } else if (state.saveStatus.isFailure) {
              AppSnackbar.error(
                context.apiErrorText(
                  state.saveStatus.errorOrNull,
                  fallback: state.saveStatus.errorMessageOrNull,
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<AvailabilityBloc, AvailabilityState>(
        builder: (context, state) {
          if (state.loadStatus.isLoading) {
            return Center(
              child: Padding(
                padding: AppSpacing.xxl.allPadding,
                child: CircularProgressIndicator(
                  color: context.colors.primary,
                ),
              ),
            );
          }

          final isSaving = state.saveStatus.isLoading;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.md.h,
              // Header Section
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

              // Weekly Day Cards List
              Column(
                children: WeekDay.values.map((day) {
                  final draft =
                      state.schedule[day] ?? const AvailabilityDraft();
                  final isSelected = draft.isAvailable;
                  final fromController = _fromControllers[day]!;
                  final toController = _toControllers[day]!;

                  return Padding(
                    padding: AppSpacing.md.bPadding,
                    child: WrapperCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 20,
                      ),
                      onTap: () => context
                          .read<AvailabilityBloc>()
                          .add(AvailabilityDayToggled(day)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          5.w,
                          // Left: Checkbox Icon + Weekday Label
                          _buildSelectionCircle(
                            context: context,
                            isSelected: isSelected,
                          ),
                          AppSpacing.sm.w,
                          Expanded(
                            child: Text(
                              day.label(),
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
                                  day: day,
                                  isFrom: true,
                                  controller: fromController,
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
                                  day: day,
                                  isFrom: false,
                                  controller: toController,
                                ),
                              ],
                            )
                          else
                            _buildDayOffBadge(
                              context,
                              onTap: () => context
                                  .read<AvailabilityBloc>()
                                  .add(AvailabilityDayToggled(day)),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              AppSpacing.md.h,

              // Save Availability Button
              AppButton(
                text: 'Save Availability',
                isLoading: isSaving,
                onPressed: isSaving
                    ? null
                    : () => context
                        .read<AvailabilityBloc>()
                        .add(const AvailabilitySaved()),
              ),
              AppSpacing.xl.h,
            ],
          );
        },
      ),
    );
  }
}
