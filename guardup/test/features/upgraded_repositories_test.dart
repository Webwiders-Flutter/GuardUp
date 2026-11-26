import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:guardup/features/body_guard/body_guard.dart';
import 'package:guardup/features/company/company.dart';

void main() {
  group('Repository Upgrades Contract Tests', () {
    test(
      'BodyguardFilters interacts with BodyguardRepository.getPaginated',
      () {
        const filters = BodyguardFilters(
          companyId: '4b791696-6d65-4f4b-871d-8524cb185c7d',
          statuses: [UserStatus.active],
          availability: BodyguardAvailabilityStatus.available,
        );

        expect(filters.companyId, '4b791696-6d65-4f4b-871d-8524cb185c7d');
        expect(filters.statuses, [UserStatus.active]);
        expect(filters.availability, BodyguardAvailabilityStatus.available);
      },
    );

    test('CompanyFilters interacts with CompanyRepository.getPaginated', () {
      const filters = CompanyFilters(statuses: [UserStatus.active]);

      expect(filters.statuses, [UserStatus.active]);
    });

    test(
      'BodyguardProfileRequest supports managed vs account serialization',
      () {
        const req = BodyguardProfileRequest(
          name: 'John Guard',
          hourlyRate: 50.0,
          bio: 'Professional bodyguard',
          experienceYears: 5,
          profileImageUrl: 'https://example.com/photo.jpg',
        );

        final managedJson = req.toJson(includeIdentity: true);
        expect(managedJson['name'], 'John Guard');
        expect(
          managedJson['profile_image_url'],
          'https://example.com/photo.jpg',
        );
        expect(managedJson['hourly_rate'], 50.0);

        final accountJson = req.toJson(includeIdentity: false);
        expect(accountJson.containsKey('name'), isFalse);
        expect(accountJson.containsKey('profile_image_url'), isFalse);
        expect(accountJson['hourly_rate'], 50.0);
      },
    );

    test('CompanyProfileRequest serializes correctly for upsertForAccount', () {
      const req = CompanyProfileRequest(
        companyName: 'Shield Protection Ltd',
        businessEmail: 'info@shield.com',
        companyType: BusinessType.pvtLtd,
        companyPhoneNumber: '9876543210',
      );

      final json = req.toJson();
      expect(json['company_name'], 'Shield Protection Ltd');
      expect(json['business_email'], 'info@shield.com');
      expect(json['company_type'], 'PVT_LTD');
      expect(json['company_phone_number'], '9876543210');
    });

    test('UserAccountRequest serializes for updateAccount', () {
      const req = UserAccountRequest(
        name: 'Aman Deep',
        email: 'aman@guardup.com',
        gender: GenderType.male,
      );

      final json = req.toJson();
      expect(json['name'], 'Aman Deep');
      expect(json['email'], 'aman@guardup.com');
      expect(json['gender'], 'MALE');
    });
  });
}
