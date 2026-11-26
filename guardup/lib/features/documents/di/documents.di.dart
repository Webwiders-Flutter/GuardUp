import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/services/file_storage/file_storage.service.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '/features/auth/domain/repositories/auth_repository.dart';
import '/features/auth/domain/repositories/user_repository.dart';
import '/features/body_guard/data/repositories/bodyguard.repository.dart';
import '/shared/models/record_owner.model.dart';
import '../bloc/documents_bloc.dart';
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
  sl.registerFactoryParam<DocumentsBloc, RecordOwner, UserRole>(
    (owner, role) => DocumentsBloc(
      typesRepository: sl<DocumentTypesRepository>(),
      documentsRepository: sl<UserDocumentsRepository>(),
      userRepository: sl<UserRepository>(),
      bodyguardRepository: sl<BodyguardRepository>(),
      owner: owner,
      role: role,
      getCurrentUserId: () => sl<AuthRepository>().currentUserId,
      onAccountSubmitted: () {
        if (sl.isRegistered<AuthBloc>()) {
          sl<AuthBloc>().add(const AuthCheckStatusRequested());
          sl<AuthBloc>().add(const AuthReloadRoleDataRequested());
        }
      },
    ),
  );
}
