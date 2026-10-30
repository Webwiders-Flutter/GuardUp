import 'package:flutter/foundation.dart';
import 'package:guardup/core/localization/domain/repositories/localization_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/providers/local/storage_service.dart';

class LocalizationRepositoryImpl implements LocalizationRepository {
  final StorageService _storageService;
  final SupabaseClient _supabaseClient;
  static const String _localeKey = 'user_locale_code';

  LocalizationRepositoryImpl({
    required StorageService storageService,
    required SupabaseClient supabaseClient,
  }) : _storageService = storageService,
       _supabaseClient = supabaseClient;

  @override
  Future<void> saveLocale(String localeCode) async {
    _storageService.setString(_localeKey, localeCode);

    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser != null) {
      try {
        await _supabaseClient
            .from('users')
            .update({'locale': localeCode})
            .eq('id', currentUser.id);
      } catch (e) {
        debugPrint('Failed to update locale in Supabase: $e');
      }
    }
  }

  @override
  Future<String?> getLocale() async {
    return _storageService.getString(_localeKey);
  }
}
