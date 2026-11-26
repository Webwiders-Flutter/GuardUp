import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/app_localizations.dart';

/// Enum representing services offered by bodyguard specialists.
enum GuardService {
  @JsonValue('VIP_CLOSE_PROTECTION')
  vipCloseProtection('VIP_CLOSE_PROTECTION'),

  @JsonValue('ARMED_ESCORT')
  armedEscort('ARMED_ESCORT'),

  @JsonValue('TACTICAL_DRIVER')
  tacticalDriver('TACTICAL_DRIVER'),

  @JsonValue('EVENT_SECURITY')
  eventSecurity('EVENT_SECURITY'),

  @JsonValue('RESIDENTIAL_PROTECTION')
  residentialProtection('RESIDENTIAL_PROTECTION'),

  @JsonValue('ASSET_PROTECTION')
  assetProtection('ASSET_PROTECTION'),

  @JsonValue('SURVEILLANCE_RECON')
  surveillanceRecon('SURVEILLANCE_RECON'),

  @JsonValue('CRISIS_MANAGEMENT')
  crisisManagement('CRISIS_MANAGEMENT');

  final String apiValue;

  const GuardService(this.apiValue);

  String get label {
    switch (this) {
      case GuardService.vipCloseProtection:
        return 'VIP Close Protection';
      case GuardService.armedEscort:
        return 'Armed Escort';
      case GuardService.tacticalDriver:
        return 'Tactical Driver';
      case GuardService.eventSecurity:
        return 'Event Security';
      case GuardService.residentialProtection:
        return 'Residential Protection';
      case GuardService.assetProtection:
        return 'Asset Protection';
      case GuardService.surveillanceRecon:
        return 'Surveillance & Recon';
      case GuardService.crisisManagement:
        return 'Crisis Management';
    }
  }

  String localizedLabel(AppLocalizations l10n) => label;

  IconData get icon {
    switch (this) {
      case GuardService.vipCloseProtection:
        return Icons.security_rounded;
      case GuardService.armedEscort:
        return Icons.shield_rounded;
      case GuardService.tacticalDriver:
        return Icons.directions_car_rounded;
      case GuardService.eventSecurity:
        return Icons.event_available_rounded;
      case GuardService.residentialProtection:
        return Icons.home_rounded;
      case GuardService.assetProtection:
        return Icons.lock_rounded;
      case GuardService.surveillanceRecon:
        return Icons.visibility_rounded;
      case GuardService.crisisManagement:
        return Icons.warning_amber_rounded;
    }
  }
}
