import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase/supabase.provider.dart';
import '/shared/states/pagination.state.dart';
import '../data/models/contact_us.model.dart';
import '../data/repositories/contact_us.repository.dart';
import '../presentation/controllers/contact_us.controller.dart';

final contactUsRepositoryProvider = Provider<ContactUsRepository>((ref) {
  return ContactUsRepository(ref.watch(supabaseClientProvider));
});

final contactUsControllerProvider =
    AsyncNotifierProvider<ContactUsController, PaginationState<ContactUs>>(
      ContactUsController.new,
    );
