import 'package:freezed_annotation/freezed_annotation.dart';

/// Represents the verification and access status of a user across all 3 roles:
/// - Customer
/// - Bodyguard (Guard)
/// - Security Company (Company)
enum UserStatus {
  /// User signed up and verified email, but has not completed required
  /// profile details or document uploads (Guards & Companies).
  @JsonValue('INCOMPLETE')
  incomplete('INCOMPLETE'),

  /// Guard/Company submitted profile, documents, and fee, and is currently
  /// waiting for admin review and verification.
  @JsonValue('PENDING_APPROVAL')
  pendingApproval('PENDING_APPROVAL'),

  /// Active access across all roles (Customers upon OTP verification, Guards & Companies once approved).
  @JsonValue('ACTIVE')
  active('ACTIVE'),

  /// Application was rejected by admin.
  @JsonValue('REJECTED')
  rejected('REJECTED'),

  /// Account has been temporarily or permanently suspended by admin.
  @JsonValue('BLOCKED')
  blocked('BLOCKED'),

  /// Soft-deleted or deactivated account.
  @JsonValue('DELETED')
  deleted('DELETED');

  final String apiValue;

  const UserStatus(this.apiValue);

  static UserStatus fromApiValue(String? value) {
    if (value == null) return UserStatus.active;
    final normalized = value.toUpperCase().trim();
    if (normalized == 'APPROVED') return UserStatus.active;
    return UserStatus.values.firstWhere(
      (e) => e.apiValue == normalized,
      orElse: () => UserStatus.active,
    );
  }

  static UserStatus? tryFromApiValue(String? value) {
    if (value == null) return null;
    final normalized = value.toUpperCase().trim();
    if (normalized == 'APPROVED') return UserStatus.active;
    try {
      return UserStatus.values.firstWhere(
        (e) => e.apiValue == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  String get label {
    switch (this) {
      case UserStatus.incomplete:
        return 'Incomplete Profile';
      case UserStatus.pendingApproval:
        return 'Pending Approval';
      case UserStatus.active:
        return 'Active';
      case UserStatus.rejected:
        return 'Rejected';
      case UserStatus.blocked:
        return 'Blocked';
      case UserStatus.deleted:
        return 'Deleted';
    }
  }
}

