import '../../domain/entities/location_state_entity.dart';

class LocationStateModel extends LocationStateEntity {
  const LocationStateModel({
    required super.id,
    required super.countryId,
    required super.nameEn,
    required super.nameAr,
    super.shortDescriptionEn,
    super.shortDescriptionAr,
    super.descriptionHtmlEn,
    super.descriptionHtmlAr,
    super.imageUrl,
    super.status,
  });

  factory LocationStateModel.fromJson(Map<String, dynamic> json) {
    return LocationStateModel(
      id: json['id'] as int,
      countryId: json['country_id'] as int,
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
