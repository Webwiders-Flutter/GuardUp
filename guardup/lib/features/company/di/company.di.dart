import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bloc/companies/companies_bloc.dart';
import '../data/repositories/company.repository.dart';

void registerCompanyDependencies(GetIt sl) {
  sl.registerLazySingleton<CompanyRepository>(
    () => CompanyRepository(sl<SupabaseClient>()),
  );
  sl.registerFactory<CompaniesBloc>(
    () => CompaniesBloc(sl<CompanyRepository>()),
  );
}
