import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/services/file_storage/file_storage.service.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/auth/data/repositories/auth_repository.dart';
import '/features/auth/data/repositories/user_repository.dart';
import '../bloc/companies/companies_bloc.dart';
import '../bloc/company_details/company_details_bloc.dart';
import '../bloc/company_profile/company_profile_bloc.dart';
import '../data/model/company.model.dart';
import '../data/repositories/company.repository.dart';

void registerCompanyDependencies(GetIt sl) {
  sl.registerLazySingleton<CompanyRepository>(
    () => CompanyRepository(sl<SupabaseClient>()),
  );
  sl.registerFactory<CompaniesBloc>(
    () => CompaniesBloc(sl<CompanyRepository>()),
  );
  sl.registerFactoryParam<CompanyDetailsBloc, String, CompanyModel?>(
    (id, preview) => CompanyDetailsBloc(
      sl<CompanyRepository>(),
      companyId: id,
      preview: preview,
    ),
  );
  sl.registerFactory<CompanyProfileBloc>(
    () => CompanyProfileBloc(
      companyRepository: sl<CompanyRepository>(),
      userRepository: sl<UserRepository>(),
      fileStorageService: sl<FileStorageService>(),
      getCurrentUserId: () => sl<AuthRepository>().currentUserId,
      onAccountUpdated: () {
        if (sl.isRegistered<AuthBloc>()) {
          sl<AuthBloc>().add(const AuthProfileRefreshRequested());
        }
      },
    ),
  );
}
