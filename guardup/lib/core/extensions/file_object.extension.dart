import 'dart:io' as io;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'string.extension.dart';
// ---------------------------------------------------------------------------
// Constants & Lookup Tables
// ---------------------------------------------------------------------------

const _imageExtensions = {
  'png',
  'jpg',
  'jpeg',
  'webp',
  'svg',
  'gif',
  'bmp',
  'ico',
  'heic',
  'heif',
};

const _videoExtensions = {'mp4', 'mov', 'avi', 'mkv', 'webm'};

const _audioExtensions = {'mp3', 'wav', 'aac', 'm4a', 'ogg'};

const _docExtensions = {
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'csv',
  'txt',
  'rtf',
  'odt',
};

const _mimeTable = <String, String>{
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'webp': 'image/webp',
  'svg': 'image/svg+xml',
  'gif': 'image/gif',
  'bmp': 'image/bmp',
  'ico': 'image/x-icon',
  'heic': 'image/heic',
  'heif': 'image/heif',
  'pdf': 'application/pdf',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'txt': 'text/plain',
  'csv': 'text/csv',
  'json': 'application/json',
  'zip': 'application/zip',
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
  'avi': 'video/x-msvideo',
  'webm': 'video/webm',
  'mkv': 'video/x-matroska',
  'mp3': 'audio/mpeg',
  'wav': 'audio/wav',
  'aac': 'audio/aac',
  'm4a': 'audio/mp4',
  'ogg': 'audio/ogg',
};

/// Formats raw byte count into human-readable representation (e.g. "1.5 MB", "500 KB").
String formatBytes(int bytes, [int decimals = 1]) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (log(bytes) / log(1024)).floor();
  final clampedIndex = i.clamp(0, suffixes.length - 1);
  final size = bytes / pow(1024, clampedIndex);
  return '${size.toStringAsFixed(clampedIndex == 0 ? 0 : decimals)} ${suffixes[clampedIndex]}';
}

/// Resolves a standard MIME type from a file extension or path.
String lookupMimeType(String ext) {
  var cleanExt = ext.toLowerCase().trim();
  if (cleanExt.contains('.')) {
    cleanExt = cleanExt.split('.').last;
  }
  return _mimeTable[cleanExt] ?? 'application/octet-stream';
}

// ---------------------------------------------------------------------------
// String (File Path / URL / Storage Path) Extensions
// ---------------------------------------------------------------------------

/// Useful utility extensions on [String] when treated as a file path, URL, or storage directory.
extension FilePathStringX on String {
  /// Extracts the file name from a path or URL (e.g. "image.png").
  String get fileName {
    final cleanUrl = split('?').first.split('#').first;
    final normalized = cleanUrl.replaceAll(r'\', '/');
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash != -1 && lastSlash < normalized.length - 1) {
      return normalized.substring(lastSlash + 1);
    }
    return normalized;
  }

  /// Extracts the file name without extension (e.g. "image").
  String get fileNameWithoutExtension {
    final fn = fileName;
    final lastDot = fn.lastIndexOf('.');
    if (lastDot == -1) return fn;
    return fn.substring(0, lastDot);
  }

  /// Extracts the file extension in lower case without dot (e.g. "png", "pdf").
  /// Works for URLs, paths, filenames, and standalone extension tokens (e.g. "png" or ".png").
  String get fileExtension {
    final clean = split('?').first.split('#').first.trim();
    if (!clean.contains('/')) {
      final dotIndex = clean.lastIndexOf('.');
      if (dotIndex != -1 && dotIndex < clean.length - 1) {
        return clean.substring(dotIndex + 1).toLowerCase();
      }
      if (clean.isNotEmpty &&
          clean.length <= 10 &&
          _mimeTable.containsKey(clean.toLowerCase())) {
        return clean.toLowerCase();
      }
    }
    final fn = fileName;
    final lastDot = fn.lastIndexOf('.');
    if (lastDot == -1 || lastDot == fn.length - 1) return '';
    return fn.substring(lastDot + 1).toLowerCase();
  }

  /// Sanitized file name without special characters or spaces.
  String get cleanFileName {
    final ext = fileExtension;
    final base = fileNameWithoutExtension.toLowerCase().replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '',
    );
    return ext.isNotEmpty ? '$base.$ext' : base;
  }

  /// Returns true if this path, URL, or extension represents an image.
  bool get isImage {
    final ext = fileExtension;
    final clean = toLowerCase().trim();
    return _imageExtensions.contains(ext) ||
        _imageExtensions.contains(clean) ||
        resolvedMimeType.startsWith('image/');
  }

  /// Returns true if this path, URL, or extension represents an SVG.
  bool get isSvg {
    final ext = fileExtension;
    final clean = toLowerCase().trim();
    return ext == 'svg' ||
        clean == 'svg' ||
        resolvedMimeType == 'image/svg+xml';
  }

  /// Returns true if this path, URL, or extension represents a PDF.
  bool get isPdf {
    final ext = fileExtension;
    final clean = toLowerCase().trim();
    return ext == 'pdf' ||
        clean == 'pdf' ||
        resolvedMimeType == 'application/pdf';
  }

  /// Returns true if this path, URL, or extension represents a video.
  bool get isVideo {
    final ext = fileExtension;
    final clean = toLowerCase().trim();
    return _videoExtensions.contains(ext) ||
        _videoExtensions.contains(clean) ||
        resolvedMimeType.startsWith('video/');
  }

  /// Returns true if this path, URL, or extension represents an audio file.
  bool get isAudio {
    final ext = fileExtension;
    final clean = toLowerCase().trim();
    return _audioExtensions.contains(ext) ||
        _audioExtensions.contains(clean) ||
        resolvedMimeType.startsWith('audio/');
  }

  /// Returns true if this path, URL, or extension represents a document.
  bool get isDocument {
    final ext = fileExtension;
    final clean = toLowerCase().trim();
    return isPdf ||
        _docExtensions.contains(ext) ||
        _docExtensions.contains(clean);
  }

  /// Appends or updates a cache-busting query parameter (`?v=...`) with a unique timestamp.
  String get burstUrl {
    if (trim().isEmpty) return this;
    final uri = Uri.tryParse(this);
    if (uri == null) return this;
    final queryParams = Map<String, String>.from(uri.queryParameters);
    queryParams['v'] =
        '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}';
    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Returns the resolved MIME type based on file extension or filename.
  String get resolvedMimeType {
    final ext = fileExtension;
    if (ext.isNotEmpty) return lookupMimeType(ext);
    return lookupMimeType(this);
  }

  /// Automatically prepends [DateTime.now().millisecondsSinceEpoch] to this file path or file name.
  ///
  /// Examples:
  /// - `'truck.png'.withTimestamp` -> `'1727534500000_truck.png'`
  /// - `'material-type/sample.png'.withTimestamp` -> `'material-type/1727534500000_sample.png'`
  String get withTimestamp {
    final slashIndex = lastIndexOf('/');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (slashIndex != -1) {
      final folder = substring(0, slashIndex);
      final file = substring(slashIndex + 1);
      return '$folder/${timestamp}_$file';
    }
    return '${timestamp}_$this';
  }

  /// Creates a timestamped path within this folder or from this path.
  ///
  /// Examples:
  /// - `'material-type'.timestamped('photo.png')` -> `'material-type/1727534500000_photo.png'`
  /// - `'photo.png'.timestamped()` -> `'1727534500000_photo.png'`
  String timestamped([String? childName]) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (childName != null && childName.isNotEmpty) {
      final clean = childName.cleanFileName;
      final folder = endsWith('/') ? substring(0, length - 1) : this;
      return '$folder/${timestamp}_$clean';
    }
    return withTimestamp;
  }

  /// Convenience helper to create a storage upload path by combining this folder path
  /// with [child] (which can be [XFile], [io.File], or [String]), automatically inserting
  /// [DateTime.now().millisecondsSinceEpoch] and cleaning the filename.
  ///
  /// Example:
  /// ```dart
  /// final path = StorageFolders.materialType.timestampedPath(imageFile);
  /// // Result: "material-type/1727534500000_profile.png"
  /// ```
  String timestampedPath(dynamic child) {
    if (child is XFile) {
      return child.timestampedPath(this);
    }
    if (child is io.File) {
      return timestamped(child.fileName);
    }
    return timestamped(child?.toString() ?? 'file');
  }
}

// ---------------------------------------------------------------------------
// Nullable String Extensions
// ---------------------------------------------------------------------------

/// Useful utility extensions on nullable [String] for file path / URL checks.
extension NullableFilePathStringX on String? {
  String get fileName => this?.fileName ?? '';
  String get fileNameWithoutExtension => this?.fileNameWithoutExtension ?? '';
  String get fileExtension => this?.fileExtension ?? '';
  String get cleanFileName => this?.cleanFileName ?? '';
  String get resolvedMimeType =>
      this?.resolvedMimeType ?? 'application/octet-stream';
  bool get isImage => this != null && this!.isImage;
  bool get isSvg => this != null && this!.isSvg;
  bool get isPdf => this != null && this!.isPdf;
  bool get isVideo => this != null && this!.isVideo;
  bool get isAudio => this != null && this!.isAudio;
  bool get isDocument => this != null && this!.isDocument;
  String? get burstUrl => this?.burstUrl;
}

// ---------------------------------------------------------------------------
// XFile Extensions
// ---------------------------------------------------------------------------

/// Useful utility extensions on [XFile] (from image_picker, file_picker, etc.).
extension XFileX on XFile {
  /// File name with extension (e.g. "profile_photo.png").
  String get fileName {
    if (name.isNotEmpty) return name.fileName;
    if (path.isNotEmpty) return path.fileName;
    return '';
  }

  /// File name without extension (e.g. "profile_photo").
  String get fileNameWithoutExtension {
    final fn = fileName;
    if (fn.isNotEmpty) return fn.fileNameWithoutExtension;
    return 'file';
  }

  /// Lowercase extension without leading dot (e.g. "png", "pdf").
  String get fileExtension {
    final ext = fileName.fileExtension;
    if (ext.isNotEmpty) return ext;
    final pathExt = path.fileExtension;
    if (pathExt.isNotEmpty) return pathExt;
    final mime = mimeType?.toLowerCase();
    if (mime != null && mime.isNotEmpty) {
      for (final entry in _mimeTable.entries) {
        if (entry.value == mime) {
          return entry.key;
        }
      }
      if (mime.startsWith('image/')) {
        return mime.substring('image/'.length);
      }
    }
    return '';
  }

  /// Sanitized base name without special characters or spaces.
  String get cleanName => fileNameWithoutExtension.toLowerCase().replaceAll(
    RegExp(r'[^a-zA-Z0-9._-]'),
    '',
  );

  /// Sanitized file name with extension.
  String get cleanFileName =>
      fileExtension.isNotEmpty ? '$cleanName.$fileExtension' : cleanName;

  /// File name prepended with [DateTime.now().millisecondsSinceEpoch].
  ///
  /// Example: `"1727534500000_profile.png"`
  String get timestampedName {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${timestamp}_$cleanFileName';
  }

  /// Builds a storage upload path under [folder] with an automatic timestamp prefix.
  ///
  /// Example:
  /// ```dart
  /// imageFile.timestampedPath(StorageFolders.materialType);
  /// // Result: "material-type/1727534500000_profile.png"
  /// ```
  String timestampedPath(String folder) {
    final cleanFolder = folder.endsWith('/')
        ? folder.substring(0, folder.length - 1)
        : folder;
    return '$cleanFolder/$timestampedName';
  }

  /// Alias for [timestampedPath].
  String toStoragePath(String folder) => timestampedPath(folder);

  /// Synchronously returns human-readable formatted file size when available locally.
  /// Returns empty string `""` if not available synchronously or on web.
  String get formattedSize {
    if (!kIsWeb && path.isNotEmpty) {
      try {
        final f = io.File(path);
        if (f.existsSync()) {
          return formatBytes(f.lengthSync());
        }
      } catch (_) {}
    }
    return '';
  }

  /// Asynchronously returns human-readable formatted file size (e.g. "1.5 MB", "500 KB").
  /// Works across all platforms including Flutter Web and local files.
  Future<String> getFormattedSize([int decimals = 1]) async {
    try {
      final bytes = await length();
      return formatBytes(bytes, decimals);
    } catch (_) {
      return formattedSize;
    }
  }

  /// Asynchronously returns the file size in bytes.
  Future<int> get fileSizeBytes async {
    try {
      return await length();
    } catch (_) {
      return 0;
    }
  }

  /// Returns the resolved MIME type, falling back to extension lookup
  /// if [mimeType] is null, empty, or 'application/octet-stream'.
  String get resolvedMimeType {
    final mime = mimeType?.toLowerCase();
    if (mime != null && mime.isNotEmpty && mime != 'application/octet-stream') {
      return mime;
    }
    final ext = fileExtension;
    if (ext.isNotEmpty) {
      return lookupMimeType(ext);
    }
    return lookupMimeType(fileName);
  }

  /// Returns true if this file is an image based on MIME type or extension.
  bool get isImage =>
      (mimeType?.toLowerCase().startsWith('image/') ?? false) ||
      fileExtension.isImage ||
      fileName.isImage ||
      path.isImage;

  /// Returns true if this file is an SVG.
  bool get isSvg => fileExtension.isSvg || path.isSvg;

  /// Returns true if this file is a PDF.
  bool get isPdf =>
      (mimeType?.toLowerCase() == 'application/pdf') ||
      fileExtension.isPdf ||
      path.isPdf;

  /// Returns true if this file is a video.
  bool get isVideo =>
      (mimeType?.toLowerCase().startsWith('video/') ?? false) ||
      fileExtension.isVideo ||
      path.isVideo;

  /// Returns true if this file is an audio file.
  bool get isAudio =>
      (mimeType?.toLowerCase().startsWith('audio/') ?? false) ||
      fileExtension.isAudio ||
      path.isAudio;

  /// Returns true if this file is a document (PDF, Word, Excel, text, etc.).
  bool get isDocument => fileExtension.isDocument || path.isDocument;

  /// Returns true if this file's path points to an external or web URL.
  bool get isUrl => path.isUrl;
}

// ---------------------------------------------------------------------------
// Nullable XFile Extensions
// ---------------------------------------------------------------------------

/// Useful utility extensions on nullable [XFile].
extension NullableXFileX on XFile? {
  String get fileName => this?.fileName ?? '';
  String get fileNameWithoutExtension => this?.fileNameWithoutExtension ?? '';
  String get fileExtension => this?.fileExtension ?? '';
  String get cleanName => this?.cleanName ?? '';
  String get cleanFileName => this?.cleanFileName ?? '';
  bool get isImage => this != null && this!.isImage;
  bool get isSvg => this != null && this!.isSvg;
  bool get isPdf => this != null && this!.isPdf;
  bool get isVideo => this != null && this!.isVideo;
  bool get isAudio => this != null && this!.isAudio;
  bool get isDocument => this != null && this!.isDocument;
  bool get isUrl => this != null && this!.isUrl;
  String get resolvedMimeType =>
      this?.resolvedMimeType ?? 'application/octet-stream';
}

// ---------------------------------------------------------------------------
// io.File Extensions (Delegates cleanly to FilePathStringX)
// ---------------------------------------------------------------------------

/// Useful utility extensions on [io.File].
extension FileX on io.File {
  String get fileName => path.fileName;
  String get fileNameWithoutExtension => path.fileNameWithoutExtension;
  String get fileExtension => path.fileExtension;
  bool get isImage => path.isImage;
  bool get isSvg => path.isSvg;
  bool get isPdf => path.isPdf;
  bool get isVideo => path.isVideo;
  bool get isAudio => path.isAudio;
  bool get isDocument => path.isDocument;
}

/// Useful utility extensions on nullable [io.File].
extension NullableFileX on io.File? {
  String get fileName => this?.fileName ?? '';
  String get fileNameWithoutExtension => this?.fileNameWithoutExtension ?? '';
  String get fileExtension => this?.fileExtension ?? '';
  bool get isImage => this != null && this!.isImage;
  bool get isSvg => this != null && this!.isSvg;
  bool get isPdf => this != null && this!.isPdf;
  bool get isVideo => this != null && this!.isVideo;
  bool get isAudio => this != null && this!.isAudio;
  bool get isDocument => this != null && this!.isDocument;
}

// ---------------------------------------------------------------------------
// Uint8List Memory Byte Extensions
// ---------------------------------------------------------------------------

/// Useful utility extensions on [Uint8List] memory bytes.
extension Uint8ListFileX on Uint8List {
  /// Returns true if this byte buffer represents an SVG XML document.
  bool get isSvg {
    if (isEmpty) return false;
    final prefix = String.fromCharCodes(take(100)).trim().toLowerCase();
    return prefix.startsWith('<svg') || prefix.contains('<svg');
  }
}

/// Useful utility extensions on nullable [Uint8List] memory bytes.
extension NullableUint8ListFileX on Uint8List? {
  bool get isSvg => this != null && this!.isSvg;
}

