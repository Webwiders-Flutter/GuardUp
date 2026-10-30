import '../entities/location_city_entity.dart';
import '../entities/location_country_entity.dart';
import '../entities/location_state_entity.dart';

abstract class LocationRepository {
  Future<List<LocationCountryEntity>> getCountries({
    int page = 1,
    int limit = 20,
    String? searchQuery,
    bool? showInTravel,
    bool? showInVideoHub,
  });
  Future<LocationCountryEntity?> getCountryById(int id);
  Future<List<LocationCountryEntity>> getCountriesByIds(List<int> ids);

  Future<List<LocationStateEntity>> getStates({
    required int countryId,
    int page = 1,
    int limit = 20,
    String? searchQuery,
    bool? showInTravel,
  });
  Future<LocationStateEntity?> getStateById(int id);

  Future<List<LocationCityEntity>> getCities({
    required int stateId,
    int page = 1,
    int limit = 20,
    String? searchQuery,
    bool? showInTravel,
  });
  Future<List<LocationCityEntity>> getCitiesByCountryId({
    required int countryId,
    int page = 1,
    int limit = 20,
    String? searchQuery,
    bool? showInTravel,
  });
  Future<LocationCityEntity?> getCityById(int id);
}
