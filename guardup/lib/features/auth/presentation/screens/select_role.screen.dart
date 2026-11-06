import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/selection/app_selectable_card.dart';
import '/shared/widgets/selection/selection.controller.dart';

class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  final SelectionController<UserRole> _roleController =
      SelectionController<UserRole>.single(initial: .guard);

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final selectedRole = _roleController.selectedItem ?? UserRole.customer;
    sl<AuthBloc>().add(AuthSetSessionRoleRequested(selectedRole));
    context.push(AppRoutes.signup, extra: selectedRole);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: context.horizontalEdgeInsets,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      AppSpacing.huge.h,

                      // 1. GuardUp Logo
                      AppImage.asset(
                        assetPath: Assets.images.appLogo.path,
                        height: 28.wPercent(context),
                        fit: BoxFit.contain,
                      ),
                      AppSpacing.xl.h,

                      // 2. Heading: "Welcome to GUARDUP" via AppRichText with theme
                      AppRichText(
                        textAlign: TextAlign.center,
                        spans: [
                          AppTextSpan(
                            text: 'Welcome to ',
                            style: context.textTheme.headlineMedium?.bold(),
                          ),
                          AppTextSpan(
                            text: 'GUARDUP',
                            style: context.textTheme.headlineMedium
                                ?.bold()
                                .colour(context.colors.primary),
                          ),
                        ],
                      ),

                      // 3. Subtitle
                      Text(
                        context.l10n.chooseRoleSubtitle,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.xl.h,

                      // 4. Role Selection Cards via AppSelectableCard
                      ...UserRole.values.map(
                        (x) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: AppSelectableCard<UserRole>(
                            controller: _roleController,
                            value: x,
                            title: x.longLabel(context.l10n),
                            subtitle: x.description(context.l10n),
                            iconAssetPath: x.svgPath,
                            makeItGlow: true,
                          ),
                        ),
                      ),

                      const Spacer(),
                      AppSpacing.lg.h,

                      // 5. Continue Button pinned to bottom
                      AppButton(
                        text: context.l10n.continueButton,

                        onPressed: _handleContinue,
                      ),
                      AppSpacing.xl.h,

                      // 6. Footer: "Already have an account? Log in" via AppRichText
                      Center(
                        child: AppRichText(
                          textAlign: TextAlign.center,
                          spans: [
                            AppTextSpan(text: context.l10n.alreadyHaveAccount),
                            AppTextSpan(
                              text: context.l10n.login,
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppRoutes.login);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.lg.h,
                    ],
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
