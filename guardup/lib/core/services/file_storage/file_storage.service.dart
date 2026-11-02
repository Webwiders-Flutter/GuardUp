import 'dart:typed_data';

import '/core/services/file_storage/models/file_upload_response.model.dart';

import 'models/file_upload_request.model.dart';

/// Abstract contract for file storage services (e.g., Supabase, S3, Firebase).
abstract interface class FileStorageService {
  // ---------------------------------------------------------------------------
  // UPLOADS
  // ---------------------------------------------------------------------------

  /// Uploads a single file using [FileUploadRequest] and returns the public URL.
  Future<String> uploadSingleFile(FileUploadRequest req);

  /// Uploads multiple files in parallel and returns their public URLs.
  Future<List<String>> uploadMultipleFiles(List<FileUploadRequest> requests);

  // ---------------------------------------------------------------------------
  // UPDATE / REPLACE (UPSERT vs INSERT & DELETE)
  // ---------------------------------------------------------------------------

  /// Overwrites or creates a file at the exact specified path using in-place upsert (`upsert: true`).
  ///
  /// Note: Updating in-place preserves the URL path, but may require cache busting
  /// if CDN or browser caches cache the image.
  Future<String> upsertFile(FileUploadRequest req);

  /// Alias for [upsertFile].
  Future<String> upsert(FileUploadRequest req);

  /// Uploads a new file and deletes the previous file (if [oldUrl] or [oldPath] is supplied).
  ///
  /// This strategy generates a brand-new URL (e.g. timestamped) to guarantee clean cache invalidation,
  /// and automatically cleans up the stale asset from storage.
  Future<String> insertAndDeleteFile({
    required FileUploadRequest newRequest,
    String? oldUrl,
    String? oldPath,
    String? oldBucket,
  });

  /// Alias for [insertAndDeleteFile].
  Future<String> insertAndDelete({
    required FileUploadRequest newRequest,
    String? oldUrl,
    String? oldPath,
    String? oldBucket,
  });

  // ---------------------------------------------------------------------------
  // DELETIONS
  // ---------------------------------------------------------------------------

  /// Deletes a single file from [bucket] at [path].
  Future<void> deleteSingleFile({required String bucket, required String path});

  /// Alias for [deleteSingleFile].
  Future<void> deleteFile({required String bucket, required String path});

  /// Deletes multiple files from the specified [bucket].
  Future<void> deleteMultipleFiles({
    required String bucket,
    required List<String> paths,
  });

  /// Alias for [deleteMultipleFiles].
  Future<void> deleteFiles({
    required String bucket,
    required List<String> paths,
  });

  /// Deletes a single file given its full storage URL.
  Future<void> deleteFileFromUrl(String url);

  /// Deletes multiple files given their full storage URLs.
  Future<void> deleteFilesFromUrls(List<String> urls);

  // ---------------------------------------------------------------------------
  // URLS
  // ---------------------------------------------------------------------------

  /// Returns the public URL for a file in [bucket] at [path].
  String getPublicUrl({required String bucket, required String path});

  /// Alias for [getPublicUrl].
  String getUrl({required String bucket, required String path});

  /// Creates a temporary signed URL for private bucket objects.
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 3600,
  });

  // ---------------------------------------------------------------------------
  // METADATA & INSPECTION
  // ---------------------------------------------------------------------------

  /// Checks if a file exists in [bucket] at [path].
  Future<bool> isFileExists({required String bucket, required String path});

  /// Retrieves metadata for a file in [bucket] at [path].
  Future<StorageItem?> getMetadata({
    required String bucket,
    required String path,
  });

  /// Retrieves the file size in bytes for a file in [bucket] at [path].
  Future<int?> getFileSize({required String bucket, required String path});

  /// Lists all files and folders under [folderPath] in [bucket].
  Future<List<StorageItem>> listFiles({
    required String bucket,
    String? folderPath,
    int limit = 100,
    int offset = 0,
    String? search,
  });

  // ---------------------------------------------------------------------------
  // DOWNLOAD / MOVE / COPY
  // ---------------------------------------------------------------------------

  /// Downloads file content as raw bytes ([Uint8List]).
  Future<Uint8List> downloadFile({
    required String bucket,
    required String path,
  });

  /// Moves or renames an existing file within a bucket or to another bucket.
  Future<String> moveFile({
    required String fromBucket,
    required String fromPath,
    required String toPath,
    String? toBucket,
  });

  /// Copies an existing file within a bucket or to another bucket.
  Future<String> copyFile({
    required String fromBucket,
    required String fromPath,
    required String toPath,
    String? toBucket,
  });
}
