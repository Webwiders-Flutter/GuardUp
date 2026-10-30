import 'dart:ui' as ui;

import 'package:sim_reader/sim_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:guardup/core/widgets/app_phone_textfield/app_phone_textfield.dart';

class CountryDetectorService {
  /// Detects country ISO code using priority order:
  /// 1. SIM / Network Country ISO
  /// 2. Device Region / Locale Settings
  /// 3. Returns null if unable to detect automatically
  static Future<String?> detectCountryIsoCode() async {
    // 1. Try SIM / Network Country Code
    try {
      final List<SimInfo> sims = await SimReader.getAllSimInfo();
      for (final sim in sims) {
        if (sim.countryCode != null && sim.countryCode!.trim().isNotEmpty) {
          return sim.countryCode!.trim().toUpperCase();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('SIM/Network country detection failed: $e');
      }
    }

    // 2. Try Country/Region in Device Settings
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      final deviceCountryCode = locale.countryCode;
      if (deviceCountryCode != null && deviceCountryCode.trim().isNotEmpty) {
        return deviceCountryCode.trim().toUpperCase();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Device settings country detection failed: $e');
      }
    }

    // 3. Could not detect automatically
    return null;
  }

  /// Returns CountryWithPhoneCode matching detected country ISO code.
  static Future<CountryWithPhoneCode?> detectCountryWithPhoneCode({
    String? defaultCountryCode,
  }) async {
    if (PhoneNumberServices.all.value.isEmpty) {
      await PhoneNumberServices.init();
    }
    final allCountries = PhoneNumberServices.all.value;

    final detectedIso = await detectCountryIsoCode();

    if (detectedIso != null && allCountries.containsKey(detectedIso)) {
      return allCountries[detectedIso];
    }

    if (defaultCountryCode != null &&
        allCountries.containsKey(defaultCountryCode)) {
      return allCountries[defaultCountryCode];
    }

    return null;
  }
}
