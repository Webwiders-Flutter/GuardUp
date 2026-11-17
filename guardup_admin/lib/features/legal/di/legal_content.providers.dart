import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase/supabase.provider.dart';
import '../data/models/legal_content.model.dart';
import '../data/repositories/legal_content.repository.dart';
import '../presentation/controllers/legal_content.controller.dart';

final legalContentRepositoryProvider = Provider<LegalContentRepository>((ref) {
  return LegalContentRepository(ref.watch(supabaseClientProvider));
});

final legalContentControllerProvider =
    AsyncNotifierProvider<LegalContentController, LegalContentModel?>(
      LegalContentController.new,
    );

/// Cached document provider keyed by compound (type, role, language) specification.
final legalContentByKeyProvider =
    FutureProvider.family<LegalContentModel, LegalContentKey>((ref, key) async {
      final repository = ref.watch(legalContentRepositoryProvider);
      return repository.getContent(
        type: key.type,
        role: key.role,
        language: key.language,
      );
    });
