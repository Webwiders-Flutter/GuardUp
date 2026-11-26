import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '../../../bloc/guard_profile/guard_profile_bloc.dart';

/// Modal bottom sheet for viewing and updating the bodyguard bio.
class EditBioSheet extends StatefulWidget {
  final String currentBio;
  final ValueChanged<String>? onBioUpdated;

  const EditBioSheet({super.key, required this.currentBio, this.onBioUpdated});

  static Future<void> show(
    BuildContext context, {
    required String currentBio,
    GuardProfileBloc? bloc,
    ValueChanged<String>? onBioUpdated,
  }) {
    final profileBloc = bloc ?? context.read<GuardProfileBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => BlocProvider.value(
        value: profileBloc,
        child: EditBioSheet(currentBio: currentBio, onBioUpdated: onBioUpdated),
      ),
    );
  }

  @override
  State<EditBioSheet> createState() => _EditBioSheetState();
}

class _EditBioSheetState extends State<EditBioSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentBio);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    context.read<GuardProfileBloc>().add(
      GuardProfileBioSaved(_controller.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GuardProfileBloc, GuardProfileState>(
      listenWhen: (prev, curr) => prev.editStatus != curr.editStatus,
      listener: (context, state) {
        if (state.editStatus.isSuccess &&
            state.editStatus.dataOrNull == GuardProfileEditKind.bio) {
          widget.onBioUpdated?.call(_controller.text.trim());
          Navigator.pop(context);
          AppSnackbar.success('Bio updated successfully');
        } else if (state.editStatus.isFailure) {
          AppSnackbar.error(
            context.apiErrorText(
              state.editStatus.errorOrNull,
              fallback: 'Failed to update bio',
            ),
          );
        }
      },
      buildWhen: (prev, curr) => prev.editStatus != curr.editStatus,
      builder: (context, state) {
        final isSaving = state.editStatus.isLoading;
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              AppSpacing.md.h,
              Text(
                'Edit Bio',
                style: context.textTheme.titleMedium?.bold().colour(
                  context.colors.onSurface,
                ),
              ),
              AppSpacing.xs.h,
              Text(
                'Provide details about your background, clearances, and security specialties.',
                style: context.textTheme.bodySmall?.colour(
                  context.colors.onSurfaceVariant,
                ),
              ),
              AppSpacing.md.h,
              AppTextField(
                controller: _controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter your professional bio...',
                ),
              ),
              AppSpacing.lg.h,
              AppButton(
                text: isSaving ? 'Saving...' : 'Save Bio',
                isLoading: isSaving,
                onPressed: isSaving ? null : _handleSave,
              ),
            ],
          ),
        );
      },
    );
  }
}
