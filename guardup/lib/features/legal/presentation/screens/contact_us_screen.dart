import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/legal/legal.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';

/// Screen allowing users to send inquiries or security dispatch messages.
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContactUsBloc(),
      child: const _ContactUsView(),
    );
  }
}

class _ContactUsView extends StatefulWidget {
  const _ContactUsView();

  @override
  State<_ContactUsView> createState() => _ContactUsViewState();
}

class _ContactUsViewState extends State<_ContactUsView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final submission = ContactUsSubmission(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobileNumber: _phoneController.text.trim(),
      message: _messageController.text.trim(),
      submittedAt: DateTime.now(),
    );

    context.read<ContactUsBloc>().add(SubmitContactUsRequested(submission));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContactUsBloc, ContactUsState>(
      listenWhen: (previous, current) =>
          previous.submissionState != current.submissionState,
      listener: (context, state) {
        final submissionState = state.submissionState;
        if (submissionState.isSuccess) {
          AppSnackbar.success(
            submissionState.dataOrNull ?? 'Message sent successfully',
            context: context,
          );
          context.pop();
        } else if (submissionState.isFailure) {
          AppSnackbar.error(
            submissionState.errorMessageOrNull ?? 'Failed to send message',
            context: context,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.submissionState.isLoading;

        return Scaffold(
          backgroundColor: context.colors.transparent,
          appBar: const AppAppBar.transparent(
            title: 'Contact Us',
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: context.screenPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuickContainer(
                    p: AppSpacing.lg,
                    radius: AppRadius.lg,
                    color: context.colors.surfaceContainer.withValues(
                      alpha: 0.72,
                    ),
                    border: Border.all(
                      color: context.colors.outlineVariant,
                      width: 1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Full Name
                        AppTextField(
                          controller: _nameController,
                          hintText: context.l10n.fullName,
                          textInputAction: TextInputAction.next,
                          validator: (value) => Validators.name(context, value),
                        ),
                        AppSpacing.md.h,

                        // Email Address
                        AppTextField.email(
                          controller: _emailController,
                          hintText: context.l10n.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.email(context, value),
                        ),
                        AppSpacing.md.h,

                        // Phone Number
                        AppTextField(
                          controller: _phoneController,
                          hintText: context.l10n.phoneNumber,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.phone(context, value),
                        ),
                        AppSpacing.md.h,

                        // Message Field
                        AppTextField(
                          controller: _messageController,
                          hintText: 'Enter your message...',
                          maxLines: 4,
                          minLines: 3,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          validator: (value) =>
                              Validators.required(context, value),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.xl.h,

                  // Submit Button
                  AppButton(
                    text: 'Send Message',
                    size: ButtonSize.large,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _handleSubmit,
                  ),
                  AppSpacing.md.h,

                  // Cancel Button
                  AppButton(
                    text: context.l10n.cancel,
                    type: ButtonType.secondaryOff,
                    size: ButtonSize.large,
                    onPressed: () => context.pop(),
                  ),
                  AppSpacing.xxl.h,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
