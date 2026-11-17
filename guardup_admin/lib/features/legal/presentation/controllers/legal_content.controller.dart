import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/utils/callback/async_callback.handler.dart';
import '../../../users/data/enums/user_role.enum.dart';
import '/features/legal/data/enums/content_type.enum.dart';
import '/features/legal/data/models/legal_content.model.dart';
import '/features/legal/data/repositories/legal_content.repository.dart';
import '/features/legal/di/legal_content.providers.dart';
import '/core/enums/language.enum.dart';

class LegalContentController extends AsyncNotifier<LegalContentModel?> {
  LegalContentRepository get _repository =>
      ref.read(legalContentRepositoryProvider);

  final Map<LegalContentKey, LegalContentModel> _cache = {};

  @override
  FutureOr<LegalContentModel?> build() {
    return null;
  }

  /// Retrieves legal content for the given [type], [role], and [language].
  ///
  /// Uses in-memory cache to ensure instant UI transitions when switching scopes,
  /// with [forceRefresh] allowing forced database fetch from Supabase.
  Future<LegalContentModel> getContent({
    required ContentType type,
    required UserRoleType role,
    required LanguageType language,
    bool forceRefresh = false,
  }) async {
    final key = (type: type, role: role, language: language);

    if (!forceRefresh && _cache.containsKey(key)) {
      final cached = _cache[key]!;
      state = AsyncData(cached);
      return cached;
    }

    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final model = await _repository.getContent(
          type: type,
          role: role,
          language: language,
        );
        _cache[key] = model;
        return model;
      }),
    );

    state = result;

    if (result.hasError) {
      throw result.error!;
    }

    return result.value ??
        LegalContentModel(
          contentType: type,
          role: role,
          language: language,
          contentHtml: '',
        );
  }

  /// Publishes legal content to Supabase and updates cache and state.
  Future<LegalContentModel> publishContent({
    required ContentType type,
    required UserRoleType role,
    required LanguageType language,
    required String contentHtml,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final updated = await _repository.publishContent(
          type: type,
          role: role,
          language: language,
          contentHtml: contentHtml,
        );
        final key = (type: type, role: role, language: language);
        _cache[key] = updated;
        ref.invalidate(legalContentByKeyProvider(key));
        return updated;
      }),
    );

    state = result;

    if (result.hasError) {
      throw result.error!;
    }

    return result.value!;
  }
}
