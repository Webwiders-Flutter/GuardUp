import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/logger/supabase_logger.dart';
import '../../domain/repositories/user_repository.dart';
import '../profile_fields.dart';
import '../model/user.model.dart';

/// Concrete Supabase implementation of [UserRepository] with structured logging.
class SupabaseUserRepository extends UserRepository {
  final supa.SupabaseClient? client;

  SupabaseUserRepository(
    super.fileStorageService, {
    this.client,
  });

  supa.SupabaseClient get _supabase {
    return client ?? supa.Supabase.instance.client;
  }

  @override
  Stream<UserModel?> watchUserProfile(String userId) {
    return watchUserData(userId).map((data) {
      if (data == null) return null;
      return UserModel.fromJson(data);
    });
  }

  /// Streams the merged profile row (same shape as [getUserData]).
  ///
  /// Realtime cannot watch a view, so this listens to the account row in
  /// `users` plus the role's profile row (`bodyguards` for a guard,
  /// `companies` for a company) and re-reads `user_profiles` on every change.
  /// Emits `null` only when the account row itself disappears.
  @override
  Stream<Map<String, dynamic>?> watchUserData(String userId) {
    SupabaseLogger.info(
      'Subscribing to realtime user profile for userId=$userId',
      operation: 'watchUserData',
    );

    final subscriptions = <StreamSubscription<List<Map<String, dynamic>>>>[];
    late final StreamController<Map<String, dynamic>?> controller;
    Map<String, dynamic>? accountRow;
    Map<String, dynamic>? lastMerged;
    var watchingProfileTable = false;
    var generation = 0;
    var isClosed = false;

    void logError(Object error) {
      SupabaseLogger.warning(
        'Realtime subscription error for userId=$userId: $error',
        operation: 'watchUserData',
      );
    }

    Future<void> emitMerged() async {
      final current = ++generation;
      Map<String, dynamic>? merged;
      try {
        merged = await _fetchProfileRow(userId);
      } catch (e) {
        SupabaseLogger.warning(
          'Could not re-read profile for userId=$userId: $e',
          operation: 'watchUserData',
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
                  SupabaseLogger.warning(
                    'Realtime stream received empty rows for userId=$userId (User might be deleted)',
                  );
                  generation++;
                  accountRow = null;
                  lastMerged = null;
                  controller.add(null);
                  return;
                }
                final row = rows.first;
                SupabaseLogger.info(
                  'Realtime user update: status=${row[JsonKeys.status]}, name=${row[JsonKeys.name]}, role=${row[JsonKeys.role]}',
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

  /// Reads the merged account + role profile row from `user_profiles`.
  Future<Map<String, dynamic>?> _fetchProfileRow(String userId) {
    return _supabase
        .from(DatabaseTables.userProfiles)
        .select()
        .eq(JsonKeys.id, userId)
        .maybeSingle();
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    SupabaseLogger.request('getUserProfile', details: 'userId=$userId');
    try {
      final response = await _supabase
          .from(DatabaseTables.users)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        SupabaseLogger.warning('No profile found in users table for userId=$userId');
        return null;
      }
      final model = UserModel.fromJson(response);
      SupabaseLogger.success('getUserProfile', result: 'name=${model.name}, role=${model.role}');
      return model;
    } catch (e, st) {
      SupabaseLogger.error('getUserProfile', e, st);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    SupabaseLogger.request('getUserData', details: 'userId=$userId');
    try {
      final response = await _fetchProfileRow(userId);

      if (response == null) {
        SupabaseLogger.warning('No data found in users table for userId=$userId');
        return null;
      }
      SupabaseLogger.success(
        'getUserData',
        result: 'role=${response['role']}, status=${response['status']}',
      );
      return response;
    } catch (e, st) {
      SupabaseLogger.error('getUserData', e, st);
      return null;
    }
  }

  @override
  Future<void> createUserProfile({required UserModel user}) async {
    SupabaseLogger.request('createUserProfile', payload: user.toJson());
    try {
      final json = user.toJson();
      json['id'] = user.id;
      await _supabase.from(DatabaseTables.users).upsert(json);
      SupabaseLogger.success('createUserProfile', message: 'User profile created for id=${user.id}');
    } catch (e, st) {
      SupabaseLogger.error('createUserProfile', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile({required UserModel user}) async {
    SupabaseLogger.request('updateUserProfile', payload: user.toJson());
    try {
      await _supabase
          .from(DatabaseTables.users)
          .update(user.toJson())
          .eq('id', user.id);
      SupabaseLogger.success('updateUserProfile', message: 'User updated for id=${user.id}');
    } catch (e, st) {
      SupabaseLogger.error('updateUserProfile', e, st);
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
    SupabaseLogger.request('updateProfileFields', payload: {'userId': userId, ...data});
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
        SupabaseLogger.warning(
          'updateProfileFields: ignoring ${split.ignored}, not profile columns for role=$role',
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
      SupabaseLogger.success('updateProfileFields', message: 'Fields updated for userId=$userId');
    } catch (e, st) {
      SupabaseLogger.error('updateProfileFields', e, st);
      rethrow;
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    SupabaseLogger.request('deleteUserProfile', details: 'userId=$userId');
    try {
      await _supabase.from(DatabaseTables.users).delete().eq('id', userId);
      SupabaseLogger.success('deleteUserProfile', message: 'Deleted profile for userId=$userId');
    } catch (e, st) {
      SupabaseLogger.error('deleteUserProfile', e, st);
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
      SupabaseLogger.info('userProfileExists: $exists for userId=$userId');
      return exists;
    } catch (e, st) {
      SupabaseLogger.error('userProfileExists', e, st);
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

    SupabaseLogger.request('checkRegistrationConflict', payload: {
      'email': cleanEmail,
      'phone': cleanPhone,
      'phone_code': cleanPhoneCode,
    });

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
          final message = res['message'] as String? ??
              'This account is already registered. Please sign in or use different details.';
          SupabaseLogger.warning('Conflict detected: $message');
          return message;
        }
      }

      SupabaseLogger.success(
        'checkRegistrationConflict',
        result: 'No active conflicts',
      );
      return null;
    } catch (e) {
      SupabaseLogger.warning('checkRegistrationConflict error: $e');
      return null;
    }
  }

  @override
  Future<({bool exists, String? errorMessage})> checkEmailExists(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    SupabaseLogger.request('checkEmailExists', payload: {'email': cleanEmail});

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
            errorMessage:
                'No account found with this email. Please check your email or sign up.',
          );
        }
        return (exists: true, errorMessage: null);
      }

      return (exists: true, errorMessage: null);
    } catch (e) {
      SupabaseLogger.warning('checkEmailExists error: $e');
      return (exists: true, errorMessage: null);
    }
  }
}
