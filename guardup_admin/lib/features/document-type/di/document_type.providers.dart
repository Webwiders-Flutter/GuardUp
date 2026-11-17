import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase/supabase.provider.dart';
import '/features/document-type/data/models/document_type.model.dart';
import '/features/document-type/data/repositories/document_type.repository.dart';
import '/features/document-type/presentation/controllers/document_type.controller.dart';
import '/shared/states/pagination.state.dart';

final documentTypeRepositoryProvider = Provider<DocumentTypeRepository>((ref) {
  return DocumentTypeRepository(ref.watch(supabaseClientProvider));
});

final documentTypeControllerProvider =
    AsyncNotifierProvider<
      DocumentTypeController,
      PaginationState<DocumentTypeModel>
    >(DocumentTypeController.new);
