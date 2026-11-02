import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../cubit/connectivity_cubit.dart';
import '../cubit/connectivity_state.dart';

enum _ConnectivityBannerState { idle, offline, restored }

/// A modern, non-intrusive floating connectivity banner using flutter_bloc.
///
/// Features:
/// - Floats at the top center without covering the full screen or blocking navigation.
/// - Smooth slide and fade transitions.
/// - Shows offline warning with a retry action and dismiss button.
/// - Gracefully transitions to a "Back online" pill for 2.5s when reconnected.
/// - 100% compliant with the project design system (`rules.md`).
class NoInternetBanner extends StatefulWidget {
  const NoInternetBanner({super.key});

  @override
  State<NoInternetBanner> createState() => _NoInternetBannerState();
}

class _NoInternetBannerState extends State<NoInternetBanner>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final ValueNotifier<_ConnectivityBannerState> _bannerStateNotifier =
      ValueNotifier(_ConnectivityBannerState.idle);
  final ValueNotifier<bool> _isCheckingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isDismissedNotifier = ValueNotifier(false);

  Timer? _restoredTimer;
  ConnectivityStatus? _lastStatus;
  ConnectivityCubit? _fallbackCubit;

  ConnectivityCubit _resolveCubit(BuildContext context) {
    try {
      return context.read<ConnectivityCubit>();
    } catch (_) {
      return _fallbackCubit ??= ConnectivityCubit();
    }
  }

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 280),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // Initial check after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = _resolveCubit(context);
      _lastStatus = cubit.state.status;
      if (cubit.state.isDisconnected) {
        _bannerStateNotifier.value = _ConnectivityBannerState.offline;
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _restoredTimer?.cancel();
    _animController.dispose();
    _pulseController.dispose();
    _bannerStateNotifier.dispose();
    _isCheckingNotifier.dispose();
    _isDismissedNotifier.dispose();
    _fallbackCubit?.close();
    super.dispose();
  }

  void _onDismiss() {
    _isDismissedNotifier.value = true;
    _animController.reverse();
  }

  Future<void> _onRetry() async {
    if (_isCheckingNotifier.value) return;
    _isCheckingNotifier.value = true;
    HapticFeedback.lightImpact();

    try {
      final cubit = _resolveCubit(context);
      final isConnected = await cubit.checkConnection();
      if (!isConnected && mounted) {
        HapticFeedback.mediumImpact();
      }
    } finally {
      if (mounted) {
        _isCheckingNotifier.value = false;
      }
    }
  }

  void _handleStateChange(ConnectivityState state) {
    final prev = _lastStatus;
    _lastStatus = state.status;
    _restoredTimer?.cancel();

    if (state.isDisconnected) {
      _isDismissedNotifier.value = false;
      _bannerStateNotifier.value = _ConnectivityBannerState.offline;
      _animController.forward();
      HapticFeedback.mediumImpact();
    } else if (prev == ConnectivityStatus.disconnected && state.isConnected) {
      // Was offline, now connection is restored
      _bannerStateNotifier.value = _ConnectivityBannerState.restored;
      _isDismissedNotifier.value = false;
      _animController.forward();
      HapticFeedback.lightImpact();

      // Auto-hide after 2.5 seconds
      _restoredTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          _animController.reverse().then((_) {
            if (mounted) {
              _bannerStateNotifier.value = _ConnectivityBannerState.idle;
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveCubit(context);

    return BlocListener<ConnectivityCubit, ConnectivityState>(
      bloc: cubit,
      listener: (context, state) => _handleStateChange(state),
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          if (_animController.value == 0.0 &&
              _bannerStateNotifier.value == _ConnectivityBannerState.idle) {
            return const SizedBox.shrink();
          }

          return ValueListenableBuilder<bool>(
            valueListenable: _isDismissedNotifier,
            builder: (context, isDismissed, _) {
              if (isDismissed && _animController.value == 0.0) {
                return const SizedBox.shrink();
              }

              return SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ValueListenableBuilder<_ConnectivityBannerState>(
                          valueListenable: _bannerStateNotifier,
                          builder: (context, bannerState, _) {
                            return ValueListenableBuilder<bool>(
                              valueListenable: _isCheckingNotifier,
                              builder: (context, isChecking, _) {
                                return _ConnectivityPill(
                                  state: bannerState,
                                  isChecking: isChecking,
                                  pulseAnimation: _pulseAnimation,
                                  onRetry: _onRetry,
                                  onDismiss: _onDismiss,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Floating pill widget rendering either the offline notice or the restored confirmation.
class _ConnectivityPill extends StatelessWidget {
  const _ConnectivityPill({
    required this.state,
    required this.isChecking,
    required this.pulseAnimation,
    required this.onRetry,
    required this.onDismiss,
  });

  final _ConnectivityBannerState state;
  final bool isChecking;
  final Animation<double> pulseAnimation;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRestored = state == _ConnectivityBannerState.restored;

    final accentColor = isRestored ? colors.success : colors.error;
    final accentBgColor = isRestored
        ? colors.successLight.withValues(alpha: 0.15)
        : colors.errorLight.withValues(alpha: 0.15);

    return Material(
      color: colors.surface,
      elevation: 4,
      shadowColor: colors.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.full.toBorderRadius,
        side: BorderSide(color: accentColor.withValues(alpha: 0.28), width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Badge with subtle pulsing ring
              Stack(
                alignment: Alignment.center,
                children: [
                  if (!isRestored)
                    AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (context, _) {
                        return Container(
                          width: AppSpacing.xl,
                          height: AppSpacing.xl,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(
                              alpha: 0.18 * (1 - pulseAnimation.value),
                            ),
                          ),
                        );
                      },
                    ),
                  Container(
                    width: AppSpacing.lg + 4,
                    height: AppSpacing.lg + 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentBgColor,
                    ),
                    child: Icon(
                      isRestored ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      size: AppSizes.iconSm,
                      color: accentColor,
                    ),
                  ),
                ],
              ),

              AppSpacing.sm.w,

              // Status message
              Flexible(
                child: Text(
                  isRestored ? 'Back online' : 'No internet connection',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelMedium
                      ?.increaseSize(1)
                      .semiBold()
                      .colour(colors.onSurface),
                ),
              ),

              AppSpacing.md.w,

              // Action buttons for offline state
              if (!isRestored) ...[
                // Retry Button
                InkWell(
                  onTap: isChecking ? null : onRetry,
                  borderRadius: AppRadius.full.toBorderRadius,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.onSurfaceSecondary.withValues(alpha: 0.08),
                      borderRadius: AppRadius.full.toBorderRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isChecking)
                          SizedBox(
                            width: AppSizes.iconSm,
                            height: AppSizes.iconSm,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation(
                                colors.primary,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.refresh_rounded,
                            size: AppSizes.iconSm,
                            color: colors.primary,
                          ),
                        AppSpacing.xxs.w,
                        Text(
                          isChecking ? 'Checking...' : 'Retry',
                          style: context.textTheme.labelMedium?.bold().colour(
                            colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                AppSpacing.md.w,

                // Dismiss Button
                InkWell(
                  onTap: onDismiss,
                  borderRadius: AppRadius.full.toBorderRadius,
                  child: Padding(
                    padding: AppSpacing.xs.allPadding,
                    child: Icon(
                      Icons.close_rounded,
                      size: AppSizes.iconSm,
                      color: colors.onSurfaceSecondary,
                    ),
                  ),
                ),
              ] else ...[
                // Success indicator icon for restored state
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.successLight.withValues(alpha: 0.15),
                    borderRadius: AppRadius.full.toBorderRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: AppSizes.iconSm,
                        color: colors.success,
                      ),
                      AppSpacing.xxs.w,
                      Text(
                        'Connected',
                        style: context.textTheme.labelMedium?.bold().colour(
                          colors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

