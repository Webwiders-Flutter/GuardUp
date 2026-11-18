import 'package:dio/dio.dart';

import '/core/config/config.dart';
import '/core/constants/api/api_endpoints.dart';
import '/core/logger/supabase_logger.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;
  final double? latitude;
  final double? longitude;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
    this.latitude,
    this.longitude,
  });

  PlaceSuggestion copyWith({
    String? placeId,
    String? description,
    String? mainText,
    String? secondaryText,
    double? latitude,
    double? longitude,
  }) {
    return PlaceSuggestion(
      placeId: placeId ?? this.placeId,
      description: description ?? this.description,
      mainText: mainText ?? this.mainText,
      secondaryText: secondaryText ?? this.secondaryText,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class AddressSearchService {
  final Dio _dio;

  AddressSearchService({Dio? dio}) : _dio = dio ?? Dio();

  String get _googleApiKey => AppEnvironment.config.googlePlacesApiKey;

  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    if (_googleApiKey.isNotEmpty) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.googlePlacesAutocomplete,
          queryParameters: {
            'input': trimmed,
            'key': _googleApiKey,
          },
        );

        final data = response.data;
        if (data != null && data['status'] == 'OK') {
          final predictions = data['predictions'] as List<dynamic>? ?? [];
          return predictions.map((p) {
            final pMap = p as Map<String, dynamic>;
            final structured =
                pMap['structured_formatting'] as Map<String, dynamic>?;
            return PlaceSuggestion(
              placeId: pMap['place_id'] as String? ?? '',
              description: pMap['description'] as String? ?? '',
              mainText: structured?['main_text'] as String?,
              secondaryText: structured?['secondary_text'] as String?,
            );
          }).toList();
        }
      } catch (e) {
        SupabaseLogger.warning('Google Places autocomplete error: $e');
      }
    }

    // Fallback: OpenStreetMap Nominatim search
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.nominatimSearch,
        queryParameters: {
          'q': trimmed,
          'format': 'json',
          'addressdetails': '1',
          'limit': '6',
        },
        options: Options(headers: {'User-Agent': 'GuardUp/1.0'}),
      );

      final list = response.data ?? [];
      return list.map((item) {
        final iMap = item as Map<String, dynamic>;
        final displayName = iMap['display_name'] as String? ?? '';
        final parts = displayName.split(',');
        final main = parts.isNotEmpty ? parts.first.trim() : displayName;
        final secondary =
            parts.length > 1 ? parts.sublist(1).join(',').trim() : null;

        return PlaceSuggestion(
          placeId: iMap['place_id']?.toString() ?? '',
          description: displayName,
          mainText: main,
          secondaryText: secondary,
          latitude: double.tryParse(iMap['lat']?.toString() ?? ''),
          longitude: double.tryParse(iMap['lon']?.toString() ?? ''),
        );
      }).toList();
    } catch (e) {
      SupabaseLogger.warning('Nominatim address search error: $e');
      return const [];
    }
  }

  Future<PlaceSuggestion?> getPlaceDetails(
    PlaceSuggestion suggestion,
  ) async {
    // If suggestion already contains coordinates (from Nominatim), return it directly
    if (suggestion.latitude != null && suggestion.longitude != null) {
      return suggestion;
    }

    if (_googleApiKey.isNotEmpty && suggestion.placeId.isNotEmpty) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.googlePlaceDetails,
          queryParameters: {
            'place_id': suggestion.placeId,
            'fields': 'formatted_address,geometry',
            'key': _googleApiKey,
          },
        );

        final data = response.data;
        if (data != null && data['status'] == 'OK') {
          final result = data['result'] as Map<String, dynamic>?;
          final location =
              result?['geometry']?['location'] as Map<String, dynamic>?;
          final formatted = result?['formatted_address'] as String?;

          return suggestion.copyWith(
            description: formatted ?? suggestion.description,
            latitude: (location?['lat'] as num?)?.toDouble(),
            longitude: (location?['lng'] as num?)?.toDouble(),
          );
        }
      } catch (e) {
        SupabaseLogger.warning('Google Place Details error: $e');
      }
    }

    return suggestion;
  }
}

