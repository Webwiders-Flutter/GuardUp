import '/core/extensions/string.extension.dart';
import '/features/company/data/model/company.model.dart';

/// Display helpers for [CompanyModel] (kept off the model, per the
/// no-model-getters rule).
extension CompanyModelX on CompanyModel {
  String get displayName => companyName?.trim().isNotEmpty == true
      ? companyName!
      : 'Security Company';

  String get experienceYearsFormatted =>
      (experienceYears != null && experienceYears! > 0)
          ? '$experienceYears+ Yrs Exp'
          : '0 Yrs Exp';

  String? get initials => companyName?.getInitials() ?? ''.getInitials();

  DateTime? get joinedAt => createdAt;

  // ---------------------------------------------------------------------------
  // Phantom values: no database column exists yet. Cards still show them, so
  // they keep today's values until the data exists.
  // ---------------------------------------------------------------------------

  // TODO(migration): logo is synced to the company account's
  // profile_image_url (user?.profileImageUrl); today cards show initials.
  String? get logoUrl => null;

  // TODO(migration): count of the company's ACTIVE bodyguards; hard-coded today.
  int get activeGuards => 12;

  // TODO(migration): no reviews table.
  double get rating => 0.0;

  // TODO(migration): no reviews table.
  int get reviewCount => 0;

  // TODO(migration): no bookings table.
  String get bookingsCount => '0 Bookings';

  // TODO(migration): customers only see ACTIVE companies; derive from
  // user?.status once every select embeds it.
  bool get isVerified => true;

  // TODO(migration): no presence data.
  bool get isOnline => true;
}
