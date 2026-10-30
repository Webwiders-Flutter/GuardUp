import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardup/core/utils/extensions/datetime_extensions.dart';

extension SupabaseUserExtension on User {
  /// Safely extracts the user's name from metadata, defaulting to 'User'
  String get displayName => userMetadata?['name'] as String? ?? 'User';

  /// Safely extracts the user's profile image from metadata
  String? get displayProfileImage => userMetadata?['profileImage'] as String?;

  /// Safely formats the createdAt date into 'MMM yyyy' format
  String get formattedMemberSince {
    try {
      final date = DateTime.parse(createdAt);
      return date.memberSince;
    } catch (_) {
      return '';
    }
  }
}
