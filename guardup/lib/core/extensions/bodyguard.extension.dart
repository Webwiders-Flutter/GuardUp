import '/core/extensions/availability.extension.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '/features/body_guard/data/enum/bodyguard_availability_status.enum.dart';
import '/features/body_guard/data/enum/guard_service.enum.dart';
import '/features/body_guard/data/model/body_guard.model.dart';
import '/features/body_guard/data/model/user_document.model.dart';

/// Display helpers for [BodyGuardModel] (kept off the model, per the
/// no-model-getters rule).
extension BodyGuardModelX on BodyGuardModel {
  String get displayName => name.isNotEmpty ? name : 'Bodyguard';

  String get displayAvatar => profileImageUrl ?? '';

  String get location =>
      (address?.isNotEmpty == true) ? address! : 'Location not set';

  /// Today's availability, evaluated from [BodyGuardModel.availabilities].
  BodyguardAvailabilityStatus get availabilityStatus =>
      availabilities.evaluateAvailabilityStatus();

  bool get isVerified => status == UserStatus.active;

  // ---------------------------------------------------------------------------
  // Legacy aliases kept so screens stay unchanged during the migration.
  // ---------------------------------------------------------------------------

  /// Alias of [BodyGuardModel.status].
  // TODO(migration): switch call sites to `status` and delete.
  UserStatus get verificationStatus => status;

  /// Alias of [BodyGuardModel.documents].
  // TODO(migration): switch call sites to `documents` and delete.
  List<UserDocumentModel>? get userDocuments => documents;

  // ---------------------------------------------------------------------------
  // Phantom values: no database column exists yet. Screens still show them,
  // so they stay until reviews / bookings have tables.
  // ---------------------------------------------------------------------------

  // TODO(migration): no reviews table; remove when ratings are real.
  int get reviewCount => 0;

  // TODO(migration): no bookings table; remove when missions are real.
  int get totalCompletedMissions => 0;

  // TODO(migration): no currency column; confirm the display currency.
  String get currency => 'USD';

  // TODO(migration): services are [BodyGuardModel.services]; GuardService is
  // a local enum and is never populated from the database.
  List<GuardService> get serviceTypes => const [];
}
