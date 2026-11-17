import 'package:guardup_admin/core/extensions/string.extension.dart';
import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/services/launcher/app_launcher.service.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_input_label.dart';
import '/shared/widgets/inputs/app_text_field.dart';

/// Card for managing customer support lines, contact details, and help desk channels.
class SupportSettingsCard extends StatelessWidget {
  final GlobalKey<FormState>? formKey;
  final TextEditingController emailController;
  final TextEditingController callPhoneController;
  final ValueNotifier<String> callCountryCodeController;
  final TextEditingController whatsappPhoneController;
  final TextEditingController hoursController;
  final ValueNotifier<String> whatsappCountryCodeController;
  final VoidCallback onChanged;

  const SupportSettingsCard({
    super.key,
    this.formKey,
    required this.emailController,
    required this.callPhoneController,
    required this.callCountryCodeController,
    required this.whatsappPhoneController,
    required this.whatsappCountryCodeController,
    required this.hoursController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(flex: 3, child: _buildFormCard(context))],
                )
              else ...[
                _buildFormCard(context),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    final colors = context.colors;

    return QuickContainer(
      p: AppSpacing.xl,
      radius: AppRadius.lg,
      color: colors.surface,
      border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  size: AppSpacing.xxl,
                  color: colors.secondary,
                ),
              ),
              AppSpacing.md.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Support Channels',
                      style: context.textTheme.titleMedium?.semiBold().colour(
                        colors.onSurface,
                      ),
                    ),
                    AppSpacing.xs.h,
                    Text(
                      'Global contact coordinates displayed in client apps and help center',
                      style: context.textTheme.bodySmall?.colour(
                        colors.onSurfaceSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppSpacing.xl.h,

          // Support Email
          const AppFieldLabel(text: 'Official Support Email', isRequired: true),
          AppSpacing.xs.h,
          AppTextField(
            controller: emailController,
            type: AppTextFieldType.email,
            validator: (value) => Validators.email(context, value),
            decoration: const InputDecoration(
              hintText: 'support@supplr.in',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            onChanged: (_) => onChanged(),
          ),
          AppSpacing.xs.h,
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              fullWidth: false,
              text: 'Test Email Launcher',
              type: ButtonType.text,
              size: ButtonSize.small,
              leading: const Icon(Icons.send_rounded, size: AppSpacing.md),
              onPressed: () {
                final email = emailController.text.trim();
                if (email.isNotEmpty) {
                  AppLauncher.sendEmail(
                    email: email,
                    subject: 'Supplr Admin Test Inquiry',
                    body: 'Hello Support Team,\nThis is a test notification from the admin console.',
                  );
                }
              },
            ),
          ),

          AppSpacing.md.h,

          // Voice Call Phone Number
          const AppFieldLabel(
            text: 'Support Voice Call Number',
            isRequired: true,
          ),
          AppSpacing.xs.h,
          ValueListenableBuilder<String>(
            valueListenable: callCountryCodeController,
            builder: (context, code, _) {
              return AppTextField.phone(
                controller: callPhoneController,
                phoneCountryCode: code,
                onCountryCodeChanged: (countryCode) {
                  callCountryCodeController.value = countryCode;
                  onChanged();
                },
                validator: (value) => Validators.phone(context, value),
                decoration: const InputDecoration(hintText: '9876543210'),
                onChanged: (_) => onChanged(),
              );
            },
          ),
          AppSpacing.xs.h,
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              fullWidth: false,
              text: 'Test Call Launcher',
              type: ButtonType.text,
              size: ButtonSize.small,
              leading: const Icon(Icons.call_made_rounded, size: AppSpacing.md),
              onPressed: () {
                final phone = callPhoneController.text.trim();
                if (phone.isNotEmpty) {
                  final code = callCountryCodeController.value;
                  AppLauncher.callPhone(phone.toE164(countryCode: code));
                }
              },
            ),
          ),

          AppSpacing.md.h,

          // WhatsApp Phone Number
          const AppFieldLabel(
            text: 'Support WhatsApp Number',
            isRequired: true,
          ),
          AppSpacing.xs.h,
          ValueListenableBuilder<String>(
            valueListenable: whatsappCountryCodeController,
            builder: (context, code, _) {
              return AppTextField.phone(
                controller: whatsappPhoneController,
                phoneCountryCode: code,
                onCountryCodeChanged: (countryCode) {
                  whatsappCountryCodeController.value = countryCode;
                  onChanged();
                },
                validator: (value) => Validators.phone(context, value),
                decoration: const InputDecoration(hintText: '9876543210'),
                onChanged: (_) => onChanged(),
              );
            },
          ),
          AppSpacing.xs.h,
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              text: 'Test WhatsApp Chat',
              type: ButtonType.text,
              fullWidth: false,
              size: ButtonSize.small,
              leading: const Icon(Icons.chat_rounded, size: AppSpacing.md),
              onPressed: () {
                final phone = whatsappPhoneController.text.trim();
                if (phone.isNotEmpty) {
                  final code = whatsappCountryCodeController.value;
                  AppLauncher.openWhatsApp(
                    phone: phone.toE164(countryCode: code),
                    message: 'Hello Support Team, testing contact link from admin console.',
                  );
                }
              },
            ),
          ),

          AppSpacing.md.h,

          // Operational Hours
          const AppFieldLabel(text: 'Support Working Hours', isRequired: false),
          AppSpacing.xs.h,
          AppTextField(
            controller: hoursController,
            decoration: const InputDecoration(
              hintText: 'e.g. 10:00 AM - 7:00 PM (Mon-Sat)',
              prefixIcon: Icon(Icons.schedule_rounded),
            ),
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}
