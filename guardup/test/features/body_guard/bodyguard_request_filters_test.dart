import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/features/auth/data/enum/user_status.enum.dart';
import 'package:guardup/features/body_guard/data/enum/bodyguard_availability_status.enum.dart';
import 'package:guardup/features/body_guard/data/model/bodyguard_filters.model.dart';
import 'package:guardup/features/body_guard/data/model/bodyguard_profile_request.model.dart';
import 'package:guardup/features/company/data/model/company_filters.model.dart';

void main() {
  group('BodyguardProfileRequest.toJson', () {
    test('trims strings, nulls empty optionals, omits unset optionals', () {
      const request = BodyguardProfileRequest(
        name: '  Ravi ',
        hourlyRate: 40,
        bio: ' Calm. ',
        languages: '  ',
        certifications: ' CPR ',
      );
      expect(request.toJson(), {
        'name': 'Ravi',
        'hourly_rate': 40.0,
        'bio': 'Calm.',
        'languages': null,
        'certifications': 'CPR',
      });
    });

    test('includeIdentity: false leaves name and photo to users', () {
      const request = BodyguardProfileRequest(
        name: 'Ravi',
        hourlyRate: 40,
        bio: 'x',
        profileImageUrl: 'https://img',
        experienceYears: 3,
        latitude: 1.5,
        longitude: 2.5,
      );
      final json = request.toJson(includeIdentity: false);
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('profile_image_url'), isFalse);
      expect(json['experience_years'], 3);
      expect(json['latitude'], 1.5);
      expect(json['longitude'], 2.5);
    });
  });

  group('BodyguardFilters', () {
    test('copyWith keeps values unless given, and can clear to null', () {
      const filters = BodyguardFilters(
        companyId: 'c1',
        statuses: [UserStatus.active],
        availability: BodyguardAvailabilityStatus.available,
      );
      expect(filters.copyWith(), filters);
      final cleared = filters.copyWith(availability: null, companyId: null);
      expect(cleared.availability, isNull);
      expect(cleared.companyId, isNull);
      expect(cleared.statuses, [UserStatus.active]);
      expect(const BodyguardFilters().hasActiveFilters, isFalse);
    });
  });

  group('CompanyFilters', () {
    test('customer default lists ACTIVE companies; can be cleared', () {
      expect(CompanyFilters.customerDefault.statuses, [UserStatus.active]);
      expect(
        CompanyFilters.customerDefault.copyWith(statuses: null).statuses,
        isNull,
      );
    });
  });
}
