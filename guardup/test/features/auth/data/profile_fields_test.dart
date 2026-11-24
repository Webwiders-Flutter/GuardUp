import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/features/auth/data/profile_fields.dart';

/// Payloads below are the ones the screens send to
/// `UserRepository.updateProfileFields`.
void main() {
  group('ProfileFields.split', () {
    test('guard key details: rate etc. to bodyguards, address to users', () {
      final split = ProfileFields.split({
        'experience_years': 7,
        'hourly_rate': 55.0,
        'address': 'Street 1',
        'latitude': 1.0,
        'longitude': 2.0,
        'languages': 'English',
        'certifications': 'CPR',
      }, 'GUARD');

      expect(split.profileTable, 'bodyguards');
      expect(split.profile, {
        'experience_years': 7,
        'hourly_rate': 55.0,
        'languages': 'English',
        'certifications': 'CPR',
      });
      expect(split.account, {
        'address': 'Street 1',
        'latitude': 1.0,
        'longitude': 2.0,
      });
      expect(split.ignored, isEmpty);
    });

    test('guard complete profile: name / photo stay on users', () {
      final split = ProfileFields.split({
        'name': 'Vikram',
        'hourly_rate': 60.0,
        'bio': 'Former special forces operative',
        'profile_image_url': 'https://x/avatar.jpg',
      }, 'GUARD');

      expect(split.profileTable, 'bodyguards');
      expect(split.profile.keys, unorderedEquals(['hourly_rate', 'bio']));
      expect(
        split.account.keys,
        unorderedEquals(['name', 'profile_image_url']),
      );
    });

    test('company complete profile: company columns to companies', () {
      final split = ProfileFields.split({
        'company_name': 'Apex',
        'name': 'Apex',
        'business_email': 'biz@apex.com',
        'company_phone_number': '999',
        'company_phone_code': '+1',
        'company_type': 'AGENCY',
      }, 'COMPANY');

      expect(split.profileTable, 'companies');
      expect(
        split.profile.keys,
        unorderedEquals([
          'company_name',
          'business_email',
          'company_phone_number',
          'company_phone_code',
          'company_type',
        ]),
      );
      expect(split.account, {'name': 'Apex'});
    });

    test('company edit profile: experience_years belongs to companies', () {
      final split = ProfileFields.split({
        'company_name': 'Apex',
        'name': 'Apex',
        'company_type': 'Agency',
        'address': 'HQ',
        'experience_years': 12,
      }, 'COMPANY');

      expect(split.profileTable, 'companies');
      expect(split.profile['experience_years'], 12);
      expect(split.account.keys, unorderedEquals(['name', 'address']));
      expect(split.ignored, isEmpty);
    });

    test('company sending guard-only columns: ignored, not written', () {
      final split = ProfileFields.split({
        'hourly_rate': 10,
        'name': 'Apex',
      }, 'COMPANY');

      expect(split.profileTable, isNull);
      expect(split.profile, isEmpty);
      expect(split.ignored, ['hourly_rate']);
      expect(split.account, {'name': 'Apex'});
    });

    test('status / metadata only: users only, no profile table', () {
      final split = ProfileFields.split({
        'status': 'PENDING_APPROVAL',
        'metadata': {'payment_status': 'PAID'},
      }, null);

      expect(split.profileTable, isNull);
      expect(split.account.keys, unorderedEquals(['status', 'metadata']));
      expect(ProfileFields.hasRoleColumns({'status': 'X'}), isFalse);
      expect(ProfileFields.hasRoleColumns({'bio': 'X'}), isTrue);
    });

    test('customer with role columns: nothing outside users is written', () {
      final split = ProfileFields.split({
        'name': 'Sara',
        'bio': 'x',
      }, 'CUSTOMER');

      expect(split.profileTable, isNull);
      expect(split.ignored, ['bio']);
      expect(split.account, {'name': 'Sara'});
    });

    test('null values are kept (clearing a column)', () {
      final split = ProfileFields.split({'bio': null}, 'GUARD');
      expect(split.profile.containsKey('bio'), isTrue);
      expect(split.profileTable, 'bodyguards');
    });
  });
}
