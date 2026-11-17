import 'package:flutter/material.dart';

/// Semantic sections available in the Admin Settings screen.
enum SettingsSection {
  overview(
    label: 'Overview',
    description: 'System health, release status & operational snapshot',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  fees(
    label: 'Platform Fees',
    description: 'Bodyguard rates, company commission & service fee schedule',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments_rounded,
  ),
  core(
    label: 'Core & Maintenance',
    description: 'Platform availability, maintenance mode & downtime alerts',
    icon: Icons.tune_outlined,
    selectedIcon: Icons.tune_rounded,
  ),
  mobileApps(
    label: 'Mobile Apps & Releases',
    description: 'iOS & Android versions, force update policies & store links',
    icon: Icons.system_update_alt_rounded,
    selectedIcon: Icons.system_update_rounded,
  ),
  support(
    label: 'Support Channels',
    description: 'Customer contact lines, WhatsApp business & operating hours',
    icon: Icons.support_agent_outlined,
    selectedIcon: Icons.support_agent_rounded,
  );

  final String label;
  final String description;
  final IconData icon;
  final IconData selectedIcon;

  const SettingsSection({
    required this.label,
    required this.description,
    required this.icon,
    required this.selectedIcon,
  });
}
