import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase/supabase.provider.dart';
import '../data/models/faq.model.dart';
import '../data/repositories/faq.repository.dart';
import '../presentation/controllers/faq.controller.dart';
import '/shared/states/pagination.state.dart';

final faqRepositoryProvider = Provider<FaqRepository>((ref) {
  return FaqRepository(ref.watch(supabaseClientProvider));
});

final faqControllerProvider =
    AsyncNotifierProvider<FaqController, PaginationState<Faq>>(
      FaqController.new,
    );
