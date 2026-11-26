import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/core/logger/app_logger.dart';
import '/core/repositories/base.repository.dart';
import '/core/services/file_storage/file_storage.service.dart';
import '/core/services/file_storage/models/file_upload_request.model.dart';
import '../../domain/repositories/user_repository.dart';
import '../enum/user_status.enum.dart';
import '../model/user.model.dart';
import '../model/user_account_request.model.dart';
import '../profile_fields.dart';

/// Concrete Supabase implementation of [UserRepository] with structured logging.
class SupabaseUserRepository extends BaseSupabaseRepository<UserModel>
    implements UserRepository {
  @override
  final FileStorageService fileStorageService;

  SupabaseUserRepository(this.fileStorageService, {required super.client})
    : super(
        tableName: DatabaseTables.users,
        fromJson: UserModel.fromJson,
        entityName: 'user',
        searchFields: const [JsonKeys.name, JsonKeys.email],
        selectColumns: _profileSelect,
        primarySortColumn: JsonKeys.createdAt,
        primarySortAscending: false,
      );

  supa.SupabaseClient get _supabase => client;

  static const String _tag = 'UserRepository';

  static const String _profileSelect = '''
    *,
    bodyguard:bodyguards!bodyguards_user_id_fkey(*),
    company:companies!companies_user_id_fkey(*),
    availabilities:user_availabilities!user_availabilities_user_id_fkey(*),
    user_services!user_services_user_id_fkey(
      id,
      service:services(id, name, description, icon_name, is_active, display_order)
    ),
    documents:user_documents!user_documents_user_id_fkey(
      *,
      document_type:document_types(*)
    )
  ''';

  @override
  Future<UserModel?> getProfile(String id) async {
    AppLogger.d('getProfile: id=$id', tag: _tag);
    final row = await _supabase
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

  @override
  Stream<UserModel?> watchProfile(String userId) {
    AppLogger.d(
      'Subscribing to realtime watchProfile for userId=$userId',
      tag: _tag,
    );

    final subscriptions = <StreamSubscription<List<Map<String, dynamic>>>>[];
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

      final model = merged ?? lastMerged;
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
          _supabase
              .from(profileTable)
              .stream(primaryKey: [JsonKeys.id])
              .eq(JsonKeys.userId, userId)
              .listen((_) => emitMerged(), onError: logError),
        );
      }

      subscriptions.add(
        _supabase
            .from(DatabaseTables.userDocuments)
            .stream(primaryKey: [JsonKeys.id])
            .eq(JsonKeys.userId, userId)
            .listen((_) => emitMerged(), onError: logError),
      );
    }

    controller = StreamController<UserModel?>(
      onListen: () {
        subscriptions.add(
          _supabase
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

  @override
  Future<UserModel> updateAccount(String id, UserAccountRequest request) async {
    AppLogger.d('updateAccount: id=$id', tag: _tag);
    final payload = request.toJson();
    if (payload.isNotEmpty) {
      await _supabase
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

  @override
  Future<void> submitForReview(String userId) async {
    await _supabase
        .from(DatabaseTables.users)
        .update({
          JsonKeys.status: UserStatus.pendingApproval.apiValue,
          JsonKeys.updatedAt: DateTime.now().toIso8601String(),
        })
        .eq(JsonKeys.id, userId);
  }

  @override
  Future<void> recordRegistrationPayment({
    required String userId,
    required String paymentId,
    required String referenceId,
    required double amount,
    String currency = 'USD',
    DateTime? paidAt,
  }) async {
    final now = paidAt ?? DateTime.now();
    await _supabase
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

  @override
  Stream<UserModel?> watchUserProfile(String userId) => watchProfile(userId);

  /// Streams the merged profile row (same shape as [getUserData]).
  ///
  /// Realtime cannot watch a view, so this listens to the account row in
  /// `users` plus the role's profile row (`bodyguards` for a guard,
  /// `companies` for a company) and re-reads the merged data on every change.
  /// Emits `null` only when the account row itself disappears.
  @override
  Stream<Map<String, dynamic>?> watchUserData(String userId) {
    AppLogger.d(
      'Subscribing to realtime user profile for userId=$userId',
      tag: _tag,
    );

    final subscriptions = <StreamSubscription<List<Map<String, dynamic>>>>[];
    // Returned as the stream; closed by the subscriber via onCancel.
    // ignore: close_sinks
    late final StreamController<Map<String, dynamic>?> controller;
    Map<String, dynamic>? accountRow;
    Map<String, dynamic>? lastMerged;
    var watchingProfileTable = false;
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
      Map<String, dynamic>? merged;
      try {
        merged = await _fetchProfileRow(userId);
      } catch (e) {
        AppLogger.w(
          'Could not re-read profile for userId=$userId: $e',
          tag: _tag,
        );
      }
      // A newer change (or cancellation) superseded this read.
      if (isClosed || current != generation) return;
      final account = accountRow;
      if (account == null) return;

      // If the re-read failed, keep the last known profile fields and apply
      // the fresh account row on top (status / role must never go stale).
      final row = merged ?? {...?lastMerged, ...account};
      lastMerged = row;
      controller.add(row);
    }

    void watchProfileTable(String? role) {
      if (watchingProfileTable) return;
      final table = switch (role) {
        'GUARD' => DatabaseTables.bodyguards,
        'COMPANY' => DatabaseTables.companies,
        _ => null,
      };
      if (table == null) return;
      watchingProfileTable = true;
      subscriptions.add(
        _supabase
            .from(table)
            .stream(primaryKey: [JsonKeys.id])
            .eq(JsonKeys.userId, userId)
            .listen((_) => emitMerged(), onError: logError),
      );
    }

    controller = StreamController<Map<String, dynamic>?>(
      onListen: () {
        subscriptions.add(
          _supabase
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
                AppLogger.d(
                  'Realtime user update: status=${row[JsonKeys.status]}, name=${row[JsonKeys.name]}, role=${row[JsonKeys.role]}',
                  tag: _tag,
                );
                accountRow = row;
                watchProfileTable(row[JsonKeys.role] as String?);
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

  /// Reads the merged account + role profile row from `users` with embedded
  /// company and bodyguard relations. Replaces the old `user_profiles` view query.
  Future<Map<String, dynamic>?> _fetchProfileRow(String userId) {
    return _supabase
        .from(DatabaseTables.users)
        .select('''
          *,
          bodyguard:bodyguards!bodyguards_user_id_fkey(*),
          company:companies!companies_user_id_fkey(*),
          availabilities:user_availabilities(*)
        ''')
        .eq(JsonKeys.id, userId)
        .maybeSingle();
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    AppLogger.d('getUserProfile: userId=$userId', tag: _tag);
    try {
      final response = await _fetchProfileRow(userId);

      if (response == null) {
        AppLogger.w(
          'No profile found in users table for userId=$userId',
          tag: _tag,
        );
        return null;
      }
      final model = UserModel.fromJson(response);
      AppLogger.d(
        'getUserProfile success: name=${model.name}, role=${model.role}',
        tag: _tag,
      );
      return model;
    } catch (e, st) {
      AppLogger.e('getUserProfile error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    AppLogger.d('getUserData: userId=$userId', tag: _tag);
    try {
      final response = await _fetchProfileRow(userId);

      if (response == null) {
        AppLogger.w(
          'No data found in users table for userId=$userId',
          tag: _tag,
        );
        return null;
      }
      AppLogger.d(
        'getUserData success: role=${response['role']}, status=${response['status']}',
        tag: _tag,
      );
      return response;
    } catch (e, st) {
      AppLogger.e('getUserData error', tag: _tag, error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<void> createUserProfile({required UserModel user}) async {
    AppLogger.d('createUserProfile: id=${user.id}', tag: _tag);
    try {
      final json = user.toJson();
      json['id'] = user.id;
      await _supabase.from(DatabaseTables.users).upsert(json);
      AppLogger.d('createUserProfile success: id=${user.id}', tag: _tag);
    } catch (e, st) {
      AppLogger.e(
        'createUserProfile error',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile({required UserModel user}) async {
    AppLogger.d('updateUserProfile: id=${user.id}', tag: _tag);
    try {
      await _supabase
          .from(DatabaseTables.users)
          .update(user.toJson())
          .eq('id', user.id);
      AppLogger.d('updateUserProfile success: id=${user.id}', tag: _tag);
    } catch (e, st) {
      AppLogger.e(
        'updateUserProfile error',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Writes [data] to the table each column belongs to: account columns to
  /// `users`, role profile columns to `bodyguards` (GUARD) or `companies`
  /// (COMPANY); see [ProfileFields]. Callers keep passing the flat map they
  /// used before the split.
  ///
  /// The profile row is written first, so the `users` update (which can move
  /// the status, e.g. submitting for review) always sees the saved profile.
  @override
  Future<void> updateProfileFields({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    AppLogger.d('updateProfileFields: userId=$userId', tag: _tag);
    try {
      String? role;
      if (ProfileFields.hasRoleColumns(data)) {
        final roleRow = await _supabase
            .from(DatabaseTables.users)
            .select(JsonKeys.role)
            .eq(JsonKeys.id, userId)
            .maybeSingle();
        role = roleRow?[JsonKeys.role] as String?;
      }

      final split = ProfileFields.split(data, role);
      if (split.ignored.isNotEmpty) {
        AppLogger.w(
          'updateProfileFields: ignoring ${split.ignored}, not profile columns for role=$role',
          tag: _tag,
        );
      }

      final profileTable = split.profileTable;
      if (profileTable != null) {
        // Upsert also repairs an account whose profile row is missing.
        await _supabase.from(profileTable).upsert({
          JsonKeys.userId: userId,
          ...split.profile,
        }, onConflict: JsonKeys.userId);
      }

      if (split.account.isNotEmpty) {
        await _supabase
            .from(DatabaseTables.users)
            .update(split.account)
            .eq(JsonKeys.id, userId);
      }
      AppLogger.d('updateProfileFields success: userId=$userId', tag: _tag);
    } catch (e, st) {
      AppLogger.e(
        'updateProfileFields error',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    AppLogger.d('deleteUserProfile: userId=$userId', tag: _tag);
    try {
      await _supabase.from(DatabaseTables.users).delete().eq('id', userId);
      AppLogger.d('deleteUserProfile success: userId=$userId', tag: _tag);
    } catch (e, st) {
      AppLogger.e(
        'deleteUserProfile error',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<bool> userProfileExists(String userId) async {
    try {
      final response = await _supabase
          .from(DatabaseTables.users)
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      final exists = response != null;
      AppLogger.d('userProfileExists: $exists for userId=$userId', tag: _tag);
      return exists;
    } catch (e, st) {
      AppLogger.e(
        'userProfileExists error',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  @override
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
      // Call Security Definer RPC so anonymous sign-up flow can check conflicts
      // without being blocked by RLS on public.users
      final res = await _supabase.rpc(
        'check_registration_conflict',
        params: {
          'p_email': cleanEmail,
          'p_phone_number': cleanPhone,
          'p_phone_code': cleanPhoneCode,
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

  @override
  Future<({bool exists, String? errorMessage})> checkEmailExists(
    String email,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    AppLogger.d('checkEmailExists: $cleanEmail', tag: _tag);

    try {
      // Reuses the existing security definer check_registration_conflict RPC
      final conflictRes = await _supabase.rpc(
        'check_registration_conflict',
        params: {
          'p_email': cleanEmail,
          'p_phone_number': null,
          'p_phone_code': null,
        },
      );

      if (conflictRes is Map) {
        final hasConflict = conflictRes['has_conflict'] == true;
        if (!hasConflict) {
          return (
            exists: false,
            errorMessage: 'No account found with this email. Please check your email or sign up.',
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

  @override
  Future<String> uploadProfileImage({
    required String userId,
    required FileUploadRequest request,
  }) => fileStorageService.uploadSingleFile(request);

  @override
  Future<String> uploadProfile({
    required String userId,
    required FileUploadRequest request,
  }) => uploadProfileImage(userId: userId, request: request);

  @override
  Future<void> deleteProfileImage({
    required String userId,
    required String imageUrl,
  }) => fileStorageService.deleteFileFromUrl(imageUrl);

  @override
  Future<String> replaceProfileImage({
    required String userId,
    required FileUploadRequest newRequest,
    String? oldImageUrl,
  }) => fileStorageService.insertAndDeleteFile(
    newRequest: newRequest,
    oldUrl: oldImageUrl,
  );
}
