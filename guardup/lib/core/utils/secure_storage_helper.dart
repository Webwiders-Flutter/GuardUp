import 'package:guardup/core/utils/app_logs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper to resolve private Supabase Storage URLs into secure, time-limited signed URLs.
/// Includes an in-memory cache to prevent repeated signing requests.
class SecureStorageHelper {
  SecureStorageHelper._();

  static const Set<String> _secureBuckets = {
    'student_applications',
    'student-applications',
    'visa_documents',
    'visa-documents',
    'consultation-documents',
    'consultation_documents',
    'support_attachments',
    'complaints',
  };

  // Cache: key -> (signedUrl, expiresAt)
  static final Map<String, ({String url, DateTime expiresAt})> _cache = {};

  static String _canonicalBucket(String bucket) {
    switch (bucket) {
      case 'student-applications':
      case 'student_applications':
        return 'student_applications';
      case 'visa-documents':
      case 'visa_documents':
        return 'visa_documents';
      case 'consultation_documents':
      case 'consultation-documents':
        return 'consultation-documents';
      case 'complaints':
      case 'support_attachments':
        return 'support_attachments';
      default:
        return bucket;
    }
  }

  static String? _alternateBucket(String bucket) {
    switch (bucket) {
      case 'student_applications':
        return 'student-applications';
      case 'student-applications':
        return 'student_applications';
      case 'visa_documents':
        return 'visa-documents';
      case 'visa-documents':
        return 'visa_documents';
      case 'consultation-documents':
        return 'consultation_documents';
      case 'consultation_documents':
        return 'consultation-documents';
      case 'support_attachments':
        return 'complaints';
      case 'complaints':
        return 'support_attachments';
      default:
        return null;
    }
  }

  /// Resolves a storage URL or path to a secure, signed URL if it belongs to a private bucket.
  /// If the URL is already signed or not in a secure bucket, returns [url] unchanged.
  static Future<String> getSecureUrl(
    String url, {
    int expiresIn = 86400, // 24 hours
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    // Handle legacy complaints URLs by rewriting to support_attachments
    if (trimmed.contains('/complaints/')) {
      final rewritten = trimmed.replaceAll(
        '/complaints/',
        '/support_attachments/',
      );
      return getSecureUrl(rewritten, expiresIn: expiresIn);
    }

    // Local files or non-http paths do not need signing
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Already signed URL
    if (trimmed.contains('/storage/v1/object/sign/')) {
      return trimmed;
    }

    // Check in-memory cache first
    final cached = _cache[trimmed];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.url;
    }

    // Check if the URL points to one of the protected document buckets
    for (final bucket in _secureBuckets) {
      final marker = '/$bucket/';
      final index = trimmed.indexOf(marker);
      if (index != -1) {
        final rawPath = trimmed
            .substring(index + marker.length)
            .split('?')
            .first;
        final decodedPath = Uri.decodeComponent(rawPath);
        final cleanPath = decodedPath.startsWith('/')
            ? decodedPath.substring(1)
            : decodedPath;

        final primaryBucket = _canonicalBucket(bucket);
        final alternateBucket = _alternateBucket(primaryBucket);

        try {
          final signed = await Supabase.instance.client.storage
              .from(primaryBucket)
              .createSignedUrl(cleanPath, expiresIn);

          final expiry = DateTime.now().add(
            Duration(seconds: expiresIn - 7200),
          );
          _cache[trimmed] = (url: signed, expiresAt: expiry);

          return signed;
        } catch (e) {
          // If primary alias failed, try alternate bucket name if available
          if (alternateBucket != null) {
            try {
              final signed = await Supabase.instance.client.storage
                  .from(alternateBucket)
                  .createSignedUrl(cleanPath, expiresIn);

              final expiry = DateTime.now().add(
                Duration(seconds: expiresIn - 7200),
              );
              _cache[trimmed] = (url: signed, expiresAt: expiry);

              return signed;
            } catch (altErr, altStack) {
              AppLogs.error(
                'Failed to generate signed URL for $alternateBucket/$cleanPath',
                error: altErr,
                stackTrace: altStack,
              );
            }
          }

          AppLogs.error(
            'Failed to generate signed URL for $primaryBucket/$cleanPath',
            error: e,
          );
          return trimmed; // fallback to original URL
        }
      }
    }

    return trimmed;
  }

  /// Checks if a given storage URL points to a private document bucket.
  static bool isPrivateDocumentUrl(String url) {
    final trimmed = url.trim();
    for (final bucket in _secureBuckets) {
      if (bucket != 'support_attachments' && bucket != 'complaints') {
        if (trimmed.contains('/$bucket/')) return true;
      }
    }
    return false;
  }
}
