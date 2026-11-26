import 'package:flutter/material.dart';

import '/features/body_guard/data/enum/guard_service.enum.dart';
import '/features/services/data/models/service.model.dart';

/// Display helpers for [ServiceModel] (kept off the model, per the
/// no-model-getters rule).
extension ServiceModelX on ServiceModel {
  /// The local [GuardService] whose code or label matches [ServiceModel.iconName]
  /// first, then [ServiceModel.name].
  GuardService? get guardService =>
      _matchGuardService(iconName) ?? _matchGuardService(name);

  IconData get icon {
    final guard = guardService;
    if (guard != null) return guard.icon;

    final lowerName = name.toLowerCase();
    if (lowerName.contains('close') || lowerName.contains('vip')) {
      return Icons.shield_outlined;
    }
    if (lowerName.contains('arm') || lowerName.contains('escort')) {
      return Icons.security_rounded;
    }
    if (lowerName.contains('driver') ||
        lowerName.contains('car') ||
        lowerName.contains('vehicle')) {
      return Icons.directions_car_filled_outlined;
    }
    if (lowerName.contains('event')) {
      return Icons.event_seat_rounded;
    }
    if (lowerName.contains('residen') ||
        lowerName.contains('home') ||
        lowerName.contains('estate')) {
      return Icons.home_work_outlined;
    }
    if (lowerName.contains('asset')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (lowerName.contains('surveil') || lowerName.contains('recon')) {
      return Icons.visibility_outlined;
    }
    if (lowerName.contains('crisis')) {
      return Icons.emergency_outlined;
    }
    return Icons.verified_user_outlined;
  }
}

GuardService? _matchGuardService(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;
  final normalized = raw.toUpperCase().replaceAll(RegExp(r'[\s\-]+'), '_');
  for (final e in GuardService.values) {
    if (e.apiValue == normalized ||
        e.name.toUpperCase() == normalized ||
        e.label.toUpperCase() == raw.toUpperCase()) {
      return e;
    }
  }
  return null;
}
