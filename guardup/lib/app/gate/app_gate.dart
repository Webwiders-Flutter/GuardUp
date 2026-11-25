import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/app/screens/app_maintenance_screen.dart';
import '/app/screens/force_update_screen.dart';
import '/app/screens/optional_update_dialog.dart';
import '/core/config/admin_settings/admin_settings.dart';
import '/core/logger/app_logger.dart';
import 'cubit/app_gate_cubit.dart';

/// Top-level gate widget that monitors platform configuration (maintenance mode,
/// mandatory updates, and optional updates) and displays the corresponding screen
/// or prompt over the normal application flow.
class AppGate extends StatefulWidget {
  final Widget child;

  const AppGate({super.key, required this.child});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check for optional update after the first frame (covers the initial state
    // that BlocConsumer.listener misses because it was emitted before mount).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryShowOptionalUpdate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        AppLogger.d('AppLifecycleState.resumed', tag: 'AppGate');
        context.read<AppGateCubit>().checkAgain();
        break;
      case AppLifecycleState.inactive:
        AppLogger.d('AppLifecycleState.inactive', tag: 'AppGate');
        break;
      case AppLifecycleState.paused:
        AppLogger.d('AppLifecycleState.paused', tag: 'AppGate');
        break;
      case AppLifecycleState.detached:
        AppLogger.d('AppLifecycleState.detached', tag: 'AppGate');
        break;
      case AppLifecycleState.hidden:
        AppLogger.d('AppLifecycleState.hidden', tag: 'AppGate');
        break;
    }
  }

  /// Shows the optional update dialog if applicable and not yet dismissed.
  void _tryShowOptionalUpdate() {
    if (!mounted) return;
    final cubit = context.read<AppGateCubit>();
    if (!cubit.shouldPromptOptionalUpdate) return;

    OptionalUpdateDialog.show(
      context: context,
      currentVersion: cubit.currentVersion,
      targetVersion: cubit.latestVersion,
      updateMessage: cubit.updateMessage,
      onUpdateNow: () => cubit.performUpdate(immediate: false),
      onLater: () => cubit.dismissOptionalUpdate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppGateCubit, AdminSettingsModel>(
      listener: (context, settings) {
        // Handles real-time changes (e.g. admin updates latestVersion while app is open).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tryShowOptionalUpdate();
        });
      },
      builder: (context, settings) {
        final cubit = context.read<AppGateCubit>();

        // 1. Platform Maintenance Gate (Hard Block)
        if (cubit.isUnderMaintenance) {
          return _GateHost(
            child: AppMaintenanceScreen(
              settings: settings,
              isChecking: cubit.isChecking,
              onCheckAgain: () => cubit.checkAgain(),
            ),
          );
        }

        // 2. Mandatory Force Update Gate (Hard Block)
        if (cubit.isForceUpdateRequired) {
          return _GateHost(
            child: ForceUpdateScreen(
              settings: settings,
              currentVersion: cubit.currentVersion,
              targetVersion: cubit.minimumVersion,
              updateMessage: cubit.updateMessage,
              onUpdateNow: () => cubit.performUpdate(immediate: true),
            ),
          );
        }

        // 3. Normal Application Flow
        return widget.child;
      },
    );
  }
}

/// Hosts blocking gate screens inside an isolated [Navigator] to provide
/// the required [Overlay] ancestor for tooltips, ripples, and snackbars.
class _GateHost extends StatelessWidget {
  final Widget child;

  const _GateHost({required this.child});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onDidRemovePage: (_) {},
      pages: [
        MaterialPage<void>(
          child: child,
        ),
      ],
    );
  }
}
