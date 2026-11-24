import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../../core/extensions/context.extension.dart';
import '../../../../core/extensions/riverpod.extension.dart';
import '../../../../core/extensions/spacing.extension.dart';
import '../../../../core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '../../../users/data/models/user_model.dart';
import '/features/auth/di/auth.providers.dart';
import '/shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/inputs/app_input_label.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/features/auth/presentation/screens/login.screen.dart';

/// Enterprise administrator profile screen.
///
/// Provides:
/// 1. Profile Editing — Full Name, Email, Mobile Number
/// 2. Change Password — Secure credentials updating with validation
/// 3. Session & Logout — Authenticated sign-out with confirmation
///
/// Responsive dashboard layout compliant with `rules.md`.
class ProfileScreen extends ConsumerStatefulWidget {
  /// Route path of this screen.
  static const route = '/profile-details';

  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // ── Keys & Form States ───────────────────────────────────────────────────────
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  // ── Profile Controllers ─────────────────────────────────────────────────────
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  // ── Password Controllers ────────────────────────────────────────────────────
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  // ── Local Loading States (ValueNotifiers) ──────────────────────────────────
  final ValueNotifier<bool> _isSavingProfileNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isChangingPasswordNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isSigningOutNotifier = ValueNotifier(false);

  // Track if profile was populated from model
  bool _hasInitialisedFields = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _isSavingProfileNotifier.dispose();
    _isChangingPasswordNotifier.dispose();
    _isSigningOutNotifier.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _syncControllersWithModel(UserModel? user) {
    if (user == null || _hasInitialisedFields) return;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber ?? '';
    _hasInitialisedFields = true;
  }

  void _resetProfileForm(UserModel? user) {
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _handleSaveProfile() async {
    if (!(_profileFormKey.currentState?.validate() ?? false)) {
      return;
    }

    _isSavingProfileNotifier.value = true;

    await ref
        .read(adminUserControllerProvider.notifier)
        .updateProfile(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          mobileNumber: _phoneController.text.trim(),
        );

    if (!mounted) return;
    _isSavingProfileNotifier.value = false;

    ref
        .read(adminUserControllerProvider)
        .handleResult(
          successMessage: 'Profile updated successfully',
          fallbackErrorMessage: 'Failed to update profile. Please try again.',
        );
  }

  Future<void> _handleChangePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) {
      return;
    }

    _isChangingPasswordNotifier.value = true;

    final newPassword = _newPasswordController.text;
    await ref.read(authControllerProvider.notifier).changePassword(newPassword);

    if (!mounted) return;
    _isChangingPasswordNotifier.value = false;

    final ok = ref
        .read(authControllerProvider)
        .handleResult(
          successMessage: 'Password updated successfully',
          fallbackErrorMessage: 'Failed to change password. Please try again.',
        );

    if (ok) {
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _passwordFormKey.currentState?.reset();
    }
  }

  Future<void> _handleLogout() async {
    final result = await AppPopup.showLogoutConfirmation(context);
    if (result?.action != PopupAction.confirm) return;

    if (!mounted) return;
    _isSigningOutNotifier.value = true;

    await ref.read(authControllerProvider.notifier).signOut();

    if (!mounted) return;
    _isSigningOutNotifier.value = false;

    final ok = ref
        .read(authControllerProvider)
        .handleResult(
          successMessage: 'You have been logged out successfully',
          fallbackErrorMessage: 'Failed to sign out. Please try again.',
        );

    if (ok && mounted) {
      context.go(LoginScreen.route);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'AD';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, math.min(2, trimmed.length)).toUpperCase();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final userAsync = ref.watch(adminUserControllerProvider);
    final authUser = ref.watch(authControllerProvider).value;

    final user = userAsync.value;

    if (user != null && !_hasInitialisedFields) {
      _syncControllersWithModel(user);
    } else if (user == null && authUser != null && !_hasInitialisedFields) {
      _nameController.text =
          authUser.userMetadata?['full_name'] as String? ?? 'Admin';
      _emailController.text = authUser.email ?? '';
      _phoneController.text = authUser.phone ?? '';
      _hasInitialisedFields = true;
    }

    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : ((authUser?.userMetadata?['full_name'] as String?) ?? 'Super Admin');
    final displayEmail = user?.email ?? authUser?.email ?? 'admin@guardup.com';
    final displayPhone = user?.phoneNumber?.isNotEmpty == true
        ? '+91 ${user!.phoneNumber}'
        : (authUser?.phone?.isNotEmpty == true
              ? authUser!.phone!
              : 'Not configured');

    return Scaffold(
      backgroundColor: colors.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 960;

            return RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(adminUserControllerProvider.notifier)
                    .refreshProfile();
              },
              color: colors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? AppSpacing.xxl : AppSpacing.lg,
                  vertical: isDesktop ? AppSpacing.xl : AppSpacing.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Hero Banner Card ────────────────────────────────
                        _buildHeroBanner(
                          context,
                          displayName: displayName,
                          displayEmail: displayEmail,
                          displayPhone: displayPhone,
                          user: user,
                          isDesktop: isDesktop,
                        ),

                        AppSpacing.xl.h,

                        // ── Main Content Grid / Stack ───────────────────────
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Sidebar Summary Column (360px)
                              SizedBox(
                                width: 360,
                                child: _buildProfileEditCard(context, user),
                              ),

                              AppSpacing.xl.w,

                              // Right Form Column (Expanded)
                              Expanded(
                                child: _buildChangePasswordCard(context),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildProfileEditCard(context, user),
                              AppSpacing.lg.h,
                              _buildChangePasswordCard(context),
                            ],
                          ),

                        AppSpacing.xxxl.h,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Hero Overview Banner ─────────────────────────────────────────────────────

  Widget _buildHeroBanner(
    BuildContext context, {
    required String displayName,
    required String displayEmail,
    required String displayPhone,
    required UserModel? user,
    required bool isDesktop,
  }) {
    final colors = context.colors;
    final initials = _getInitials(displayName);

    return QuickContainer(
      p: isDesktop ? AppSpacing.xxl : AppSpacing.lg,
      radius: AppRadius.lg,
      color: colors.surface,
      border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      shadows: [
        BoxShadow(
          color: colors.onSurface.withValues(alpha: 0.03),
          blurRadius: AppSpacing.md,
          offset: const Offset(0, 2),
        ),
      ],
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large Avatar with status indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  QuickContainer(
                    w: isDesktop
                        ? (AppSpacing.xxxl * 2)
                        : (AppSpacing.xxxl + AppSpacing.lg),
                    h: isDesktop
                        ? (AppSpacing.xxxl * 2)
                        : (AppSpacing.xxxl + AppSpacing.lg),
                    radius: AppRadius.full,
                    color: colors.primary.withValues(alpha: 0.10),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.25),
                      width: 2,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: context.textTheme.headlineSmall
                          ?.bold()
                          .size(isDesktop ? (AppSpacing.xl + 2) : AppSpacing.lg)
                          .colour(colors.primary),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: AppSpacing.md + 2,
                      height: AppSpacing.md + 2,
                      decoration: BoxDecoration(
                        color: colors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              AppSpacing.lg.w,

              // User Info & Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: context.textTheme.titleLarge?.bold().size(
                              isDesktop ? 22 : 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppSpacing.sm.w,
                        Icon(
                          Icons.verified_rounded,
                          color: colors.primary,
                          size: AppSpacing.lg + 2,
                        ),
                      ],
                    ),
                    (AppSpacing.xs / 2).h,
                    Row(
                      children: [
                        Icon(
                          Icons.mail_outline_rounded,
                          size: AppSpacing.md + 2,
                          color: colors.onSurfaceSecondary,
                        ),
                        (AppSpacing.xs + 2).w,
                        Flexible(
                          child: Text(
                            displayEmail,
                            style: context.textTheme.bodySmall?.medium().colour(
                              colors.onSurfaceSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Desktop Header Actions
              if (isDesktop) ...[
                AppSpacing.lg.w,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: _isSigningOutNotifier,
                      builder: (context, isSigningOut, _) {
                        return AppButton(
                          text: 'Sign Out',
                          leading: const Icon(Icons.logout_rounded),
                          type: ButtonType.danger,
                          size: ButtonSize.normal,
                          fullWidth: false,
                          isLoading: isSigningOut,
                          onPressed: _handleLogout,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Profile Information Edit Card ───────────────────────────────────────────

  Widget _buildProfileEditCard(BuildContext context, UserModel? user) {
    final colors = context.colors;

    return QuickContainer(
      p: AppSpacing.xxl,
      radius: AppRadius.lg,
      color: colors.surface,
      border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      shadows: [
        BoxShadow(
          color: colors.onSurface.withValues(alpha: 0.03),
          blurRadius: AppSpacing.md,
          offset: const Offset(0, 2),
        ),
      ],
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title Header
            Row(
              children: [
                QuickContainer(
                  p: AppSpacing.sm,
                  radius: AppRadius.md,
                  color: colors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.badge_outlined,
                    color: colors.primary,
                    size: AppSpacing.xl,
                  ),
                ),
                AppSpacing.md.w,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Information',
                        style: context.textTheme.titleMedium?.bold().colour(
                          colors.onSurface,
                        ),
                      ),
                      Text(
                        'Update your administrator credentials, email address, and contact number',
                        style: context.textTheme.bodySmall
                            ?.size(AppSpacing.md)
                            .colour(colors.onSurfaceSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            AppSpacing.lg.h,
            Divider(
              color: colors.borderLight.withValues(alpha: 0.6),
              height: 1,
            ),
            AppSpacing.xl.h,

            // Full Name Input
            const AppFieldLabel(text: 'Full Name', isRequired: true),
            (AppSpacing.xs + 2).h,
            AppTextField(
              controller: _nameController,
              customPrefixIcon: Icon(
                Icons.person_outline_rounded,
                size: AppSpacing.lg,
                color: colors.onSurfaceSecondary,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter full name (e.g. John Doe)',
              ),
              validator: (value) =>
                  Validators.required(context, value, fieldName: 'Full Name'),
            ),

            AppSpacing.lg.h,

            // Email Input
            const AppFieldLabel(text: 'Email Address', isRequired: true),
            (AppSpacing.xs + 2).h,
            AppTextField.email(
              controller: _emailController,
              customPrefixIcon: Icon(
                Icons.mail_outline_rounded,
                size: AppSpacing.lg,
                color: colors.onSurfaceSecondary,
              ),
              decoration: const InputDecoration(hintText: 'admin@guardup.com'),
              validator: (value) => Validators.email(context, value),
            ),

            AppSpacing.xxl.h,
            Divider(
              color: colors.borderLight.withValues(alpha: 0.6),
              height: 1,
            ),
            AppSpacing.lg.h,

            // Card Action Buttons
            ValueListenableBuilder<bool>(
              valueListenable: _isSavingProfileNotifier,
              builder: (context, isSaving, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: 'Reset',
                      leading: const Icon(Icons.refresh_rounded),
                      type: ButtonType.secondaryOff,
                      size: ButtonSize.normal,
                      fullWidth: false,
                      enabled: !isSaving,
                      onPressed: () => _resetProfileForm(user),
                    ),
                    AppSpacing.md.w,
                    AppButton(
                      text: 'Save Changes',
                      leading: const Icon(Icons.check_rounded),
                      type: ButtonType.primary,
                      size: ButtonSize.normal,
                      fullWidth: false,
                      isLoading: isSaving,
                      onPressed: _handleSaveProfile,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Change Password Card ─────────────────────────────────────────────────────

  Widget _buildChangePasswordCard(BuildContext context) {
    final colors = context.colors;

    return QuickContainer(
      p: AppSpacing.xxl,
      radius: AppRadius.lg,
      color: colors.surface,
      border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      shadows: [
        BoxShadow(
          color: colors.onSurface.withValues(alpha: 0.03),
          blurRadius: AppSpacing.md,
          offset: const Offset(0, 2),
        ),
      ],
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title Header
            Row(
              children: [
                QuickContainer(
                  p: AppSpacing.sm,
                  radius: AppRadius.md,
                  color: colors.secondary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: colors.secondary,
                    size: AppSpacing.xl,
                  ),
                ),
                AppSpacing.md.w,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password',
                        style: context.textTheme.titleMedium?.bold().colour(
                          colors.onSurface,
                        ),
                      ),
                      Text(
                        'Ensure your administrator account uses a strong and uncompromised password',
                        style: context.textTheme.bodySmall
                            ?.size(AppSpacing.md)
                            .colour(colors.onSurfaceSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            AppSpacing.lg.h,
            Divider(
              color: colors.borderLight.withValues(alpha: 0.6),
              height: 1,
            ),
            AppSpacing.xl.h,

            // New Password Input
            const AppFieldLabel(text: 'New Password', isRequired: true),
            (AppSpacing.xs + 2).h,
            AppTextField.password(
              controller: _newPasswordController,
              decoration: const InputDecoration(hintText: 'Enter new password'),
              validator: (value) =>
                  Validators.password(context, value, minLength: 6),
            ),

            AppSpacing.lg.h,

            // Confirm Password Input
            const AppFieldLabel(text: 'Confirm New Password', isRequired: true),
            (AppSpacing.xs + 2).h,
            AppTextField.password(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                hintText: 'Repeat new password',
              ),
              validator: (value) => Validators.confirmPassword(
                context,
                value,
                _newPasswordController.text,
              ),
            ),

            AppSpacing.md.h,

            // Dynamic Security Criteria Badges
            ListenableBuilder(
              listenable: _newPasswordController,
              builder: (context, _) {
                final pwd = _newPasswordController.text;
                final hasMinLength = pwd.length >= 6;
                final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(pwd);
                final hasNumberOrSpecial = RegExp(r'[0-9!@#\$&*~]')
                    .hasMatch(pwd);

                return QuickContainer(
                  p: AppSpacing.md,
                  radius: AppRadius.md,
                  color: colors.backgroundLight,
                  border: Border.all(
                    color: colors.borderLight.withValues(alpha: 0.6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password Requirements',
                        style: context.textTheme.labelMedium?.bold().colour(
                          colors.onSurface,
                        ),
                      ),
                      AppSpacing.xs.h,
                      _buildRequirementItem(
                        context,
                        label: 'At least 6 characters',
                        isMet: hasMinLength,
                      ),
                      (AppSpacing.xs / 2).h,
                      _buildRequirementItem(
                        context,
                        label: 'Contains letters (a-z, A-Z)',
                        isMet: hasLetter,
                      ),
                      (AppSpacing.xs / 2).h,
                      _buildRequirementItem(
                        context,
                        label: 'Contains numbers or special characters',
                        isMet: hasNumberOrSpecial,
                      ),
                    ],
                  ),
                );
              },
            ),

            AppSpacing.xxl.h,
            Divider(
              color: colors.borderLight.withValues(alpha: 0.6),
              height: 1,
            ),
            AppSpacing.lg.h,

            // Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _isChangingPasswordNotifier,
                  builder: (context, isChanging, _) {
                    return AppButton(
                      text: 'Update Password',
                      leading: const Icon(Icons.shield_outlined),
                      type: ButtonType.secondaryPrimary,
                      size: ButtonSize.normal,
                      fullWidth: false,
                      isLoading: isChanging,
                      onPressed: _handleChangePassword,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(
    BuildContext context, {
    required String label,
    required bool isMet,
  }) {
    final colors = context.colors;
    final color = isMet ? colors.success : colors.onSurfaceSecondary;

    return Row(
      children: [
        Icon(
          isMet
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: AppSpacing.md + 1,
          color: color,
        ),
        (AppSpacing.xs + 2).w,
        Text(
          label,
          style: context.textTheme.bodySmall
              ?.size(AppSpacing.md - 1)
              .colour(color),
        ),
      ],
    );
  }
}
