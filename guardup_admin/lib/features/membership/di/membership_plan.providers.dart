import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase/supabase.provider.dart';
import '/shared/states/pagination.state.dart';
import '../data/models/membership_plan.model.dart';
import '../data/repositories/membership_plan.repository.dart';
import '../presentation/controllers/membership_plan.controller.dart';

final membershipPlanRepositoryProvider = Provider<MembershipPlanRepository>((
  ref,
) {
  return MembershipPlanRepository(ref.watch(supabaseClientProvider));
});

final membershipPlanControllerProvider =
    AsyncNotifierProvider<
      MembershipPlanController,
      PaginationState<MembershipPlan>
    >(MembershipPlanController.new);

/// Single plan for the details screen, fetched fresh so deep links work.
final membershipPlanDetailsProvider = FutureProvider.autoDispose
    .family<MembershipPlan, String>((ref, id) async {
      final repository = ref.read(membershipPlanRepositoryProvider);
      return repository.getDetails(id);
    });
