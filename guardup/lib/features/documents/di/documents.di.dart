import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/services/file_storage/file_storage.service.dart';
import '../data/repositories/document_types.repository.dart';
import '../data/repositories/user_documents.repository.dart';

void registerDocumentsDependencies(GetIt sl) {
  sl.registerLazySingleton<DocumentTypesRepository>(
    () => DocumentTypesRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<UserDocumentsRepository>(
    () => UserDocumentsRepository(
      sl<SupabaseClient>(),
      fileStorageService: sl.isRegistered<FileStorageService>()
          ? sl<FileStorageService>()
          : null,
    ),
  );
}
