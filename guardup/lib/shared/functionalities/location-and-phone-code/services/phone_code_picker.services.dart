import 'dart:convert';

import 'package:csc_picker_plus/model/select_status_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';

class LocationPhoneCodeServices {
  LocationPhoneCodeServices._();

  // ---------------------------------------------------------------------------
  // Assets
  // ---------------------------------------------------------------------------

  static const String _countriesAsset =
      'packages/csc_picker_plus/lib/assets/countries.json';

  // ---------------------------------------------------------------------------
  // Phone Countries
  // ---------------------------------------------------------------------------

  static final ValueNotifier<Map<String, CountryWithPhoneCode>>
      phoneCountries = ValueNotifier({});

  static final CountryWithPhoneCode defaultPhoneCountry =
      CountryWithPhoneCode(
    phoneCode: '91',
    countryCode: 'IN',
    exampleNumberMobileNational: '91234 56789',
    exampleNumberFixedLineNational: '022 1234 5678',
    phoneMaskMobileNational: '+00 00000 00000',
    phoneMaskFixedLineNational: '+00 000 0000 0000',
    exampleNumberMobileInternational: '+91 91234 56789',
    exampleNumberFixedLineInternational: '+91 22 1234 5678',
    phoneMaskMobileInternational: '+00 00000 00000',
    phoneMaskFixedLineInternational: '+00 00 0000 0000',
    countryName: 'India',
  );

  // ---------------------------------------------------------------------------
  // Location Data
  // ---------------------------------------------------------------------------

  static List<Country> _countries = [];

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Call this once from application bootstrap.
  static Future<void> init() async {
    await Future.wait([
      _loadPhoneCountries(),
      _loadLocations(),
    ]);
  }

  static Future<void> _loadPhoneCountries() async {
    try {
      phoneCountries.value = await getAllSupportedRegions();
    } catch (_) {
      // Keep the existing empty map if initialization fails.
    }
  }

  static Future<void> _loadLocations() async {
    final jsonString = await rootBundle.loadString(_countriesAsset);

    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      throw const FormatException(
        'Invalid countries.json format. Expected a JSON array.',
      );
    }

    _countries = decoded
        .map(
          (item) => Country.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  // ===========================================================================
  // PHONE CODE METHODS
  // ===========================================================================

  static List<CountryWithPhoneCode> getPhoneCountries() {
    return List.unmodifiable(phoneCountries.value.values);
  }

  static CountryWithPhoneCode? getPhoneCountryByCode(
    String countryCode,
  ) {
    final code = countryCode.trim().toUpperCase();

    if (code.isEmpty) return null;

    for (final country in phoneCountries.value.values) {
      if (country.countryCode.toUpperCase() == code) {
        return country;
      }
    }

    return null;
  }

  static CountryWithPhoneCode? getPhoneCountryByDialCode(
    String phoneCode,
  ) {
    final cleanCode = phoneCode.replaceAll(RegExp(r'\D'), '');

    if (cleanCode.isEmpty) return null;

    for (final country in phoneCountries.value.values) {
      if (country.phoneCode == cleanCode) {
        return country;
      }
    }

    return null;
  }

  /// Finds a [CountryWithPhoneCode] by country ISO code (e.g. 'IN', 'US')
  /// or phone dial code (e.g. '+91', '91', '+1').
  ///
  /// Includes static fallbacks if [phoneCountries] is not yet loaded.
  static CountryWithPhoneCode? findCountryByCode(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;

    // 1. Try ISO alpha-2 country code (e.g. 'IN', 'US')
    final byCode = getPhoneCountryByCode(trimmed);
    if (byCode != null) return byCode;

    // 2. Try dial code (e.g. '+91', '91')
    final byDial = getPhoneCountryByDialCode(trimmed);
    if (byDial != null) return byDial;

    // 3. Static fallback before phoneCountries is populated via async init()
    final cleanUpper = trimmed.toUpperCase();
    final cleanDigits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (cleanUpper == 'IN' || cleanDigits == '91') {
      return defaultPhoneCountry;
    }
    if (cleanUpper == 'US' || cleanDigits == '1') {
      return const CountryWithPhoneCode.us();
    }
    if (cleanUpper == 'GB' || cleanDigits == '44') {
      return const CountryWithPhoneCode.gb();
    }

    return null;
  }

  static CountryWithPhoneCode? findPhoneCountry(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');

    if (clean.isEmpty) return null;

    return phoneCountries.value.values
        .where((country) => clean.startsWith(country.phoneCode))
        .fold<CountryWithPhoneCode?>(
      null,
      (longest, current) {
        if (longest == null ||
            current.phoneCode.length > longest.phoneCode.length) {
          return current;
        }

        return longest;
      },
    );
  }

  static CountryWithPhoneCode? findPhoneCountrySync(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');

    if (clean.isEmpty || phoneCountries.value.isEmpty) {
      return null;
    }

    return phoneCountries.value.values
        .where((country) => clean.startsWith(country.phoneCode))
        .fold<CountryWithPhoneCode?>(
      null,
      (longest, current) {
        if (longest == null ||
            current.phoneCode.length > longest.phoneCode.length) {
          return current;
        }

        return longest;
      },
    );
  }

  static List<CountryWithPhoneCode> filterPhoneCountries(
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return phoneCountries.value.values.toList();
    }

    final cleanDigits =
        normalizedQuery.replaceAll(RegExp(r'[^\d]'), '');

    return phoneCountries.value.values.where((country) {
      final countryName =
          (country.countryName ?? '').toLowerCase();

      final countryCode =
          country.countryCode.toLowerCase();

      final phoneCode = country.phoneCode;

      return countryName.contains(normalizedQuery) ||
          countryCode.contains(normalizedQuery) ||
          (cleanDigits.isNotEmpty &&
              phoneCode.contains(cleanDigits));
    }).toList();
  }

  static String countryFlagEmoji(String countryCode) {
    if (countryCode.length != 2) return '';

    final code = countryCode.toUpperCase();

    return String.fromCharCodes(
      code.codeUnits.map(
        (c) => 0x1F1E6 + c - 65,
      ),
    );
  }

  // ===========================================================================
  // LOCATION METHODS
  // ===========================================================================

  static List<Country> getCountries() {
    return List.unmodifiable(_countries);
  }

  static Country? getCountryById(int countryId) {
    return _findCountryById(countryId);
  }

  static Country? _findCountryById(int countryId) {
    for (final country in _countries) {
      if (country.id == countryId) {
        return country;
      }
    }

    return null;
  }

  static List<Region> getStates(int countryId) {
    final country = _findCountryById(countryId);

    if (country == null || country.state == null) {
      return const [];
    }

    return List.unmodifiable(country.state!);
  }

  static Region? getStateById(
    int countryId,
    int stateId,
  ) {
    final country = _findCountryById(countryId);

    if (country == null || country.state == null) {
      return null;
    }

    for (final state in country.state!) {
      if (state.id == stateId) {
        return state;
      }
    }

    return null;
  }

  static List<City> getCities(
    int countryId,
    int stateId,
  ) {
    final state = getStateById(
      countryId,
      stateId,
    );

    if (state == null || state.city == null) {
      return const [];
    }

    return List.unmodifiable(state.city!);
  }

  static City? getCityById(
    int countryId,
    int stateId,
    int cityId,
  ) {
    final state = getStateById(
      countryId,
      stateId,
    );

    if (state == null || state.city == null) {
      return null;
    }

    for (final city in state.city!) {
      if (city.id == cityId) {
        return city;
      }
    }

    return null;
  }

  // ===========================================================================
  // LOCATION FILTERING
  // ===========================================================================

  static List<Country> filterCountries(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return List.unmodifiable(_countries);
    }

    return _countries.where((country) {
      final name = country.name?.toLowerCase() ?? '';
      final nameAr = country.nameAr?.toLowerCase() ?? '';

      return name.contains(normalizedQuery) ||
          nameAr.contains(normalizedQuery);
    }).toList();
  }

  static List<Region> filterStates(
    int countryId,
    String query,
  ) {
    final country = _findCountryById(countryId);

    if (country == null || country.state == null) {
      return const [];
    }

    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return List.unmodifiable(country.state!);
    }

    return country.state!.where((state) {
      final name = state.name?.toLowerCase() ?? '';
      final nameAr = state.nameAr?.toLowerCase() ?? '';

      return name.contains(normalizedQuery) ||
          nameAr.contains(normalizedQuery);
    }).toList();
  }

  static List<City> filterCities(
    int countryId,
    int stateId,
    String query,
  ) {
    final state = getStateById(
      countryId,
      stateId,
    );

    if (state == null || state.city == null) {
      return const [];
    }

    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return List.unmodifiable(state.city!);
    }

    return state.city!.where((city) {
      final name = city.name?.toLowerCase() ?? '';

      return name.contains(normalizedQuery);
    }).toList();
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  static Country? getCountryByName(String name) {
    final normalizedName = name.trim().toLowerCase();

    if (normalizedName.isEmpty) {
      return null;
    }

    for (final country in _countries) {
      if ((country.name?.toLowerCase() ?? '') == normalizedName) {
        return country;
      }
    }

    return null;
  }

  // ===========================================================================
  // CACHE
  // ===========================================================================

  static void clearLocationCache() {
    _countries = [];
  }

  static void clearPhoneCountryCache() {
    phoneCountries.value = {};
  }
}