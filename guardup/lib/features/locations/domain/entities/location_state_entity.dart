import 'package:equatable/equatable.dart';

class LocationStateEntity extends Equatable {
  final int id;
  final int countryId;
  final String nameEn;
  final String nameAr;
  final String? shortDescriptionEn;
  final String? shortDescriptionAr;
  final String? descriptionHtmlEn;
  final String? descriptionHtmlAr;
  final String? imageUrl;
  final bool status;

  const LocationStateEntity({
    required this.id,
    required this.countryId,
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
