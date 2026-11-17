import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/error/api_exception.dart';
import '../../../users/data/enums/user_role.enum.dart';
import '/features/legal/data/enums/content_type.enum.dart';
import '/features/legal/data/models/legal_content.model.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/enums/language.enum.dart';

class LegalContentRepository {
  final SupabaseClient _client;

  LegalContentRepository(this._client);

  /// Fetches legal content from Supabase for the specified [type], [role], and [language].
  ///
  /// If no record is found in the database, returns an empty fallback model.
  Future<LegalContentModel> getContent({
    required ContentType type,
    required UserRoleType role,
    required LanguageType language,
  }) async {
    final response = await _client
        .from(DatabaseTables.legalContent)
        .select()
        .eq(JsonKeys.role, role.apiValue)
        .eq(JsonKeys.contentType, type.apiValue)
        .eq(JsonKeys.language, language.code)
        .maybeSingle();

    if (response == null) {
      return LegalContentModel(
        contentType: type,
        role: role,
        language: language,
        contentHtml: '',
      );
    }

    return LegalContentModel.fromJson(response);
  }

  /// Publishes legal content to Supabase using upsert on conflict `(role, type, language_code)`.
  Future<LegalContentModel> publishContent({
    required ContentType type,
    required UserRoleType role,
    required LanguageType language,
    required String contentHtml,
  }) async {
    final payload = <String, dynamic>{
      JsonKeys.role: role.apiValue,
      JsonKeys.contentType: type.apiValue,
      JsonKeys.language: language.code,
      JsonKeys.contentHtml: contentHtml,
    };

    final response = await _client
        .from(DatabaseTables.legalContent)
        .update(payload)
        .eq(JsonKeys.role, role.apiValue)
        .eq(JsonKeys.contentType, type.apiValue)
        .eq(JsonKeys.language, language.code)
        .select()
        .maybeSingle();

    if (response == null) {
      throw ApiException(
        'Unable to publish legal content. Please try again later.',
      );
    }

    return LegalContentModel.fromJson(response);
  }
}
