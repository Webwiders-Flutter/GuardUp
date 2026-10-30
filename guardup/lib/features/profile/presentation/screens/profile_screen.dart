import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/localization/locale_bloc.dart';
import 'package:guardup/core/services/injection_container.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/widgets/common/app_circle_avatar.dart'; // Added for DefaultProfileIcon
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:guardup/features/auth/presentation/widgets/login_gate_bottom_sheet.dart';
import 'package:guardup/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:guardup/features/profile/presentation/widgets/change_language_dialog.dart';
import 'package:guardup/features/profile/presentation/widgets/delete_account_dialog.dart';
import 'package:guardup/features/profile/presentation/widgets/logout_dialog.dart';
import 'package:guardup/features/profile/presentation/widgets/profile_header_widget.dart';
import 'package:guardup/features/profile/presentation/widgets/profile_menu_item_widget.dart';

import '../../../../core/utils/ui_feedback.dart';
import '../../../auth/domain/entities/user_entity.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProfileBloc>(),
      child: const ProfileScreenView(),
    );
  }
}

class ProfileScreenView extends StatefulWidget {
  const ProfileScreenView({super.key});

  @override
  State<ProfileScreenView> createState() => _ProfileScreenViewState();
}

class _ProfileScreenViewState extends State<ProfileScreenView> {
  UserEntity? _lastUser;

  @override
  void initState() {
    super.initState();
    _fetchProfileIfAuthenticated();
  }

  void _fetchProfileIfAuthenticated() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      _lastUser = authState.user;
      context.read<ProfileBloc>().add(
        GetProfileEvent(userId: authState.user.id),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return const LogoutDialog();
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return const DeleteAccountDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackgroundColor,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthenticatedState) {
                  _lastUser = state.user;
                  context.read<ProfileBloc>().add(
                    GetProfileEvent(userId: state.user.id),
                  );
                } else if (state is AuthErrorState) {
                  UIFeedback.showSnackbar(
                    context,
                    context.translateFailure(state.message),
                    isError: true,
                  );
                  // We need to get back to AuthenticatedState if deletion fails
                  context.read<AuthBloc>().add(const AuthRefreshEvent());
                } else if (state is AuthDeleteAccountErrorState) {
                  UIFeedback.showSnackbar(
                    context,
                    context.translateFailure(state.message),
                    isError: true,
                  );
                  // We need to get back to AuthenticatedState if deletion fails
                  context.read<AuthBloc>().add(const AuthRefreshEvent());
                } else if (state is AuthDeleteAccountSuccessState) {
                  Navigator.of(context).pop();
                } else if (state is UnAuthenticatedState) {
                  _lastUser = null;
                }
              },
            ),
          ],
          child: Stack(
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final isLoggedIn =
                      authState is AuthenticatedState ||
                      authState is AuthDeleteAccountLoadingState ||
                      authState is AuthDeleteAccountErrorState;
                  final authUser = authState is AuthenticatedState
                      ? authState.user
                      : authState is AuthDeleteAccountLoadingState
                      ? authState.user
                      : authState is AuthDeleteAccountErrorState
                      ? authState.user
                      : _lastUser;

                  final profileState = context.watch<ProfileBloc>().state;
                  final profileUser = profileState is ProfileLoaded
                      ? profileState.user
                      : null;

                  final name = profileUser?.name ?? authUser?.name ?? 'User';
                  final email = profileUser?.email ?? authUser?.email ?? '';
                  final profileImage =
                      profileUser?.profileImage ?? authUser?.profileImage;
                  final memberSince =
                      profileUser?.formattedMemberSince ??
                      authUser?.formattedMemberSince ??
                      '';

                  return Column(
                    children: [
                      if (isLoggedIn)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0,
                          ),
                          child: Column(
                            children: [
                              ProfileHeaderWidget(
                                name: name,
                                email: email,
                                memberSince: memberSince,
                                imageUrl: profileImage,
                              ),
                              20.height,
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 40.0,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(
                                width: 80,
                                height: 80,
                                child: DefaultProfileIcon(),
                              ),
                              20.height,
                              Text(
                                context.l10n.loginToViewYourProfile,
                                style: context.textTheme.titleLarge?.copyWith(
                                  color: AppColors.whiteColor,
                                ),
                              ),
                              20.height,
                              ElevatedButton(
                                onPressed: () {
                                  context.push(AppRouter.login);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  context.l10n.login,
                                  style: TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Menu Items List
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          children: [
                            ProfileMenuItemWidget(
                              iconPath: AppAssets.languageIcon,
                              title: context.l10n.language,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  BlocBuilder<LocaleBloc, LocaleState>(
                                    builder: (context, state) {
                                      final currentLanguage =
                                          state.locale.languageCode == 'ar'
                                          ? context.l10n.arabic
                                          : context.l10n.english;
                                      return Text(
                                        currentLanguage,
                                        style: context.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.grey),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                ],
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const ChangeLanguageDialog(),
                                );
                              },
                            ),
                            if (isLoggedIn) ...[
                              ProfileMenuItemWidget(
                                iconPath: AppAssets.editProfileIcon,
                                title: context.l10n.editProfile,
                                onTap: () {
                                  context.push(AppRouter.editProfile);
                                },
                              ),

                              ProfileMenuItemWidget(
                                iconPath: AppAssets.lockIconFilled,
                                title: context.l10n.changePassword,
                                onTap: () {
                                  context.push(AppRouter.changePasswordScreen);
                                },
                              ),
                              ProfileMenuItemWidget(
                                iconPath: AppAssets.emailIcon,
                                title: context.l10n.changeEmail,
                                onTap: () {
                                  context.push(AppRouter.changeEmailScreen);
                                },
                              ),
                              ProfileMenuItemWidget(
                                iconPath: AppAssets
                                    .userIcon, // Or a phone icon if available
                                title: context.l10n.changePhone,
                                onTap: () {
                                  context.push(AppRouter.changePhoneScreen);
                                },
                              ),
                            ],
                            ProfileMenuItemWidget(
                              iconPath: AppAssets.helpIcon,
                              title: context.l10n.helpCenter,
                              onTap: () {
                                if (isLoggedIn) {
                                  context.push(AppRouter.supportCenter);
                                } else {
                                  LoginGateBottomSheet.show(context);
                                }
                              },
                            ),
                            if (isLoggedIn) ...[
                              ProfileMenuItemWidget(
                                iconPath: AppAssets.ticketsIcon,
                                title: context.l10n.myTickets,
                                onTap: () {
                                  context.push(AppRouter.myTickets);
                                },
                              ),
                              // ProfileMenuItemWidget(
                              //   iconPath: AppAssets.chatIcon,
                              //   title: context.l10n.myChat,
                              //   onTap: () {
                              //     context.push(AppRouter.myChats);
                              //   },
                              // ),

                              // ProfileMenuItemWidget(
                              //   iconPath: AppAssets.documentIcon,
                              //   title: context.l10n.uploadedDocuments,
                              //   onTap: () {
                              //     context.push(AppRouter.uploadedDocuments);
                              //   },
                              // ),
                            ],
                            ProfileMenuItemWidget(
                              iconPath: AppAssets.termsIcon,
                              title: context.l10n.termsAndConditions,
                              onTap: () {
                                context.push(AppRouter.termsAndConditionScreen);
                              },
                            ),
                            ProfileMenuItemWidget(
                              iconPath: AppAssets.privacyIcon,
                              title: context.l10n.privacyPolicy,
                              onTap: () {
                                context.push(AppRouter.privacyPolicyScreen);
                              },
                            ),
                            if (isLoggedIn)
                              ProfileMenuItemWidget(
                                iconPath: AppAssets.lockIconFilled, // Or a specific block icon if available
                                title: context.l10n.blockedUsers,
                                onTap: () {
                                  context.push(AppRouter.blockedUsers);
                                },
                              ),
                            if (isLoggedIn) ...[
                              ProfileMenuItemWidget(
                                iconPath: AppAssets.logoutIcon,
                                title: context.l10n.logout,
                                onTap: () {
                                  _showLogoutDialog(context);
                                },
                              ),
                              ProfileMenuItemWidget(
                                iconPath: AppAssets.deleteIcon,
                                title: context.l10n.deleteAccount,
                                onTap: () {
                                  _showDeleteAccountDialog(context);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoadingState) {
                    return Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
