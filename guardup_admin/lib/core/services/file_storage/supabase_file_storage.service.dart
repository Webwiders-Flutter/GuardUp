import 'dart:io';

import '/core/error/api_exception.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../extensions/file_object.extension.dart';
import '../../providers/supabase/supabase.provider.dart';
import 'file_storage.dart';
import 'file_upload_request.model.dart';

/// Provider for [SupabaseFileStorageService].
final supabaseFileStorageServiceProvider = Provider<SupabaseFileStorageService>(
  (ref) {
    final storage = ref.watch(supabaseStorageProvider);
    return SupabaseFileStorageService(storage: storage);
  },
);

/// Supabase implementation of the [FileStorageService] contract.
///
/// Provides single/batch uploads, updates, deletions, URL generation,
/// metadata queries, and file movement/copying on Supabase Storage.
final class SupabaseFileStorageService implements FileStorageService {
  SupabaseFileStorageService({required this.storage});

  final SupabaseStorageClient storage;

  // ---------------------------------------------------------------------------
  // URL Parser Helper
  // ---------------------------------------------------------------------------

  /// Extracts the bucket and relative path from a full Supabase storage URL.
  ///
  /// Supports:
  /// - `https://<proj>.supabase.co/storage/v1/object/public/<bucket>/<path>`
  /// - `https://<proj>.supabase.co/storage/v1/object/sign/<bucket>/<path>?token=...`
  /// - `https://<proj>.supabase.co/storage/v1/object/authenticated/<bucket>/<path>`
  ({String bucket, String path})? parseUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.pathSegments.isEmpty) {
      return null;
    }

    final segments = uri.pathSegments;
    final objectIndex = segments.indexOf('object');
    if (objectIndex != -1 && segments.length > objectIndex + 2) {
      final typeOrBucket = segments[objectIndex + 1];
      if (['public', 'sign', 'authenticated'].contains(typeOrBucket) &&
          segments.length > objectIndex + 2) {
        final bucket = segments[objectIndex + 2];
        final path = segments.sublist(objectIndex + 3).join('/');
        return (bucket: bucket, path: path);
      } else {
        final bucket = typeOrBucket;
        final path = segments.sublist(objectIndex + 2).join('/');
        return (bucket: bucket, path: path);
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // UPLOADS - Single File
  // ---------------------------------------------------------------------------

  @override
  Future<String> uploadSingleFile(FileUploadRequest req) async {
    final cleanPath = req.path.startsWith('/')
        ? req.path.substring(1)
        : req.path;

    // Resolve an accurate MIME type so Supabase bucket policies don't reject
    // default 'application/octet-stream' uploads.
    final effectiveContentType =
        (req.contentType != null &&
            req.contentType!.trim().isNotEmpty &&
            req.contentType != 'application/octet-stream')
        ? req.contentType
        : (req.xFile?.resolvedMimeType ?? cleanPath.resolvedMimeType);

    // 1. Raw bytes upload (Web / memory assets)
    if (req.bytes != null) {
      await storage
          .from(req.bucket)
          .uploadBinary(
            cleanPath,
            req.bytes!,
            fileOptions: FileOptions(
              upsert: req.upsert,
              contentType: effectiveContentType,
            ),
          );
      return getPublicUrl(bucket: req.bucket, path: cleanPath);
    }

    // 2. XFile upload (Cross-platform)
    if (req.xFile != null) {
      final bytes = await req.xFile!.readAsBytes();
      await storage
          .from(req.bucket)
          .uploadBinary(
            cleanPath,
            bytes,
            fileOptions: FileOptions(
              upsert: req.upsert,
              contentType: effectiveContentType,
            ),
          );
      return getPublicUrl(bucket: req.bucket, path: cleanPath);
    }

    // 3. Local file path upload (Native only)
    if (req.localPath != null) {
      if (kIsWeb) {
        throw UnsupportedError(
          'Direct localPath uploads are not supported on Flutter Web. '
          'Use FileUploadRequest.fromBytes or FileUploadRequest.fromXFile instead.',
        );
      }

      final file = File(req.localPath!);
      await storage
          .from(req.bucket)
          .upload(
            cleanPath,
            file,
            fileOptions: FileOptions(
              upsert: req.upsert,
              contentType: effectiveContentType,
            ),
          );
      return getPublicUrl(bucket: req.bucket, path: cleanPath);
    }

    throw ArgumentError(
      'FileUploadRequest must contain one of: bytes, xFile, or localPath.',
    );
  }

  // ---------------------------------------------------------------------------
  // UPLOADS - Multiple Files
  // ---------------------------------------------------------------------------

  @override
  Future<List<String>> uploadMultipleFiles(
    List<FileUploadRequest> requests,
  ) async {
    return Future.wait(requests.map(uploadSingleFile));
  }

  // ---------------------------------------------------------------------------
  // UPDATE / REPLACE (UPSERT vs INSERT & DELETE)
  // ---------------------------------------------------------------------------

  @override
  Future<String> upsertFile(FileUploadRequest req) async {
    return uploadSingleFile(req.copyWith(upsert: true));
  }

  @override
  Future<String> upsert(FileUploadRequest req) => upsertFile(req);

  @override
  Future<String> insertAndDeleteFile({
    required FileUploadRequest newRequest,
    String? oldUrl,
    String? oldPath,
    String? oldBucket,
  }) async {
    // 1. Upload new file first
    final newUrl = await uploadSingleFile(newRequest);

    // 2. Safely delete the old file if provided and distinct
    try {
      if (oldUrl != null && oldUrl.trim().isNotEmpty) {
        final parsedOld = parseUrl(oldUrl);
        final parsedNew = parseUrl(newUrl);
        final isSameFile =
            parsedOld != null &&
            parsedNew != null &&
            parsedOld.bucket == parsedNew.bucket &&
            parsedOld.path == parsedNew.path;

        if (!isSameFile) {
          await deleteFileFromUrl(oldUrl);
        }
      } else if (oldPath != null && oldPath.trim().isNotEmpty) {
        final bucket = oldBucket ?? newRequest.bucket;
        final cleanNewPath = newRequest.path.startsWith('/')
            ? newRequest.path.substring(1)
            : newRequest.path;
        final cleanOldPath = oldPath.startsWith('/')
            ? oldPath.substring(1)
            : oldPath;

        if (bucket != newRequest.bucket || cleanOldPath != cleanNewPath) {
          await deleteSingleFile(bucket: bucket, path: cleanOldPath);
        }
      }
    } catch (e, st) {
      throw ApiException(
        'Failed to delete previous file during insertAndDelete: $e',
        raw: e,
        stackTrace: st,
      );
    }

    return newUrl;
  }

  @override
  Future<String> insertAndDelete({
    required FileUploadRequest newRequest,
    String? oldUrl,
    String? oldPath,
    String? oldBucket,
  }) => insertAndDeleteFile(
    newRequest: newRequest,
    oldUrl: oldUrl,
    oldPath: oldPath,
    oldBucket: oldBucket,
  );

  // ---------------------------------------------------------------------------
  // DELETIONS
  // ---------------------------------------------------------------------------

  @override
  Future<void> deleteSingleFile({
    required String bucket,
    required String path,
  }) async {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    await storage.from(bucket).remove([cleanPath]);
  }

  @override
  Future<void> deleteFile({required String bucket, required String path}) =>
      deleteSingleFile(bucket: bucket, path: path);

  @override
  Future<void> deleteMultipleFiles({
    required String bucket,
    required List<String> paths,
  }) async {
    if (paths.isEmpty) return;
    final cleanPaths = paths
        .map((p) => p.startsWith('/') ? p.substring(1) : p)
        .toList();
    await storage.from(bucket).remove(cleanPaths);
  }

  @override
  Future<void> deleteFiles({
    required String bucket,
    required List<String> paths,
  }) => deleteMultipleFiles(bucket: bucket, paths: paths);

  @override
  Future<void> deleteFileFromUrl(String url) async {
    if (url.trim().isEmpty) return;
    final parsed = parseUrl(url);
    if (parsed == null) {
      throw ArgumentError('Invalid Supabase storage URL: $url');
    }
    await deleteSingleFile(bucket: parsed.bucket, path: parsed.path);
  }

  @override
  Future<void> deleteFilesFromUrls(List<String> urls) async {
    if (urls.isEmpty) return;

    final bucketToPaths = <String, List<String>>{};
    for (final url in urls) {
      final parsed = parseUrl(url);
      if (parsed != null) {
        bucketToPaths.putIfAbsent(parsed.bucket, () => []).add(parsed.path);
      }
    }

    await Future.wait(
      bucketToPaths.entries.map(
        (entry) => deleteMultipleFiles(bucket: entry.key, paths: entry.value),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // URLS
  // ---------------------------------------------------------------------------

  @override
  String getPublicUrl({
    required String bucket,
    required String path,
    TransformOptions? transform,
  }) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return storage.from(bucket).getPublicUrl(cleanPath, transform: transform);
  }

  @override
  String getUrl({
    required String bucket,
    required String path,
    TransformOptions? transform,
  }) => getPublicUrl(bucket: bucket, path: path, transform: transform);

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 3600,
    TransformOptions? transform,
  }) async {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return storage
        .from(bucket)
        .createSignedUrl(cleanPath, expiresIn, transform: transform);
  }

  /// Creates multiple signed URLs in batch for a given [bucket].
  Future<List<SignedUrlResult>> createSignedUrls({
    required String bucket,
    required List<String> paths,
    int expiresIn = 3600,
  }) async {
    if (paths.isEmpty) return [];
    final cleanPaths = paths
        .map((p) => p.startsWith('/') ? p.substring(1) : p)
        .toList();
    return storage.from(bucket).createSignedUrlsResult(cleanPaths, expiresIn);
  }

  // ---------------------------------------------------------------------------
  // METADATA & INSPECTION
  // ---------------------------------------------------------------------------

  @override
  Future<StorageItem?> getMetadata({
    required String bucket,
    required String path,
  }) async {
    try {
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      final lastSlash = cleanPath.lastIndexOf('/');
      final folder = lastSlash == -1 ? '' : cleanPath.substring(0, lastSlash);
      final fileName = lastSlash == -1
          ? cleanPath
          : cleanPath.substring(lastSlash + 1);

      final files = await storage
          .from(bucket)
          .list(
            path: folder.isEmpty ? null : folder,
            searchOptions: SearchOptions(search: fileName, limit: 10),
          );

      for (final f in files) {
        if (f.name == fileName) {
          return f.toStorageItem();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isFileExists({
    required String bucket,
    required String path,
  }) async {
    final meta = await getMetadata(bucket: bucket, path: path);
    return meta != null;
  }

  @override
  Future<int?> getFileSize({
    required String bucket,
    required String path,
  }) async {
    final metadata = await getMetadata(bucket: bucket, path: path);
    return metadata?.size;
  }

  @override
  Future<List<StorageItem>> listFiles({
    required String bucket,
    String? folderPath,
    int limit = 100,
    int offset = 0,
    String? search,
    SortBy? sortBy,
  }) async {
    final cleanPath = folderPath != null && folderPath.startsWith('/')
        ? folderPath.substring(1)
        : folderPath;

    final files = await storage
        .from(bucket)
        .list(
          path: (cleanPath == null || cleanPath.isEmpty) ? null : cleanPath,
          searchOptions: SearchOptions(
            limit: limit,
            offset: offset,
            search: search,
            sortBy: sortBy,
          ),
        );

    return files.map((f) => f.toStorageItem()).toList();
  }

  // ---------------------------------------------------------------------------
  // DOWNLOAD / MOVE / COPY
  // ---------------------------------------------------------------------------

  @override
  Future<Uint8List> downloadFile({
    required String bucket,
    required String path,
  }) async {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return storage.from(bucket).download(cleanPath);
  }

  @override
  Future<String> moveFile({
    required String fromBucket,
    required String fromPath,
    required String toPath,
    String? toBucket,
  }) async {
    final cleanFrom = fromPath.startsWith('/')
        ? fromPath.substring(1)
        : fromPath;
    final cleanTo = toPath.startsWith('/') ? toPath.substring(1) : toPath;

    return storage
        .from(fromBucket)
        .move(cleanFrom, cleanTo, destinationBucket: toBucket);
  }

  @override
  Future<String> copyFile({
    required String fromBucket,
    required String fromPath,
    required String toPath,
    String? toBucket,
  }) async {
    final cleanFrom = fromPath.startsWith('/')
        ? fromPath.substring(1)
        : fromPath;
    final cleanTo = toPath.startsWith('/') ? toPath.substring(1) : toPath;

    return storage
        .from(fromBucket)
        .copy(cleanFrom, cleanTo, destinationBucket: toBucket);
  }
}
