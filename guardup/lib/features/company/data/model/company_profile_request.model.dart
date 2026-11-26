import '/core/constants/api/json_keys.dart';
import '../enum/business_type.enum.dart';

/// Payload for a `companies` row, keyed by `user_id`.
///
/// Strings are trimmed; empty optional strings are written as `null`.
class CompanyProfileRequest {
  const CompanyProfileRequest({
    required this.companyName,
    required this.businessEmail,
    this.companyType,
    this.companyPhoneCode = '+91',
    required this.companyPhoneNumber,
    this.experienceYears,
  });

  final String companyName;
  final String businessEmail;
  final BusinessType? companyType;
  final String companyPhoneCode;
  final String companyPhoneNumber;
  final int? experienceYears;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JsonKeys.companyName: companyName.trim(),
      JsonKeys.businessEmail: businessEmail.trim(),
      if (companyType != null) JsonKeys.companyType: companyType!.apiValue,
      JsonKeys.companyPhoneCode: companyPhoneCode.trim(),
      JsonKeys.companyPhoneNumber: companyPhoneNumber.trim(),
      JsonKeys.experienceYears: ?experienceYears,
    };
  }
}
