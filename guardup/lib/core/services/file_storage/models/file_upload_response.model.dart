/// Generic metadata representation for a stored file across any storage provider.
class StorageItem {
  const StorageItem({
    required this.name,
    this.id,
    this.size,
    this.mimeType,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Name of the file or folder.
  final String name;

  /// Unique identifier of the file (if provided by storage provider).
  final String? id;

  /// Size of the file in bytes.
  final int? size;

  /// MIME type of the file (e.g. 'image/png').
  final String? mimeType;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last updated timestamp.
  final DateTime? updatedAt;

  /// Additional provider-specific metadata.
  final Map<String, dynamic>? metadata;
}
