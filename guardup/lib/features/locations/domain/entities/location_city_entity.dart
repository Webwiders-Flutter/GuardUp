import 'package:equatable/equatable.dart';

class LocationCityEntity extends Equatable {
  final int id;
  final int countryId;
  final int? stateId;
  final String nameEn;
  final String nameAr;
  final String? shortDescriptionEn;
  final String? shortDescriptionAr;
  final String? descriptionHtmlEn;
  final String? descriptionHtmlAr;
  final String? imageUrl;
  final bool status;

  const LocationCityEntity({
    required this.id,
    required this.countryId,
    this.stateId,
    required this.nameEn,
    required this.nameAr,
    this.shortDescriptionEn,
    this.shortDescriptionAr,
    this.descriptionHtmlEn,
    this.descriptionHtmlAr,
    this.imageUrl,
    this.status = true,
  });

  @override
  List<Object?> get props => [
    id,
    countryId,
    stateId,
    nameEn,
    nameAr,
    shortDescriptionEn,
    shortDescriptionAr,
    descriptionHtmlEn,
    descriptionHtmlAr,
    imageUrl,
    status,
  ];
}
