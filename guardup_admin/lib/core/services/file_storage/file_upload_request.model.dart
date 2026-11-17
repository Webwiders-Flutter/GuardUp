import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// A request model for file upload operations to Supabase Storage.
///
/// Encapsulates the target [bucket], destination [path], source data
/// (via [localPath], [bytes], or [xFile]), and upload options ([upsert], [contentType]).
class FileUploadRequest {
  const FileUploadRequest({
    required this.bucket,
    required this.path,
    this.localPath,
    this.bytes,
    this.xFile,
    this.contentType,
    this.upsert = false,
  });

  /// Creates an upload request from a local file path (Native platforms).
  const FileUploadRequest.fromPath({
    required this.bucket,
    required this.path,
    required String this.localPath,
    this.contentType,
    this.upsert = false,
  }) : bytes = null,
       xFile = null;

  /// Creates an upload request from in-memory bytes (ideal for Web & memory assets).
  const FileUploadRequest.fromBytes({
    required this.bucket,
    required this.path,
    required Uint8List this.bytes,
    this.contentType,
    this.upsert = false,
  }) : localPath = null,
       xFile = null;

  /// Creates an upload request from an [XFile] (from image_picker or file_picker).
  const FileUploadRequest.fromXFile({
    required this.bucket,
    required this.path,
    required XFile this.xFile,
    this.contentType,
    this.upsert = false,
  }) : localPath = null,
       bytes = null;

  /// Target Supabase Storage bucket name (e.g., 'public', 'trucks', 'documents').
  final String bucket;

  /// Target destination path within the bucket (e.g., 'images/truck_1.png').
  final String path;

  /// Local file system path (Native platforms).
  final String? localPath;

  /// Raw byte payload for direct memory/web uploads.
  final Uint8List? bytes;

  /// Cross-platform file abstraction (from file pickers).
  final XFile? xFile;

  /// Optional MIME type (e.g., 'image/png', 'application/pdf').
  final String? contentType;

  /// Whether to overwrite existing file at [path] if it already exists.
  final bool upsert;

  /// Creates a copy of this request with the given fields replaced.
  FileUploadRequest copyWith({
    String? bucket,
    String? path,
    String? localPath,
    Uint8List? bytes,
    XFile? xFile,
    String? contentType,
    bool? upsert,
  }) {
    return FileUploadRequest(
      bucket: bucket ?? this.bucket,
      path: path ?? this.path,
      localPath: localPath ?? this.localPath,
      bytes: bytes ?? this.bytes,
      xFile: xFile ?? this.xFile,
      contentType: contentType ?? this.contentType,
      upsert: upsert ?? this.upsert,
    );
  }
}
