import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/layout.extension.dart';
import '/core/extensions/menu.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/di/auth.providers.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/misc/app_avatar.dart';
import '/shared/widgets/misc/app_hover_builder.dart';
import '/features/auth/presentation/screens/profile.screen.dart';
import '/features/auth/presentation/screens/login.screen.dart';

enum _AccountAction { profile, signOut }

/// Top-bar account trigger (avatar, name, email) with profile and sign-out
/// actions. Collapses to the avatar alone below the expanded breakpoint.
class ShellAccountMenu extends ConsumerWidget {
  const ShellAccountMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final adminUser = ref.watch(adminUserControllerProvider).value;
    final authUser = ref.watch(authControllerProvider).value;

    final adminName = adminUser?.name ?? '';
    final metadataName = authUser?.userMetadata?['full_name'] as String? ?? '';
    final name = adminName.isNotBlank
        ? adminName
        : (metadataName.isNotBlank ? metadataName : 'Administrator');
    final adminEmail = adminUser?.email ?? '';
    final email = adminEmail.isNotBlank ? adminEmail : (authUser?.email ?? '');

    final showDetails = context.screenWidth >= AppLayout.expandedBreakpoint;

    return Builder(
      builder: (anchor) => AppHoverBuilder(
        cursor: SystemMouseCursors.click,
        builder: (context, isHovered, _) => Tooltip(
          message: showDetails ? '' : name,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: AppRadius.mdRadius,
              onTap: () => _openMenu(anchor, ref, name: name, email: email),
              child: AnimatedContainer(
                duration: AppDurations.instant,
                padding: EdgeInsets.only(
                  left: AppSpacing.xs,
                  right: showDetails ? AppSpacing.sm : AppSpacing.xs,
                  top: AppSpacing.xs / 2,
                  bottom: AppSpacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: isHovered ? colors.surfaceMuted : colors.transparent,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppAvatar(
                      name: name,
                      size: AppLayout.controlHeightSm,
                      statusColor: colors.success,
                    ),
                    if (showDetails) ...[
                      AppSpacing.sm.w,
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppLayout.sidebarMinWidth - AppSpacing.xxxl,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodySmall
                                  ?.semiBold()
                                  .colour(colors.onSurface),
                            ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.labelSmall?.colour(
                                  colors.onSurfaceSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      AppSpacing.xs.w,
                      Icon(
                        Icons.unfold_more_rounded,
                        size: AppLayout.iconSm,
                        color: colors.onSurfaceSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMenu(
    BuildContext anchor,
    WidgetRef ref, {
    required String name,
    required String email,
  }) async {
    final colors = anchor.colors;

    final action = await anchor.showAnchoredMenu<_AccountAction>(
      constraints: const BoxConstraints(minWidth: AppLayout.sidebarMinWidth),
      items: [
        PopupMenuItem<_AccountAction>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              AppAvatar(name: name, size: AppLayout.avatarMd),
              AppSpacing.md.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: anchor.textTheme.bodyMedium?.semiBold().colour(
                        colors.onSurface,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: anchor.textTheme.bodySmall?.colour(
                          colors.onSurfaceSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<_AccountAction>(
          value: _AccountAction.profile,
          height: AppLayout.menuItemHeight,
          child: _MenuRow(
            icon: Icons.person_outline_rounded,
            label: 'Account profile',
            color: colors.onSurface,
            iconColor: colors.onSurfaceSecondary,
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<_AccountAction>(
          value: _AccountAction.signOut,
          height: AppLayout.menuItemHeight,
          child: _MenuRow(
            icon: Icons.logout_rounded,
            label: 'Sign out',
            color: colors.error,
          ),
        ),
      ],
    );

    if (!anchor.mounted) return;
    switch (action) {
      case _AccountAction.profile:
        anchor.go(ProfileScreen.route);
      case _AccountAction.signOut:
        await _signOut(anchor, ref);
      case null:
        break;
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final result = await AppPopup.showLogoutConfirmation(context);
    if (result?.action != PopupAction.confirm) return;

    final signedOut = await ref.read(authControllerProvider.notifier).signOut();
    if (!signedOut) return;

    AppSnackbar.success('You have been signed out.');
    if (context.mounted) context.go(LoginScreen.route);
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppLayout.iconMd, color: iconColor ?? color),
        AppSpacing.md.w,
        Text(
          label,
          style: context.textTheme.bodyMedium?.medium().colour(color),
        ),
      ],
    );
  }
}
