import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:guardup/features/body_guard/body_guard.dart';
import 'package:guardup/features/legal/legal.dart';
import 'package:guardup/features/payments/payments.dart';

void main() {
  group('DocumentTypeModel', () {
    test('parses from database JSON with defaults', () {
      final json = <String, dynamic>{
        'id': 'dt-1',
        'name': 'Government ID',
        'description': 'Valid passport or national ID',
        'target_role': 'GUARD',
        'is_required': true,
        'is_active': true,
        'display_order': 1,
        'created_at': '2026-11-20T10:00:00.000Z',
      };

      final model = DocumentTypeModel.fromJson(json);

      expect(model.id, 'dt-1');
      expect(model.name, 'Government ID');
      expect(model.targetRole, UserRole.guard);
      expect(model.isRequired, isTrue);
      expect(model.isActive, isTrue);
      expect(model.displayOrder, 1);
      expect(model.docKey, 'dt-1');
      expect(model.allowCrop, isFalse);
      expect(model.allowFile, isTrue);
    });

    test('detects logo allowCrop correctly', () {
      const model = DocumentTypeModel(
        id: 'dt-logo',
        name: 'Company Logo',
        targetRole: UserRole.company,
      );

      expect(model.allowCrop, isTrue);
      expect(model.allowFile, isFalse);
    });
  });

  group('UserDocumentModel', () {
    test('parses with embedded document_type', () {
      final json = <String, dynamic>{
        'id': 'ud-1',
        'user_id': 'user-123',
        'document_type_id': 'dt-1',
        'file_url': 'https://example.com/docs/gov_id.pdf',
        'file_name': 'gov_id.pdf',
        'status': 'APPROVED',
        'document_type': {
          'id': 'dt-1',
          'name': 'Government ID',
          'target_role': 'GUARD',
        },
      };

      final model = UserDocumentModel.fromJson(json);

      expect(model.id, 'ud-1');
      expect(model.userId, 'user-123');
      expect(model.documentTypeId, 'dt-1');
      expect(model.status, DocumentStatus.approved);
      expect(model.verificationStatus, DocumentStatus.approved);
      expect(model.resolvedDocumentName, 'Government ID');
    });
  });

  group('UserBankAccountModel', () {
    test('parses from database JSON and supports BankAccount alias', () {
      final json = <String, dynamic>{
        'id': 'ba-1',
        'user_id': 'u-1',
        'account_number': '1234567890',
        'account_holder': 'Aman Staff',
        'bank_name': 'State Bank of India',
        'branch': 'Main Branch',
        'ifsc_code': 'SBIN0001234',
        'branch_address': 'Connaught Place',
        'is_primary': true,
      };

      final model = UserBankAccountModel.fromJson(json);

      expect(model.id, 'ba-1');
      expect(model.userId, 'u-1');
      expect(model.accountNumber, '1234567890');
      expect(model.bankName, 'State Bank of India');
      expect(model.ifscCode, 'SBIN0001234');
      expect(model.isPrimary, isTrue);

      // Verify BankAccount alias
      final BankAccount aliasAccount = model;
      expect(aliasAccount.id, 'ba-1');
    });
  });

  group('MembershipPlanModel', () {
    test('parses JSON, computes savings and payable amounts', () {
      final json = <String, dynamic>{
        'id': 'plan-1',
        'name': 'VIP Gold',
        'description': ['Priority Dispatch', '24/7 Concierge'],
        'price_per_month': '99.99',
        'price_per_year': '999.99',
        'discount': 10.0,
        'discount_type': 'PERCENTAGE',
        'discount_upto': 50.0,
        'is_popular': true,
        'is_active': true,
        'display_order': 2,
      };

      final plan = MembershipPlanModel.fromJson(json);

      expect(plan.id, 'plan-1');
      expect(plan.name, 'VIP Gold');
      expect(plan.title, 'VIP Gold');
      expect(plan.pricePerMonth, 99.99);
      expect(plan.discountType, DiscountType.percentage);
      expect(plan.isPopular, isTrue);
      expect(plan.hasDiscount, isTrue);

      // Calculation tests: 10% of 200 = 20 (less than 50 max) -> payable 180
      expect(plan.calculateSavings(200), 20.0);
      expect(plan.calculatePayable(200), 180.0);

      // 10% of 1000 = 100 (capped at discountUpto 50) -> payable 950
      expect(plan.calculateSavings(1000), 50.0);
      expect(plan.calculatePayable(1000), 950.0);
    });
  });

  group('ContactUsModel', () {
    test('parses from database JSON with enum status', () {
      final json = <String, dynamic>{
        'id': 'cu-1',
        'user_id': 'u-100',
        'role': 'CUSTOMER',
        'full_name': 'Principal User',
        'email': 'principal@vip.com',
        'message': 'Requesting immediate detail',
        'status': 'PENDING',
      };

      final model = ContactUsModel.fromJson(json);

      expect(model.id, 'cu-1');
      expect(model.userId, 'u-100');
      expect(model.role, UserRole.customer);
      expect(model.fullName, 'Principal User');
      expect(model.status, ContactUsStatus.pending);
    });
  });
}
