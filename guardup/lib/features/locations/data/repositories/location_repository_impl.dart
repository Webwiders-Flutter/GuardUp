import 'package:flutter/foundation.dart';
import 'package:guardup/core/utils/app_logs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/utils/extensions/string_extensions.dart';
import '../../domain/entities/location_city_entity.dart';
import '../../domain/entities/location_country_entity.dart';
import '../../domain/entities/location_state_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../models/location_city_model.dart';
import '../models/location_country_model.dart';
import '../models/location_state_model.dart';

List<LocationCountryEntity> _parseCountries(List<dynamic> jsonList) {
  return jsonList.map((json) => LocationCountryModel.fromJson(json)).toList();
}

List<LocationStateEntity> _parseStates(List<dynamic> jsonList) {
  return jsonList.map((json) => LocationStateModel.fromJson(json)).toList();
}

List<LocationCityEntity> _parseCities(List<dynamic> jsonList) {
  return jsonList.map((json) => LocationCityModel.fromJson(json)).toList();
}

class LocationRepositoryImpl implements LocationRepository {
  final SupabaseClient _supabaseClient;

  LocationRepositoryImpl(this._supabaseClient);

  SupabaseQueryBuilder get _countriesTable =>
      _supabaseClient.from(SupabaseTables.countries);
  SupabaseQueryBuilder get _statesTable =>
      _supabaseClient.from(SupabaseTables.states);
  SupabaseQueryBuilder get _citiesTable =>
      _supabaseClient.from(SupabaseTables.cities);
  String _escapePostgrestValue(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll(',', '\\,')
        .replaceAll('{', '\\{')
        .replaceAll('}', '\\}');
  }

  @override
  Future<List<LocationCountryEntity>> getCountries({
    int page = 1,
    int limit = 20,
    String? searchQuery,
    bool? showInTravel,
    bool? showInVideoHub,
  }) async {
    try {
      final offset = (page - 1) * limit;
      var query = _countriesTable.select().eq('status', true);
      if (showInTravel != null) {
        query = query.eq('show_in_travel', showInTravel);
      }
      if (showInVideoHub != null) {
        query = query.eq('show_in_video_hub', showInVideoHub);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final normalizedQuery = searchQuery.trim();
        final arabicRegex = normalizedQuery.toArabicSearchRegex();

        query = query.or(
          'name_en.ilike.%$normalizedQuery%,'
          'name_ar.imatch.$arabicRegex,'
          'country_code.ilike.%$normalizedQuery%,'
          'search_keywords.ilike.%$normalizedQuery%',
        );
      }
      // if (searchQuery != null && searchQuery.isNotEmpty) {
      //   final normalizedQuery = searchQuery.trim();
      //   final arabicRegex = normalizedQuery.toArabicSearchRegex();

      //   query = query.or(
      //     'name_en.ilike.%$normalizedQuery%,'
      //     'name_ar.imatch.$arabicRegex,'
      //     'country_code.ilike.%$normalizedQuery%',
      //   );
      // }

      final response = await query
          .order('sort_order', ascending: true)
          .range(offset, offset + limit - 1);

      return await compute(_parseCountries, response as List);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to get countries',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to get countries: $e');
    }
  }

  @override
  Future<LocationCountryEntity?> getCountryById(int id) async {
    try {
      final response = await _countriesTable
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return LocationCountryModel.fromJson(response);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to get country by id',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to get country by id: $e');
    }
  }

  @override
  Future<List<LocationCountryEntity>> getCountriesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await _countriesTable.select().inFilter('id', ids);
      return await compute(_parseCountries, response as List);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to get countries by ids',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to get countries by ids: $e');
    }
  }

  @override
  Future<List<LocationStateEntity>> getStates({
    required int countryId,
    int page = 1,
    int limit = 20,
    String? searchQuery,
    bool? showInTravel,
  }) async {
    try {
      final offset = (page - 1) * limit;
      var query = _statesTable
          .select()
          .eq('country_id', countryId)
          .eq('status', true);

      if (showInTravel != null) {
        query = query.eq('show_in_travel', showInTravel);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final normalizedQuery = searchQuery.trim();
        final arabicRegex = normalizedQuery.toArabicSearchRegex();
        query = query.or(
          'name_en.ilike.%$normalizedQuery%,name_ar.imatch.$arabicRegex,search_keywords.ilike.%$normalizedQuery%',
        );
      }

      final response = await query
          .order('name_en', ascending: true)
          .range(offset, offset + limit - 1);

      return await compute(_parseStates, response as List);
    } catch (e, stackTrace) {
      AppLogs.error('Failed to get states', error: e, stackTrace: stackTrace);
      throw Exception('Failed to get states: $e');
    }
  }

  @override
  Future<LocationStateEntity?> getStateById(int id) async {
    try {
      final response = await _statesTable.select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return LocationStateModel.fromJson(response);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to get state by id',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to get state by id: $e');
    }
  }

  @override
  Future<List<LocationCityEntity>> getCities({
    required int stateId,
    int page = 1,
    int limit = 20,
    String? searchQuery,
    bool? showInTravel,
  }) async {
    try {
      final offset = (page - 1) * limit;
      var query = _citiesTable
          .select()
          .eq('state_id', stateId)
          .eq('status', true);

      if (showInTravel != null) {
        query = query.eq('show_in_travel', showInTravel);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final normalizedQuery = searchQuery.trim();
        final arabicRegex = normalizedQuery.toArabicSearchRegex();
        query = query.or(
          'name_en.ilike.%$normalizedQuery%,name_ar.imatch.$arabicRegex,search_keywords.ilike.%$normalizedQuery%',
        );
      }

      final response = await query
          .order('name_en', ascending: true)
          .range(offset, offset + limit - 1);

      return await compute(_parseCities, response as List);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to get cities by state',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to get cities: $e');
    }
  }

  @override
  Future<List<LocationCityEntity>> getCitiesByCountryId({
    required int countryId,
    int page = 1,
    int limit = 20,
    String? searchQuery,
    bool? showInTravel,
  }) async {
    try {
      final offset = (page - 1) * limit;
      var query = _citiesTable
          .select()
          .eq('country_id', countryId)
          .eq('status', true);

      if (showInTravel != null) {
        query = query.eq('show_in_travel', showInTravel);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final normalizedQuery = searchQuery.trim();
        final arabicRegex = normalizedQuery.toArabicSearchRegex();
        query = query.or(
          'name_en.ilike.%$normalizedQuery%,name_ar.imatch.$arabicRegex,search_keywords.ilike.%$normalizedQuery%',
        );
      }

      final response = await query
          .order('name_en', ascending: true)
          .range(offset, offset + limit - 1);

      return await compute(_parseCities, response as List);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to get cities by country',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to get cities by country: $e');
    }
  }

  @override
  Future<LocationCityEntity?> getCityById(int id) async {
    try {
      final response = await _citiesTable.select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return LocationCityModel.fromJson(response);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to get city by id',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to get city by id: $e');
    }
  }
}
