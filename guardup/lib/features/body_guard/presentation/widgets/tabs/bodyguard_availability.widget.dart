import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/enum/week_day.enum.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/auth/domain/repositories/auth_repository.dart';
import '/features/auth/domain/repositories/user_repository.dart';
import '/features/body_guard/data/model/body_guard.model.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '/shared/widgets/selection/selection.controller.dart';

/// Tab content widget allowing bodyguards to manage their active weekly
/// availability hours and designated days off dynamically via user_availabilities table.
class BodyguardAvailabilityWidget extends StatefulWidget {
  final BodyGuardModel? bodyguard;
  final ValueChanged<List<WeekDay>>? onAvailabilityChanged;

  const BodyguardAvailabilityWidget({
    super.key,
    this.bodyguard,
    this.onAvailabilityChanged,
  });

  @override
  State<BodyguardAvailabilityWidget> createState() =>
      _BodyguardAvailabilityWidgetState();
}

class _BodyguardAvailabilityWidgetState
    extends State<BodyguardAvailabilityWidget> {
  late final SelectionController<WeekDay> _selectionController;

  final Map<WeekDay, TextEditingController> _fromControllers = {
    for (final day in WeekDay.values)
      day: TextEditingController(text: '09:00 AM'),
  };

  final Map<WeekDay, TextEditingController> _toControllers = {
    for (final day in WeekDay.values)
      day: TextEditingController(text: '12:00 PM'),
  };

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectionController = SelectionController<WeekDay>.multi(
      initial: const [],
      onChanged: widget.onAvailabilityChanged,
    );
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final bodyguardId = widget.bodyguard?.id;
    final currentUserId = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentUserId
        : null;

    if (bodyguardId == null && currentUserId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch from user_availabilities table
      final dynamic query;
      if (bodyguardId != null && bodyguardId.isNotEmpty) {
        query = Supabase.instance.client
            .from(DatabaseTables.userAvailabilities)
            .select()
            .eq('bodyguard_id', bodyguardId);
      } else {
        query = Supabase.instance.client
            .from(DatabaseTables.userAvailabilities)
            .select()
            .eq('user_id', currentUserId!);
      }

      final rows = await query;

      final availableDays = <WeekDay>[];

      if (rows.isNotEmpty) {
        for (final row in rows) {
          final dayStr = (row['day_of_week'] as String?)?.toLowerCase() ?? '';
          final day = WeekDay.values.firstWhere(
            (d) => d.name.toLowerCase() == dayStr,
            orElse: () => WeekDay.monday,
          );

          final isAvailable = row['is_available'] as bool? ?? false;
          if (isAvailable && !availableDays.contains(day)) {
            availableDays.add(day);
          }

          final fromStr = row['from_time'] as String?;
          if (fromStr != null && fromStr.isNotEmpty) {
            _fromControllers[day]?.text = fromStr;
          }

          final toStr = row['to_time'] as String?;
          if (toStr != null && toStr.isNotEmpty) {
            _toControllers[day]?.text = toStr;
          }
        }
      } else {
        // Fallback to metadata['availability'] if table is not yet populated
        final rawAvailability = sl<AuthBloc>()
            .state
            .user?.metadata?['availability'] is Map
            ? sl<AuthBloc>().state.user!.metadata!['availability']
                as Map<String, dynamic>?
            : null;

        if (rawAvailability != null && rawAvailability.isNotEmpty) {
          for (final day in WeekDay.values) {
            final dayData =
                rawAvailability[day.name] as Map<String, dynamic>?;
            if (dayData != null) {
              final isAvailable = dayData['is_available'] as bool? ?? false;
              if (isAvailable) availableDays.add(day);

              final fromStr = dayData['from'] as String?;
              if (fromStr != null && fromStr.isNotEmpty) {
                _fromControllers[day]!.text = fromStr;
              }

              final toStr = dayData['to'] as String?;
              if (toStr != null && toStr.isNotEmpty) {
                _toControllers[day]!.text = toStr;
              }
            }
          }
        } else {
          availableDays.addAll([
            WeekDay.monday,
            WeekDay.tuesday,
            WeekDay.wednesday,
            WeekDay.thursday,
            WeekDay.friday,
          ]);
        }
      }

      if (mounted) {
        _selectionController.value = availableDays;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  Future<void> _handleSaveAvailability() async {
    final bodyguardId = widget.bodyguard?.id;
    final currentUserId = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentUserId
        : null;
    if (bodyguardId == null && currentUserId == null) return;

    setState(() => _isSaving = true);
    try {
      final selectedDays = _selectionController.value;

      if (bodyguardId != null && bodyguardId.isNotEmpty) {
        final rows = WeekDay.values.map((day) {
          return {
            'bodyguard_id': bodyguardId,
            'day_of_week': day.name.toLowerCase(),
            'is_available': selectedDays.contains(day),
            'from_time': _fromControllers[day]!.text.trim(),
            'to_time': _toControllers[day]!.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          };
        }).toList();

        await Supabase.instance.client
            .from(DatabaseTables.userAvailabilities)
            .upsert(rows, onConflict: 'bodyguard_id, day_of_week');
      } else if (currentUserId != null) {
        // 1. Save to user_availabilities table
        final rows = WeekDay.values.map((day) {
          return {
            'user_id': currentUserId,
            'day_of_week': day.name.toLowerCase(),
            'is_available': selectedDays.contains(day),
            'from_time': _fromControllers[day]!.text.trim(),
            'to_time': _toControllers[day]!.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          };
        }).toList();

        await Supabase.instance.client
            .from(DatabaseTables.userAvailabilities)
            .upsert(rows, onConflict: 'user_id, day_of_week');

        // 2. Also keep metadata['availability'] in sync for backward compatibility
        if (sl.isRegistered<UserRepository>()) {
          try {
            final availabilityMap = <String, dynamic>{};
            for (final day in WeekDay.values) {
              availabilityMap[day.name] = {
                'is_available': selectedDays.contains(day),
                'from': _fromControllers[day]!.text.trim(),
                'to': _toControllers[day]!.text.trim(),
              };
            }
            final userRow =
                await sl<UserRepository>().getUserData(currentUserId);
            final existingMeta = (userRow?['metadata'] is Map)
                ? Map<String, dynamic>.from(userRow!['metadata'] as Map)
                : <String, dynamic>{};
            existingMeta['availability'] = availabilityMap;

            await sl<UserRepository>().updateProfileFields(
              userId: currentUserId,
              data: {'metadata': existingMeta},
            );
          } catch (_) {}
        }

        if (sl.isRegistered<AuthBloc>()) {
          sl<AuthBloc>().add(const AuthCheckStatusRequested());
        }
      }

      if (mounted) {
        AppSnackbar.success('Availability updated successfully.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error('Failed to update availability: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: AppSpacing.xxl.allPadding,
          child: CircularProgressIndicator(
            color: context.colors.primary,
          ),
        ),
      );
    }

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
        ValueListenableBuilder<List<WeekDay>>(
          valueListenable: _selectionController,
          builder: (context, selectedDays, _) {
            return Column(
              children: WeekDay.values.map((day) {
                final isSelected = selectedDays.contains(day);
                final fromController = _fromControllers[day]!;
                final toController = _toControllers[day]!;

                return Padding(
                  padding: AppSpacing.md.bPadding,
                  child: WrapperCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                    onTap: () => _selectionController.toggle(day),
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
                                isHighlighted: false,
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
        AppSpacing.md.h,

        // Save Availability Button
        AppButton(
          text: 'Save Availability',
          isLoading: _isSaving,
          onPressed: _handleSaveAvailability,
        ),
        AppSpacing.xl.h,
      ],
    );
  }
}
