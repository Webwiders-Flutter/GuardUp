import 'dart:async';

import '/core/services/file_storage/file_storage.service.dart';
import '/core/services/file_storage/models/file_upload_request.model.dart';
import '../../data/model/user.model.dart';
import '../../data/model/user_account_request.model.dart';

/// Abstract contract for managing User Profiles and profile storage.
///
/// Belongs to the Domain layer: defines user profile operations independently
/// of underlying storage implementations (Supabase, Firebase, REST).
abstract class UserRepository {
  final FileStorageService fileStorageService;

  const UserRepository(this.fileStorageService);

  /// Retrieves full typed profile for [id] with embedded relations.
  Future<UserModel?> getProfile(String id);

  /// Streams typed [UserModel] with embedded relations in real-time.
  Stream<UserModel?> watchProfile(String id);

  /// Updates account-level fields for [id].
  Future<UserModel> updateAccount(String id, UserAccountRequest request);

  /// Streams real-time updates for a specific user profile by [userId].
  Stream<UserModel?> watchUserProfile(String userId);

  /// Streams raw realtime data map for a user profile by [userId].
  Stream<Map<String, dynamic>?> watchUserData(String userId);

  /// Retrieves a user profile by [userId]. Returns `null` if not found.
  Future<UserModel?> getUserProfile(String userId);

  /// Retrieves raw data map for a user profile by [userId]. Returns `null` if not found.
  Future<Map<String, dynamic>?> getUserData(String userId);

  /// Creates a new user profile record.
  Future<void> createUserProfile({required UserModel user});

  /// Updates an existing user's profile data.
  Future<void> updateUserProfile({required UserModel user});

  /// Updates specific profile fields without overwriting the entire model.
  Future<void> updateProfileFields({
    required String userId,
    required Map<String, dynamic> data,
  });

  /// Deletes a user profile record by [userId].
  Future<void> deleteUserProfile(String userId);

  /// Checks whether a profile exists for the given [userId].
  Future<bool> userProfileExists(String userId);

  /// Checks whether an email or phone number is already registered by an active (non-deleted) user.
  /// Executes as a single query.
  /// Returns a human-readable conflict error message if taken, or `null` if both are free to use.
  Future<String?> checkRegistrationConflict({
    required String email,
    String? phone,
    String? phoneCode,
  });

  /// Checks whether an account with the given [email] exists in the database.
  /// Returns whether it exists and an optional user-facing error message if it does not.
  Future<({bool exists, String? errorMessage})> checkEmailExists(String email);

  // ---------------------------------------------------------------------------
  // PROFILE IMAGE STORAGE
  // ---------------------------------------------------------------------------

  /// Uploads a user profile image to storage and returns the public URL.
  Future<String> uploadProfileImage({
    required String userId,
    required FileUploadRequest request,
  }) async {
    return await fileStorageService.uploadSingleFile(request);
  }

  /// Alias for [uploadProfileImage].
  Future<String> uploadProfile({
    required String userId,
    required FileUploadRequest request,
  }) => uploadProfileImage(userId: userId, request: request);

  /// Deletes a user profile image from storage by its URL.
  Future<void> deleteProfileImage({
    required String userId,
    required String imageUrl,
  }) async {
    await fileStorageService.deleteFileFromUrl(imageUrl);
  }

  /// Replaces an existing profile image with a new one.
  ///
  /// Uploads [newRequest] and deletes [oldImageUrl] (if supplied) to avoid stale caching.
  Future<String> replaceProfileImage({
    required String userId,
    required FileUploadRequest newRequest,
    String? oldImageUrl,
  }) async {
    return await fileStorageService.insertAndDeleteFile(
      newRequest: newRequest,
      oldUrl: oldImageUrl,
    );
  }
}
