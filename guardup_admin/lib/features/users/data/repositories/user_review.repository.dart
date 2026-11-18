import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/enums/verification_status.enum.dart';

/// Reviews guard / company applications by updating the rows directly, like
/// block / unblock in [UsersRepository].
///
/// The database triggers own the rules: who can be reviewed, mandatory
/// reason, "all documents approved" before profile approval, clearing the
/// reason on approval, and moving the user to REJECTED when a document is
/// rejected. See documentation/user_review_and_rejection.md.
final class UserReviewRepository {
  const UserReviewRepository(this._client);

  final SupabaseClient _client;

  /// Marks one document APPROVED (its rejection reason is cleared).
  Future<void> approveDocument(String documentId) => _updateDocument(
    documentId,
    {JsonKeys.status: VerificationStatus.verified.apiValue},
  );

  /// Marks one document REJECTED with [reason]; the user becomes REJECTED.
  Future<void> rejectDocument(String documentId, String reason) =>
      _updateDocument(documentId, {
        JsonKeys.status: VerificationStatus.rejected.apiValue,
        JsonKeys.rejectionReason: reason,
      });

  /// Approves the profile (status ACTIVE). Fails unless every document is
  /// approved.
  Future<void> approveUser(String userId) => _updateUser(userId, {
    JsonKeys.registrationStatus: UserStatus.active.apiValue,
  });

  /// Rejects the profile (status REJECTED) and stores [reason] on the user.
  Future<void> rejectUser(String userId, String reason) => _updateUser(userId, {
    JsonKeys.registrationStatus: UserStatus.rejected.apiValue,
    JsonKeys.rejectionReason: reason,
  });

  Future<void> _updateDocument(String id, Map<String, dynamic> data) async {
    await _client
        .from(DatabaseTables.userDocuments)
        .update(data)
        .eq(JsonKeys.id, id);
  }

  Future<void> _updateUser(String id, Map<String, dynamic> data) async {
    await _client.from(DatabaseTables.users).update(data).eq(JsonKeys.id, id);
  }
}
