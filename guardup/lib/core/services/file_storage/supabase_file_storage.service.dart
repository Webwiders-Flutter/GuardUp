import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/logger/app_logger.dart';
import 'file_storage.service.dart';
import 'models/file_upload_request.model.dart';
import 'models/file_upload_response.model.dart';

/// Production-ready Supabase implementation of [FileStorageService].
class SupabaseFileStorageService implements FileStorageService {
  final SupabaseClient? client;

  SupabaseFileStorageService({this.client});

  SupabaseClient get _supabase {
    return client ?? Supabase.instance.client;
  }

  @override
  Future<String> uploadSingleFile(FileUploadRequest req) async {
    AppLogger.d('uploadSingleFile: bucket=${req.bucket}, path=${req.path}', tag: 'Storage');
    final storage = _supabase.storage.from(req.bucket);
    final fileOptions = FileOptions(
      upsert: req.upsert,
      contentType: req.contentType,
    );

    try {
      if (req.bytes != null) {
        await storage.uploadBinary(req.path, req.bytes!, fileOptions: fileOptions);
      } else if (req.localPath != null) {
        final file = File(req.localPath!);
        await storage.upload(req.path, file, fileOptions: fileOptions);
      } else if (req.xFile != null) {
        final bytes = await req.xFile!.readAsBytes();
        await storage.uploadBinary(req.path, bytes, fileOptions: fileOptions);
      }

      final url = getPublicUrl(bucket: req.bucket, path: req.path);
      AppLogger.d('uploadSingleFile success: $url', tag: 'Storage');
      return url;
    } catch (e, st) {
      AppLogger.e('uploadSingleFile failed', tag: 'Storage', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<List<String>> uploadMultipleFiles(List<FileUploadRequest> requests) async {
    return await Future.wait(requests.map(uploadSingleFile));
  }

  @override
  Future<String> upsertFile(FileUploadRequest req) async {
    final upsertReq = FileUploadRequest.fromXFile(
      bucket: req.bucket,
      path: req.path,
      xFile: req.xFile!,
      contentType: req.contentType,
      upsert: true,
    );
    return await uploadSingleFile(upsertReq);
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
    final newUrl = await uploadSingleFile(newRequest);
    if (oldPath != null && oldBucket != null) {
      try {
        await deleteSingleFile(bucket: oldBucket, path: oldPath);
      } catch (_) {}
    } else if (oldUrl != null) {
      try {
        await deleteFileFromUrl(oldUrl);
      } catch (_) {}
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

  @override
  Future<void> deleteSingleFile({required String bucket, required String path}) async {
    await _supabase.storage.from(bucket).remove([path]);
  }

  @override
  Future<void> deleteFile({required String bucket, required String path}) =>
      deleteSingleFile(bucket: bucket, path: path);

  @override
  Future<void> deleteMultipleFiles({
    required String bucket,
    required List<String> paths,
  }) async {
    await _supabase.storage.from(bucket).remove(paths);
  }

  @override
  Future<void> deleteFiles({
    required String bucket,
    required List<String> paths,
  }) => deleteMultipleFiles(bucket: bucket, paths: paths);

  @override
  Future<void> deleteFileFromUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final segments = uri.pathSegments;
    // URL shape: /storage/v1/object/public/<bucket>/<path...>
    final publicIdx = segments.indexOf('public');
    if (publicIdx != -1 && segments.length > publicIdx + 2) {
      final bucket = segments[publicIdx + 1];
      final path = segments.sublist(publicIdx + 2).join('/');
      await deleteSingleFile(bucket: bucket, path: path);
    }
  }

  @override
  Future<void> deleteFilesFromUrls(List<String> urls) async {
    await Future.wait(urls.map(deleteFileFromUrl));
  }

  @override
  String getPublicUrl({required String bucket, required String path}) {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  @override
  String getUrl({required String bucket, required String path}) =>
      getPublicUrl(bucket: bucket, path: path);

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 3600,
  }) async {
    return await _supabase.storage.from(bucket).createSignedUrl(path, expiresIn);
  }

  @override
  Future<bool> isFileExists({required String bucket, required String path}) async {
    final dir = path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : '';
    final name = path.contains('/') ? path.substring(path.lastIndexOf('/') + 1) : path;
    final files = await _supabase.storage.from(bucket).list(path: dir);
    return files.any((f) => f.name == name);
  }

  @override
  Future<StorageItem?> getMetadata({
    required String bucket,
    required String path,
  }) async {
    return null;
  }

  @override
  Future<int?> getFileSize({required String bucket, required String path}) async {
    return null;
  }

  @override
  Future<List<StorageItem>> listFiles({
    required String bucket,
    String? folderPath,
    int limit = 100,
    int offset = 0,
    String? search,
  }) async {
    final objects = await _supabase.storage.from(bucket).list(
      path: folderPath ?? '',
      searchOptions: SearchOptions(
        limit: limit,
        offset: offset,
        search: search,
      ),
    );
    return objects
        .map(
          (obj) => StorageItem(
            name: obj.name,
            id: obj.id,
            updatedAt: obj.updatedAt != null ? DateTime.tryParse(obj.updatedAt!) : null,
            createdAt: obj.createdAt != null ? DateTime.tryParse(obj.createdAt!) : null,
          ),
        )
        .toList();
  }

  @override
  Future<Uint8List> downloadFile({
    required String bucket,
    required String path,
  }) async {
    return await _supabase.storage.from(bucket).download(path);
  }

  @override
  Future<String> moveFile({
    required String fromBucket,
    required String fromPath,
    required String toPath,
    String? toBucket,
  }) async {
    await _supabase.storage.from(fromBucket).move(fromPath, toPath);
    return getPublicUrl(bucket: toBucket ?? fromBucket, path: toPath);
  }

  @override
  Future<String> copyFile({
    required String fromBucket,
    required String fromPath,
    required String toPath,
    String? toBucket,
  }) async {
    await _supabase.storage.from(fromBucket).copy(fromPath, toPath);
    return getPublicUrl(bucket: toBucket ?? fromBucket, path: toPath);
  }
}

