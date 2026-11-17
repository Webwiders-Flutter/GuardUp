import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase/supabase.provider.dart';
import '/features/services/data/models/service.model.dart';
import '/features/services/data/repositories/services.repository.dart';
import '/features/services/presentation/controllers/services.controller.dart';
import '/shared/states/pagination.state.dart';

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepository(ref.watch(supabaseClientProvider));
});

final servicesControllerProvider =
    AsyncNotifierProvider<ServicesController, PaginationState<ServiceModel>>(
      ServicesController.new,
    );
