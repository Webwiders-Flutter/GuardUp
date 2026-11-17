import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '/core/constants/api/database_tables.dart';
import '/core/logger/supabase_logger.dart';
import '../../domain/repositories/user_repository.dart';
import '../model/user.model.dart';

/// Concrete Supabase implementation of [UserRepository] with structured logging.
class SupabaseUserRepository extends UserRepository {
  final supa.SupabaseClient? _client;

  SupabaseUserRepository(
    super.fileStorageService, {
    supa.SupabaseClient? client,
  }) : _client = client;

  supa.SupabaseClient get _supabase {
    return _client ?? supa.Supabase.instance.client;
  }

  @override
  Stream<UserModel?> watchUserProfile(String userId) {
    return watchUserData(userId).map((data) {
      if (data == null) return null;
      return UserModel.fromJson(data);
    });
  }

  @override
  Stream<Map<String, dynamic>?> watchUserData(String userId) {
    SupabaseLogger.info(
      'Subscribing to realtime user profile for userId=$userId',
      operation: 'watchUserData',
    );
    return _supabase
        .from(DatabaseTables.users)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .handleError((error) {
          SupabaseLogger.warning(
            'Realtime subscription error for userId=$userId: $error',
            operation: 'watchUserData',
          );
        })
        .map((rows) {
          if (rows.isEmpty) {
            SupabaseLogger.warning(
              'Realtime stream received empty rows for userId=$userId (User might be deleted)',
            );
            return null;
          }
          final row = rows.first;
          SupabaseLogger.info(
            'Realtime user update: status=${row['status']}, name=${row['name']}, role=${row['role']}',
          );
          return row;
        });
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
      final response = await _supabase
          .from(DatabaseTables.users)
          .select()
          .eq('id', userId)
          .maybeSingle();

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

  @override
  Future<void> updateProfileFields({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    SupabaseLogger.request('updateProfileFields', payload: {'userId': userId, ...data});
    try {
      await _supabase
          .from(DatabaseTables.users)
          .update(data)
          .eq('id', userId);
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
