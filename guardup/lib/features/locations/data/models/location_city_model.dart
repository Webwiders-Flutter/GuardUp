import '../../domain/entities/location_city_entity.dart';

class LocationCityModel extends LocationCityEntity {
  const LocationCityModel({
    required super.id,
    required super.countryId,
    super.stateId,
    required super.nameEn,
    required super.nameAr,
    super.shortDescriptionEn,
    super.shortDescriptionAr,
    super.descriptionHtmlEn,
    super.descriptionHtmlAr,
    super.imageUrl,
    super.status,
  });

  factory LocationCityModel.fromJson(Map<String, dynamic> json) {
    return LocationCityModel(
      id: json['id'] as int,
      countryId: json['country_id'] as int,
      stateId: json['state_id'] as int?,
      nameEn: json['name_en'] as String,
      nameAr: json['name_ar'] as String,
      shortDescriptionEn: json['short_description_en'] as String?,
      shortDescriptionAr: json['short_description_ar'] as String?,
      descriptionHtmlEn: json['description_html_en'] as String?,
      descriptionHtmlAr: json['description_html_ar'] as String?,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as bool? ?? true,
    );
  }
}
