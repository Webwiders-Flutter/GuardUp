import 'dart:io';

import 'package:guardup/core/utils/app_logs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A common service for uploading files to Supabase Storage.
class FileUploadService {
  final SupabaseClient _supabaseClient;

  FileUploadService(this._supabaseClient);

  /// Uploads a single [file] to the given [bucket] under [folder].
  ///
  /// Returns the public URL of the uploaded file.
  Future<String> uploadFile({
    required File file,
    required String bucket,
    required String folder,
    bool upsert = false,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$folder/$fileName';

      if (onProgress != null) {
        onProgress(0.1);

        double simulatedProgress = 0.1;
        bool isFinished = false;

        // Simulate progress since Supabase Flutter doesn't support native upload progress events for File streams yet.
        // This keeps the UI responsive and prevents OOM crashes from readAsBytes().
        Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 500));
          if (isFinished) return false;

          if (simulatedProgress < 0.95) {
            simulatedProgress += 0.02;
            onProgress(simulatedProgress);
          }
          return !isFinished;
        });

        await _supabaseClient.storage
            .from(bucket)
            .upload(
              filePath,
              file,
              fileOptions: FileOptions(cacheControl: '3600', upsert: upsert),
            );

        isFinished = true;
        onProgress(1.0);
      } else {
        await _supabaseClient.storage
            .from(bucket)
            .upload(
              filePath,
              file,
              fileOptions: FileOptions(cacheControl: '3600', upsert: upsert),
            );
      }

      final publicUrl = _supabaseClient.storage
          .from(bucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e, stackTrace) {
      AppLogs.error(
        'Failed to upload file to $bucket/$folder',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Uploads multiple [files] to the given [bucket] under [folder].
  ///
  /// Returns a list of public URLs for each uploaded file.
  Future<List<String>> uploadFiles({
    required List<File> files,
    required String bucket,
    required String folder,
  }) async {
    final List<String> urls = [];
    for (final file in files) {
      final url = await uploadFile(file: file, bucket: bucket, folder: folder);
      urls.add(url);
    }
    return urls;
  }
}
