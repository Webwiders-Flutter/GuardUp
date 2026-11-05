import 'package:freezed_annotation/freezed_annotation.dart';

part 'company.model.freezed.dart';
part 'company.model.g.dart';

/// Domain entity representing a licensed private security company.
@freezed
abstract class CompanyModel with _$CompanyModel {
  const CompanyModel._();

  const factory CompanyModel({
    required String id,
    required String name,
    String? initials,
    String? logoUrl,
    @Default(12) int activeGuards,
    @Default(4.9) double rating,
    @Default(214) int reviewCount,
    @Default('340+ Bookings') String bookingsCount,
    @Default('15+ Yrs Exp') String experienceYears,
    @Default(true) bool isVerified,
    @Default(true) bool isOnline,
    String? bio,
    DateTime? joinedAt,
  }) = _CompanyModel;

  factory CompanyModel.fromJson(Map<String, dynamic> json) =>
      _$CompanyModelFromJson(json);


  /// Sample fake security companies for UI mocking, feeds, and tests.
  static List<CompanyModel> get fakeData => [
    const CompanyModel(
      id: 'comp_securepro',
      name: 'SecurePro Security Ltd.',
      initials: 'SP',
      activeGuards: 12,
      rating: 4.9,
      reviewCount: 254,
      bookingsCount: '340+ Bookings',
      experienceYears: '15+ Yrs Exp',
      isVerified: true,
      isOnline: true,
    ),
    const CompanyModel(
      id: 'comp_aegis',
      name: 'Aegis Elite Tactical',
      initials: 'AE',
      activeGuards: 8,
      rating: 4.98,
      reviewCount: 180,
      bookingsCount: '510+ Bookings',
      experienceYears: '22+ Yrs Exp',
      isVerified: true,
      isOnline: true,
    ),
    const CompanyModel(
      id: 'comp_ironclad',
      name: 'Ironclad Protection Group',
      initials: 'IP',
      activeGuards: 16,
      rating: 4.85,
      reviewCount: 310,
      bookingsCount: '420+ Bookings',
      experienceYears: '18+ Yrs Exp',
      isVerified: true,
      isOnline: true,
    ),
  ];
}
