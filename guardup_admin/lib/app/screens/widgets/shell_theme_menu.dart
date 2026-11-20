import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/constants/app_layout.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/menu.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/providers/theme/theme.provider.dart';
import '/shared/widgets/buttons/app_icon_button.dart';

/// Presentation spec for a theme mode option.
typedef _ThemeModeSpec = ({String label, IconData icon, IconData menuIcon});

/// Top-bar button that switches between light, dark and system theme.
class ShellThemeMenu extends ConsumerWidget {
  const ShellThemeMenu({super.key});

  static const Map<ThemeMode, _ThemeModeSpec> _specs = {
    ThemeMode.light: (
      label: 'Light',
      icon: Icons.light_mode_rounded,
      menuIcon: Icons.light_mode_outlined,
    ),
    ThemeMode.dark: (
      label: 'Dark',
      icon: Icons.dark_mode_rounded,
      menuIcon: Icons.dark_mode_outlined,
    ),
    ThemeMode.system: (
      label: 'System',
      icon: Icons.brightness_auto_rounded,
      menuIcon: Icons.brightness_auto_outlined,
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode =
        ref.watch(themeControllerProvider).value ?? ThemeMode.system;
    final spec = _specs[currentMode]!;

    return Builder(
      builder: (anchor) => AppIconButton(
        icon: spec.icon,
        tooltip: 'Theme: ${spec.label}',
        foregroundColor: context.colors.primary,
        onPressed: () async {
          final selected = await anchor.showAnchoredMenu<ThemeMode>(
            items: [
              for (final MapEntry(key: mode, value: option) in _specs.entries)
                PopupMenuItem<ThemeMode>(
                  value: mode,
                  height: AppLayout.menuItemHeight,
                  child: _ThemeOption(
                    spec: option,
                    isSelected: mode == currentMode,
                  ),
                ),
            ],
          );
          if (selected != null) {
            ref.read(themeControllerProvider.notifier).changeTheme(selected);
          }
        },
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.spec, required this.isSelected});

  final _ThemeModeSpec spec;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isSelected ? colors.primary : colors.onSurface;

    return Row(
      children: [
        Icon(
          spec.menuIcon,
          size: AppLayout.iconSm,
          color: isSelected ? colors.primary : colors.onSurfaceSecondary,
        ),
        AppSpacing.md.w,
        Expanded(
          child: Text(
            spec.label,
            style:
                (isSelected
                        ? context.textTheme.bodyMedium?.semiBold()
                        : context.textTheme.bodyMedium?.medium())
                    ?.colour(color),
          ),
        ),
        if (isSelected)
          Icon(Icons.check_rounded, size: AppLayout.iconSm, color: color),
      ],
    );
  }
}
