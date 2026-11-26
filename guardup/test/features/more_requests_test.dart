import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/constants/api/json_keys.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:guardup/features/body_guard/body_guard.dart';
import 'package:guardup/features/company/company.dart';
import 'package:guardup/features/legal/legal.dart';
import 'package:guardup/features/payments/payments.dart';
import 'package:guardup/shared/models/record_owner.model.dart';

void main() {
  group('UserAccountRequest', () {
    test(
      'toJson trims strings, maps gender, omits nulls, nulls empty optionals',
      () {
        const req = UserAccountRequest(
          name: '  John Doe  ',
          email: '  john@example.com ',
          phoneCode: ' +91 ',
          phoneNumber: ' 9876543210 ',
          profileImageUrl: ' https://example.com/avatar.jpg ',
          gender: GenderType.male,
          isPushNotificationEnabled: true,
        );

        expect(req.toJson(), {
          JsonKeys.name: 'John Doe',
          JsonKeys.email: 'john@example.com',
          JsonKeys.phoneCode: '+91',
          JsonKeys.phoneNumber: '9876543210',
          JsonKeys.profileImageUrl: 'https://example.com/avatar.jpg',
          JsonKeys.gender: 'MALE',
          JsonKeys.isPushNotificationEnabled: true,
        });
      },
    );

    test('toJson handles empty strings as null', () {
      const req = UserAccountRequest(name: '   ', profileImageUrl: '   ');

      final json = req.toJson();
      expect(json.containsKey(JsonKeys.name), isTrue);
      expect(json[JsonKeys.name], isNull);
      expect(json.containsKey(JsonKeys.profileImageUrl), isTrue);
      expect(json[JsonKeys.profileImageUrl], isNull);
    });
  });

  group('CompanyProfileRequest', () {
    test(
      'toJson trims strings and serializes companyType and experienceYears',
      () {
        const req = CompanyProfileRequest(
          companyName: '  Apex Security Corp  ',
          businessEmail: ' contact@apex.com ',
          companyType: BusinessType.pvtLtd,
          companyPhoneCode: ' +91 ',
          companyPhoneNumber: ' 9876543210 ',
          experienceYears: 5,
        );

        expect(req.toJson(), {
          JsonKeys.companyName: 'Apex Security Corp',
          JsonKeys.businessEmail: 'contact@apex.com',
          JsonKeys.companyType: 'PVT_LTD',
          JsonKeys.companyPhoneCode: '+91',
          JsonKeys.companyPhoneNumber: '9876543210',
          JsonKeys.experienceYears: 5,
        });
      },
    );
  });

  group('BankAccountRequest', () {
    test('toJson trims strings, upper-cases ifscCode, and sets isPrimary', () {
      const req = BankAccountRequest(
        accountNumber: ' 1234567890 ',
        accountHolder: ' John Doe ',
        bankName: ' HDFC Bank ',
        branch: ' Indore Main ',
        ifscCode: ' hdfc0001234 ',
        branchAddress: ' MG Road ',
        isPrimary: true,
      );

      expect(req.toJson(userId: 'u-1'), {
        JsonKeys.userId: 'u-1',
        JsonKeys.accountNumber: '1234567890',
        JsonKeys.accountHolder: 'John Doe',
        JsonKeys.bankName: 'HDFC Bank',
        JsonKeys.branch: 'Indore Main',
        JsonKeys.ifscCode: 'HDFC0001234',
        JsonKeys.branchAddress: 'MG Road',
        JsonKeys.isPrimary: true,
      });
    });
  });

  group('AvailabilityRequest', () {
    test('toJson formats weekday apiValue and includes owner column', () {
      const req = AvailabilityRequest(
        dayOfWeek: WeekDay.monday,
        isAvailable: true,
        fromTime: ' 09:00 AM ',
        toTime: ' 05:00 PM ',
      );

      const owner = AccountOwner('u-123');
      expect(req.toJson(owner: owner), {
        JsonKeys.userId: 'u-123',
        JsonKeys.dayOfWeek: 'monday',
        JsonKeys.isAvailable: true,
        JsonKeys.fromTime: '09:00 AM',
        JsonKeys.toTime: '05:00 PM',
      });

      const managedOwner = ManagedBodyguardOwner('bg-456');
      expect(req.toJson(owner: managedOwner), {
        JsonKeys.bodyguardId: 'bg-456',
        JsonKeys.dayOfWeek: 'monday',
        JsonKeys.isAvailable: true,
        JsonKeys.fromTime: '09:00 AM',
        JsonKeys.toTime: '05:00 PM',
      });
    });
  });

  group('ContactUsRequest', () {
    test('toJson trims strings and formats role and status', () {
      const req = ContactUsRequest(
        userId: 'u-1',
        role: UserRole.guard,
        fullName: '  Jane Guard  ',
        email: ' jane@guard.com ',
        message: ' Need help with schedule ',
        status: ContactUsStatus.pending,
      );

      expect(req.toJson(), {
        JsonKeys.userId: 'u-1',
        JsonKeys.role: 'GUARD',
        JsonKeys.fullName: 'Jane Guard',
        JsonKeys.email: 'jane@guard.com',
        JsonKeys.message: 'Need help with schedule',
        JsonKeys.status: 'PENDING',
      });
    });
  });
}
