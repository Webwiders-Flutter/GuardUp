import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/auth/domain/repositories/user_repository.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';

/// Modal bottom sheet for viewing and updating the bodyguard bio.
class EditBioSheet extends StatefulWidget {
  final String currentBio;

  const EditBioSheet({super.key, required this.currentBio});

  static Future<void> show(BuildContext context, {required String currentBio}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => EditBioSheet(currentBio: currentBio),
    );
  }

  @override
  State<EditBioSheet> createState() => _EditBioSheetState();
}

class _EditBioSheetState extends State<EditBioSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;

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

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final authState = sl<AuthBloc>().state;
      final userId = authState.user?.id ?? '';
      if (userId.isNotEmpty) {
        await sl<UserRepository>().updateProfileFields(
          userId: userId,
          data: {'bio': _controller.text.trim()},
        );
        sl<AuthBloc>().add(const AuthCheckStatusRequested());
      }
      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success('Bio updated successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackbar.error('Failed to update bio: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            text: _isSaving ? 'Saving...' : 'Save Bio',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _handleSave,
          ),
        ],
      ),
    );
  }
}

