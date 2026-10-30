import 'package:equatable/equatable.dart';

class LocationCountryEntity extends Equatable {
  final int id;
  final String countryCode;
  final String nameEn;
  final String nameAr;
  final String? shortDescriptionEn;
  final String? shortDescriptionAr;
  final String? descriptionHtmlEn;
  final String? descriptionHtmlAr;
  final String? imageUrl;
  final bool status;
  final bool showInVideoHub;
  final int videoHubSortOrder;

  const LocationCountryEntity({
    required this.id,
    required this.countryCode,
    required this.nameEn,
    required this.nameAr,
    this.shortDescriptionEn,
    this.shortDescriptionAr,
    this.descriptionHtmlEn,
    this.descriptionHtmlAr,
    this.imageUrl,
    this.status = true,
    this.showInVideoHub = false,
    this.videoHubSortOrder = 0,
  });

  @override
  List<Object?> get props => [
    id,
    countryCode,
    nameEn,
    nameAr,
    shortDescriptionEn,
    shortDescriptionAr,
    descriptionHtmlEn,
    descriptionHtmlAr,
    imageUrl,
    status,
    showInVideoHub,
    videoHubSortOrder,
  ];
}
