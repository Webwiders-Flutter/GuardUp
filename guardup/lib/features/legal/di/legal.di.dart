import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/contact_us.repository.dart';
import '../data/repositories/legal_content.repository.dart';

void registerLegalDependencies(GetIt sl) {
  sl.registerLazySingleton<LegalContentRepository>(
    () => LegalContentRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ContactUsRepository>(
    () => ContactUsRepository(sl<SupabaseClient>()),
  );
}
