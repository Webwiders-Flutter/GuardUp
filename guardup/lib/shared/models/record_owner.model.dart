import 'package:equatable/equatable.dart';

import '/core/constants/api/json_keys.dart';

/// Who a profile child row (availability, document, service link) belongs to.
///
/// Child tables carry exactly one of `user_id` / `bodyguard_id` (see
/// `documentation/user_profiles.md`). Repositories take a [RecordOwner] so
/// that branching lives in one place.
sealed class RecordOwner extends Equatable {
  const RecordOwner(this.id);

  final String id;

  /// The foreign-key column that identifies this owner on child rows.
  String get column;

  @override
  List<Object?> get props => [runtimeType, id];
}

/// A login account (GUARD or COMPANY user) — rows keyed by `user_id`.
final class AccountOwner extends RecordOwner {
  const AccountOwner(super.id);

  @override
  String get column => JsonKeys.userId;
}

/// A company-managed bodyguard (no login) — rows keyed by `bodyguard_id`.
final class ManagedBodyguardOwner extends RecordOwner {
  const ManagedBodyguardOwner(super.id);

  @override
  String get column => JsonKeys.bodyguardId;
}
