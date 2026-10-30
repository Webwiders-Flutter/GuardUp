import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:guardup/core/services/file_upload_service.dart';
import 'package:guardup/core/utils/app_logs.dart';
import 'package:guardup/features/auth/domain/entities/user_entity.dart';
import 'package:guardup/features/profile/domain/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/error_keys.dart';
import '../../../../core/error/failures.dart';
import '../models/user_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _supabaseClient;
  final FileUploadService _fileUploadService;

  ProfileRepositoryImpl(this._supabaseClient, this._fileUploadService);

  SupabaseQueryBuilder get _usersTable =>
      _supabaseClient.from(SupabaseTables.users);

  @override
  Future<UserEntity> getProfile(String userId) async {
    try {
      final response = await _usersTable
          .select('*, user_social_profiles(*)')
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e, stackTrace) {
      AppLogs.error('Failed to get profile', error: e, stackTrace: stackTrace);
      throw Exception('Failed to get profile: $e');
    }
  }

  @override
  Future<void> updateProfile(UserEntity user) async {
    try {
      final userModel = UserModel(
        id: user.id,
        email: user.email,
        name: user.name,
        profileImage: user.profileImage,
        phone: user.phone,
        phoneCode: user.phoneCode,
        countryCode: user.countryCode,
        bio: user.bio,
        isVerified: user.isVerified,
        degree: user.degree,
        preferredCountry: user.preferredCountry,
        preferredField: user.preferredField,
        preferredSpecialisation: user.preferredSpecialisation,
        targetIntake: user.targetIntake,
        studyGoals: user.studyGoals,
        otherPreferredCountries: user.otherPreferredCountries,
      );

      final updateData = userModel.toJson();
      updateData.remove('id'); // Do not update the primary key
      updateData.remove('email'); // Do not update email via this endpoint
      updateData.remove('interests'); // belongs to user_social_profiles
      updateData.remove(
        'preferred_destinations',
      ); // belongs to user_social_profiles
      updateData.remove('degree');
      updateData.remove('preferred_country');
      updateData.remove('preferred_field');
      updateData.remove('preferred_specialisation');
      updateData.remove('target_intake');
      updateData.remove('study_goals');
      updateData.remove('other_preferred_countries');
      // Bilingual & ID fields – belong to user_social_profiles, not users
      updateData.remove('degree_en');
      updateData.remove('degree_ar');
      updateData.remove('preferred_country_en');
      updateData.remove('preferred_country_ar');
      updateData.remove('preferred_field_en');
      updateData.remove('preferred_field_ar');
      updateData.remove('preferred_specialisation_en');
      updateData.remove('preferred_specialisation_ar');
      updateData.remove('target_intake_en');
      updateData.remove('target_intake_ar');
      updateData.remove('other_preferred_countries_en');
      updateData.remove('other_preferred_countries_ar');
      updateData.remove('degree_id');
      updateData.remove('preferred_country_id');
      updateData.remove('other_preferred_country_ids');

      // Clean up nulls
      updateData.removeWhere((key, value) => value == null);

      final futures = <Future>[];

      if (updateData.isNotEmpty) {
        futures.add(_usersTable.update(updateData).eq('id', user.id));
      }

      // Upsert study profile & social preferences to user_social_profiles
      final socialData = <String, dynamic>{
        'id': user.id,
        // text fields (display / fallback)
        if (user.degree != null) 'degree': user.degree,
        if (user.preferredCountry != null)
          'preferred_country': user.preferredCountry,
        if (user.preferredField != null) 'preferred_field': user.preferredField,
        if (user.preferredSpecialisation != null)
          'preferred_specialisation': user.preferredSpecialisation,
        if (user.targetIntake != null) 'target_intake': user.targetIntake,
        if (user.studyGoals != null) 'study_goals': user.studyGoals,
        'other_preferred_countries': user.otherPreferredCountries,
        // bilingual fields
        if (user.degreeEn != null) 'degree_en': user.degreeEn,
        if (user.degreeAr != null) 'degree_ar': user.degreeAr,
        if (user.preferredCountryEn != null)
          'preferred_country_en': user.preferredCountryEn,
        if (user.preferredCountryAr != null)
          'preferred_country_ar': user.preferredCountryAr,
        if (user.preferredFieldEn != null)
          'preferred_field_en': user.preferredFieldEn,
        if (user.preferredFieldAr != null)
          'preferred_field_ar': user.preferredFieldAr,
        if (user.preferredSpecialisationEn != null)
          'preferred_specialisation_en': user.preferredSpecialisationEn,
        if (user.preferredSpecialisationAr != null)
          'preferred_specialisation_ar': user.preferredSpecialisationAr,
        if (user.targetIntakeEn != null)
          'target_intake_en': user.targetIntakeEn,
        if (user.targetIntakeAr != null)
          'target_intake_ar': user.targetIntakeAr,
        'other_preferred_countries_en': user.otherPreferredCountriesEn,
        'other_preferred_countries_ar': user.otherPreferredCountriesAr,
        // structured ID fields
        'degree_id': user.degreeId,
        'preferred_country_id': user.preferredCountryId,
        'other_preferred_country_ids': user.otherPreferredCountryIds,
      };

      futures.add(
        _supabaseClient.from('user_social_profiles').upsert(socialData),
      );

      // Also update Auth user metadata so it's globally available
      futures.add(
        _supabaseClient.auth.updateUser(
          UserAttributes(
            data: {'name': user.name, 'profileImage': user.profileImage},
          ),
        ),
      );

      await Future.wait(futures);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to update profile',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      return await _fileUploadService.uploadFile(
        file: imageFile,
        bucket: 'profiles',
        folder: userId,
        upsert: true,
      );
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to upload profile image',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to upload profile image: $e');
    }
  }

  @override
  Future<void> updatePreferences({
    required String userId,
    required List<String> interests,
    required List<String> preferredDestinations,
  }) async {
    try {
      await _supabaseClient.from('user_social_profiles').upsert({
        'id': userId,
        'interests': interests,
        'preferred_destinations': preferredDestinations,
      });
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to update preferences',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to update preferences: $e');
    }
  }

  @override
  Future<Either<Failure, void>> blockUser(String userId) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        return const Left(ServerFailure(ErrorKeys.userNotAuthenticated));
      }

      await _supabaseClient.from(SupabaseTables.userBlocks).insert({
        'blocker_id': currentUserId,
        'blocked_id': userId,
      });

      return const Right(null);
    } catch (e, stackTrace) {
      if (e is PostgrestException && e.code == '23505') {
        return const Right(null); // Already blocked
      }
      AppLogs.error('Failed to block user', error: e, stackTrace: stackTrace);
      return const Left(ServerFailure(ErrorKeys.failedToUpdate));
    }
  }

  @override
  Future<Either<Failure, void>> unblockUser(String userId) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        return const Left(ServerFailure(ErrorKeys.userNotAuthenticated));
      }

      await _supabaseClient.from(SupabaseTables.userBlocks).delete().match({
        'blocker_id': currentUserId,
        'blocked_id': userId,
      });

      return const Right(null);
    } catch (e, stackTrace) {
      AppLogs.error('Failed to unblock user', error: e, stackTrace: stackTrace);
      return const Left(ServerFailure(ErrorKeys.failedToUpdate));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getBlockedUserIds() async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        return const Left(ServerFailure(ErrorKeys.userNotAuthenticated));
      }

      final response = await _supabaseClient
          .from(SupabaseTables.userBlocks)
          .select('blocked_id')
          .eq('blocker_id', currentUserId);

      final ids = (response as List)
          .map((row) => row['blocked_id'] as String)
          .toList();
      return Right(ids);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to get blocked user ids',
        error: e,
        stackTrace: stackTrace,
      );
      return const Left(ServerFailure(ErrorKeys.failedToLoadData));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getBlockedUsers({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        return const Left(ServerFailure(ErrorKeys.userNotAuthenticated));
      }

      final offset = (page - 1) * limit;

      final blockResponse = await _supabaseClient
          .from(SupabaseTables.userBlocks)
          .select('blocked_id')
          .eq('blocker_id', currentUserId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final ids = (blockResponse as List)
          .map((row) => row['blocked_id'] as String)
          .toList();
      if (ids.isEmpty) return const Right([]);

      final usersResponse = await _supabaseClient
          .from(SupabaseTables.users)
          .select('*')
          .inFilter('id', ids);

      final users = (usersResponse as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
      return Right(users);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to get blocked users',
        error: e,
        stackTrace: stackTrace,
      );
      return const Left(ServerFailure(ErrorKeys.failedToLoadData));
    }
  }
}
