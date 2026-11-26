import 'dart:async';

import '/core/constants/api/database_functions.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/core/logger/app_logger.dart';
import '/core/repositories/base.repository.dart';
import '/core/services/file_storage/file_storage.service.dart';
import '../enum/user_status.enum.dart';
import '../model/user.model.dart';
import '../model/user_account_request.model.dart';

/// Typed Supabase repository for `public.users` and its embedded role/child
/// relations (`bodyguard`, `company`, `availabilities`, `user_services`, `documents`).
class UserRepository extends BaseSupabaseRepository<UserModel> {
  final FileStorageService fileStorageService;

  UserRepository(this.fileStorageService, {required super.client})
    : super(
        tableName: DatabaseTables.users,
        fromJson: UserModel.fromJson,
        entityName: 'user',
        searchFields: const [JsonKeys.name, JsonKeys.email],
        selectColumns: _profileSelect,
        primarySortColumn: JsonKeys.createdAt,
        primarySortAscending: false,
      );

  static const String _tag = 'UserRepository';

  static const String _profileSelect = '''
    *,
    bodyguard:bodyguards!bodyguards_user_id_fkey(*),
    company:companies!companies_user_id_fkey(*, ${JsonKeys.activeGuards}),
    availabilities:user_availabilities!user_availabilities_user_id_fkey(*),
    user_services!user_services_user_id_fkey(
      id,
      service:services(id, name, description, icon_name, icon_url, is_active, display_order)
    ),
    documents:user_documents!user_documents_user_id_fkey(
      *,
      document_type:document_types(*)
    )
  ''';

  /// Retrieves full typed profile for [id] with embedded relations.
  Future<UserModel?> getProfile(String id) async {
    AppLogger.d('getProfile: id=$id', tag: _tag);
    final row = await client
        .from(DatabaseTables.users)
        .select(_profileSelect)
        .eq(JsonKeys.id, id)
        .maybeSingle();

    if (row == null) {
      AppLogger.w('No profile found in users table for id=$id', tag: _tag);
      return null;
    }
    return UserModel.fromJson(row);
  }

  /// Streams typed [UserModel] with embedded relations in real-time.
  Stream<UserModel?> watchProfile(String userId) {
    AppLogger.d(
      'Subscribing to realtime watchProfile for userId=$userId',
      tag: _tag,
    );

    final subscriptions = <StreamSubscription<List<Map<String, dynamic>>>>[];
    // Returned as the stream; closed in onCancel.
    // ignore: close_sinks
    late final StreamController<UserModel?> controller;
    Map<String, dynamic>? accountRow;
    UserModel? lastMerged;
    var watchingRelated = false;
    var generation = 0;
    var isClosed = false;

    void logError(Object error) {
      AppLogger.w(
        'Realtime subscription error for userId=$userId: $error',
        tag: _tag,
      );
    }

    Future<void> emitMerged() async {
      final current = ++generation;
      UserModel? merged;
      try {
        merged = await getProfile(userId);
      } catch (e) {
        AppLogger.w(
          'Could not re-read profile for userId=$userId: $e',
          tag: _tag,
        );
      }
      if (isClosed || current != generation) return;
      final account = accountRow;
      if (account == null) return;

      UserModel? model = merged;
      if (model == null) {
        final accountModel = UserModel.fromJson(account);
        model = lastMerged != null
            ? lastMerged!.copyWith(
                name: accountModel.name,
                email: accountModel.email,
                phoneCode: accountModel.phoneCode,
                phoneNumber: accountModel.phoneNumber,
                role: accountModel.role,
                status: accountModel.status,
                rejectionReason: accountModel.rejectionReason,
                profileImageUrl: accountModel.profileImageUrl,
                gender: accountModel.gender,
                isPushNotificationEnabled:
                    accountModel.isPushNotificationEnabled,
                metadata: accountModel.metadata,
                updatedAt: accountModel.updatedAt,
              )
            : accountModel;
      }
      lastMerged = model;
      controller.add(model);
    }

    void watchRelatedTables(String? role) {
      if (watchingRelated) return;
      final profileTable = switch (role) {
        'GUARD' => DatabaseTables.bodyguards,
        'COMPANY' => DatabaseTables.companies,
        _ => null,
      };

      watchingRelated = true;

      if (profileTable != null) {
        subscriptions.add(
          client
              .from(profileTable)
              .stream(primaryKey: [JsonKeys.id])
              .eq(JsonKeys.userId, userId)
              .listen((_) => emitMerged(), onError: logError),
        );
      }

      subscriptions.add(
        client
            .from(DatabaseTables.userDocuments)
            .stream(primaryKey: [JsonKeys.id])
            .eq(JsonKeys.userId, userId)
            .listen((_) => emitMerged(), onError: logError),
      );
    }

    controller = StreamController<UserModel?>(
      onListen: () {
        subscriptions.add(
          client
              .from(DatabaseTables.users)
              .stream(primaryKey: [JsonKeys.id])
              .eq(JsonKeys.id, userId)
              .listen((rows) {
                if (rows.isEmpty) {
                  AppLogger.w(
                    'Realtime stream received empty rows for userId=$userId (User might be deleted)',
                    tag: _tag,
                  );
                  generation++;
                  accountRow = null;
                  lastMerged = null;
                  controller.add(null);
                  return;
                }
                final row = rows.first;
                accountRow = row;
                watchRelatedTables(row[JsonKeys.role] as String?);
                emitMerged();
              }, onError: logError),
        );
      },
      onCancel: () async {
        isClosed = true;
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }

  /// Updates account-level fields on `public.users`.
  Future<UserModel> updateAccount(String id, UserAccountRequest request) async {
    AppLogger.d('updateAccount: id=$id', tag: _tag);
    final payload = request.toJson();
    if (payload.isNotEmpty) {
      await client
          .from(DatabaseTables.users)
          .update(payload)
          .eq(JsonKeys.id, id);
    }
    final updated = await getProfile(id);
    if (updated == null) {
      throw ApiException('User profile not found after update.');
    }
    return updated;
  }

  /// Moves a user account's status to `PENDING_APPROVAL` for admin review.
  Future<void> submitForReview(String userId) async {
    await client
        .from(DatabaseTables.users)
        .update({
          JsonKeys.status: UserStatus.pendingApproval.apiValue,
          JsonKeys.updatedAt: DateTime.now().toIso8601String(),
        })
        .eq(JsonKeys.id, userId);
  }

  /// Records registration payment details and moves the account to `PENDING_APPROVAL`.
  Future<void> recordRegistrationPayment({
    required String userId,
    required String paymentId,
    required String referenceId,
    required double amount,
    String currency = 'USD',
    DateTime? paidAt,
  }) async {
    final now = paidAt ?? DateTime.now();
    await client
        .from(DatabaseTables.users)
        .update({
          JsonKeys.status: UserStatus.pendingApproval.apiValue,
          JsonKeys.updatedAt: now.toIso8601String(),
          JsonKeys.metadata: {
            'payment_status': 'PAID',
            'payment_id': paymentId,
            'payment_reference': referenceId,
            'payment_amount': amount,
            'payment_currency': currency,
            'payment_date': now.toIso8601String(),
          },
        })
        .eq(JsonKeys.id, userId);
  }

  /// Checks whether an active (non-deleted) account already owns [email] or [phone].
  ///
  /// Swallows RPC errors so a failed pre-check never blocks sign-up (PARITY).
  Future<String?> checkRegistrationConflict({
    required String email,
    String? phone,
    String? phoneCode,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone?.trim();
    final cleanPhoneCode = phoneCode?.trim() ?? '+91';

    AppLogger.d('checkRegistrationConflict: $cleanEmail', tag: _tag);

    try {
      final res = await client.rpc(
        DatabaseFunctions.checkRegistrationConflict,
        params: {
          JsonKeys.pEmail: cleanEmail,
          JsonKeys.pPhoneNumber: cleanPhone,
          JsonKeys.pPhoneCode: cleanPhoneCode,
        },
      );

      if (res is Map) {
        final hasConflict = res['has_conflict'] == true;
        if (hasConflict) {
          final message =
              res['message'] as String? ??
              'This account is already registered. Please sign in or use different details.';
          AppLogger.w('Conflict detected: $message', tag: _tag);
          return message;
        }
      }

      AppLogger.d('checkRegistrationConflict: No active conflicts', tag: _tag);
      return null;
    } catch (e) {
      AppLogger.w('checkRegistrationConflict error: $e', tag: _tag);
      return null;
    }
  }

  /// Checks whether an account with [email] exists for password reset.
  Future<({bool exists, String? errorMessage})> checkEmailExists(
    String email,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    AppLogger.d('checkEmailExists: $cleanEmail', tag: _tag);

    try {
      final conflictRes = await client.rpc(
        DatabaseFunctions.checkRegistrationConflict,
        params: {
          JsonKeys.pEmail: cleanEmail,
          JsonKeys.pPhoneNumber: null,
          JsonKeys.pPhoneCode: null,
        },
      );

      if (conflictRes is Map) {
        final hasConflict = conflictRes['has_conflict'] == true;
        if (!hasConflict) {
          return (
            exists: false,
            errorMessage:
                'No account found with this email. Please check your email or sign up.',
          );
        }
        return (exists: true, errorMessage: null);
      }

      return (exists: true, errorMessage: null);
    } catch (e) {
      AppLogger.w('checkEmailExists error: $e', tag: _tag);
      return (exists: true, errorMessage: null);
    }
  }
}
