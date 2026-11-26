import '/core/constants/api/json_keys.dart';

/// Payload for adding / updating a row in `public.user_bank_accounts`.
///
/// Strings are trimmed; IFSC is converted to uppercase.
class BankAccountRequest {
  const BankAccountRequest({
    required this.accountNumber,
    required this.accountHolder,
    required this.bankName,
    required this.branch,
    required this.ifscCode,
    this.branchAddress,
    this.isPrimary = false,
  });

  final String accountNumber;
  final String accountHolder;
  final String bankName;
  final String branch;
  final String ifscCode;
  final String? branchAddress;
  final bool isPrimary;

  Map<String, dynamic> toJson({String? userId}) {
    return <String, dynamic>{
      JsonKeys.userId: ?userId,
      JsonKeys.accountNumber: accountNumber.trim(),
      JsonKeys.accountHolder: accountHolder.trim(),
      JsonKeys.bankName: bankName.trim(),
      JsonKeys.branch: branch.trim(),
      JsonKeys.ifscCode: ifscCode.trim().toUpperCase(),
      if (branchAddress != null)
        JsonKeys.branchAddress: _nullIfEmpty(branchAddress),
      JsonKeys.isPrimary: isPrimary,
    };
  }
}

String? _nullIfEmpty(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
