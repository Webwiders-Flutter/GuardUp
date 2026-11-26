import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '../enum/content_type.enum.dart';
import '../model/legal_content.model.dart';

/// `public.legal_content`: Terms, privacy, about us, and policy texts.
class LegalContentRepository {
  final SupabaseClient client;

  LegalContentRepository(this.client);

  /// Fetches the latest published legal content for [role], [type], and [language].
  ///
  /// Returns `null` if no database row matches, allowing callers to fall back to static fixtures.
  Future<LegalContentModel?> getLatest({
    required UserRole role,
    required ContentType type,
    String language = 'en',
  }) async {
    final row = await client
        .from(DatabaseTables.legalContent)
        .select()
        .eq(JsonKeys.role, role.apiValue)
        .eq(JsonKeys.contentType, type.apiValue)
        .eq(JsonKeys.language, language)
        .order(JsonKeys.lastPublishedAt, ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;

    final html = (row[JsonKeys.contentHtml] as String?) ?? '';
    final updatedAtStr =
        row[JsonKeys.updatedAt] ?? row[JsonKeys.lastPublishedAt];

    return LegalContentModel(
      id: (row[JsonKeys.id] as String?) ?? 'legal_${type.apiValue}',
      contentType: type,
      title: type.name,
      contentHtml: html,
      clauses: const [],
      updatedAt: updatedAtStr != null
          ? DateTime.tryParse(updatedAtStr.toString())
          : null,
    );
  }
}
