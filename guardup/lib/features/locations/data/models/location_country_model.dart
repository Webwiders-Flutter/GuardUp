import '../../domain/entities/location_country_entity.dart';

class LocationCountryModel extends LocationCountryEntity {
  const LocationCountryModel({
    required super.id,
    required super.countryCode,
    required super.nameEn,
    required super.nameAr,
    super.shortDescriptionEn,
    super.shortDescriptionAr,
    super.descriptionHtmlEn,
    super.descriptionHtmlAr,
    super.imageUrl,
    super.status,
    super.showInVideoHub,
    super.videoHubSortOrder,
  });

  factory LocationCountryModel.fromJson(Map<String, dynamic> json) {
    return LocationCountryModel(
      id: json['id'] as int,
      countryCode: json['country_code'] as String,
      nameEn: json['name_en'] as String,
      nameAr: json['name_ar'] as String,
      shortDescriptionEn: json['short_description_en'] as String?,
      shortDescriptionAr: json['short_description_ar'] as String?,
      descriptionHtmlEn: json['description_html_en'] as String?,
      descriptionHtmlAr: json['description_html_ar'] as String?,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as bool? ?? true,
      showInVideoHub: json['show_in_video_hub'] as bool? ?? false,
      videoHubSortOrder: json['video_hub_sort_order'] as int? ?? 0,
    );
  }
}
