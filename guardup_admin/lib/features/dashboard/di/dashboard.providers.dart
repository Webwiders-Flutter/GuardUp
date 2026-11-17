import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase/supabase.provider.dart';
import '/features/dashboard/data/models/dashboard_user_stats.model.dart';
import '/features/dashboard/data/repositories/dashboard_stats.repository.dart';
import '/features/dashboard/presentation/controllers/dashboard_stats.controller.dart';

final dashboardStatsRepositoryProvider = Provider<DashboardStatsRepository>((
  ref,
) {
  return DashboardStatsRepository(ref.watch(supabaseClientProvider));
});

final dashboardStatsControllerProvider =
    AsyncNotifierProvider.family<
      DashboardStatsController,
      DashboardUserStats,
      DashboardFilterParam
    >(DashboardStatsController.new);
