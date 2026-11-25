import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/legal/legal.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/misc/app_input_label.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';

/// Screen allowing users to send inquiries or security dispatch messages.
class ContactUsScreen extends StatelessWidget {
  static const route = '/contact-us';

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

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<AuthBloc>()) {
      final authState = sl<AuthBloc>().state;
      final name = authState.user?.name ?? '';
      if (name.isNotEmpty && name != 'User') {
        _nameController.text = name;
      }
      final email = authState.user?.email ?? authState.email ?? '';
      if (email.isNotEmpty) {
        _emailController.text = email;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final submission = ContactUsSubmission(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobileNumber: '',
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
            submissionState.dataOrNull ??
                'Your message has been sent successfully',
          );
          context.pop();
        } else if (submissionState.isFailure) {
          AppSnackbar.error(
            submissionState.errorMessageOrNull ?? 'Failed to send message',
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.submissionState.isLoading;

        return Scaffold(
          appBar: AppAppBar.transparent(
            title: context.l10n.contactUs,
            fontSize: 14,
          ),
          body: SingleChildScrollView(
            padding: context.horizontalEdgeInsets,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSpacing.xl.h,

                  // 1. Upper Info Card
                  WrapperCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            QuickContainer(
                              w: 48,
                              h: 48,
                              shape: QuickContainerShape.circle,
                              color: context.colors.primaryContainer.withValues(
                                alpha: 0.35,
                              ),
                              border: Border.all(
                                color: context.colors.primary.withValues(
                                  alpha: 0.4,
                                ),
                                width: 1.5,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.support_agent_rounded,
                                color: context.colors.primary,
                                size: AppSizes.iconLg,
                              ),
                            ),
                            AppSpacing.md.w,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.l10n.contactUs,
                                    style: context.textTheme.titleMedium
                                        ?.bold(),
                                  ),
                                  AppSpacing.xxs.h,
                                  Text(
                                    context.l10n.contactUsSubtitle,
                                    style: context.textTheme.bodySmall?.colour(
                                      context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.md.h,
                        Divider(
                          color: context.colors.outlineVariant,
                          height: 1,
                        ),
                        AppSpacing.md.h,
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: AppSizes.iconSm,
                              color: context.colors.primary,
                            ),
                            AppSpacing.xs.w,
                            Text(
                              'support@guardup.com',
                              style: context.textTheme.bodySmall?.semiBold(),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.access_time_rounded,
                              size: AppSizes.iconSm,
                              color: context.colors.primary,
                            ),
                            AppSpacing.xs.w,
                            Text(
                              '10:00 AM – 7:00 PM',
                              style: context.textTheme.bodySmall?.colour(
                                context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.lg.h,

                  // 2. Form Card
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full Name Field
                      AppFieldLabel(
                        text: context.l10n.fullName,
                        isRequired: true,
                      ),
                      AppSpacing.xs.h,
                      AppTextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: context.l10n.fullName,
                          fillColor: context.colors.onPrimary,
                        ),
                        style: TextStyle(color: context.colors.onSurface),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.name(context, value),
                      ),
                      AppSpacing.lg.h,

                      // Email Field
                      AppFieldLabel(text: context.l10n.email, isRequired: true),
                      AppSpacing.xs.h,
                      AppTextField.email(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: context.l10n.email,
                          fillColor: context.colors.onPrimary,
                        ),
                        style: TextStyle(color: context.colors.onSurface),
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.email(context, value),
                      ),
                      AppSpacing.lg.h,

                      // Message Field
                      AppFieldLabel(
                        text: context.l10n.message,
                        isRequired: true,
                      ),
                      AppSpacing.xs.h,
                      AppTextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: context.l10n.messageHint,
                          fillColor: context.colors.onPrimary,
                        ),
                        style: TextStyle(color: context.colors.onSurface),
                        maxLines: 4,
                        minLines: 3,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        validator: (value) =>
                            Validators.required(context, value),
                      ),
                      AppSpacing.xl.h,

                      // Submit Message Button
                      AppButton(
                        text: context.l10n.submitMessage,
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _handleSubmit,
                      ),
                    ],
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
