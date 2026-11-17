import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase/supabase.provider.dart';
import '../data/models/admin_settings.model.dart';
import '../data/repositories/admin_settings.repository.dart';
import '../presentation/controllers/admin_settings.controller.dart';

/// Provider for [AdminSettingsRepository].
final adminSettingsRepositoryProvider = Provider<AdminSettingsRepository>((
  ref,
) {
  return AdminSettingsRepository(ref.watch(supabaseClientProvider));
});

/// Async notifier controller provider for [AdminSettingsModel].
final adminSettingsControllerProvider =
    AsyncNotifierProvider<AdminSettingsController, AdminSettingsModel>(
      AdminSettingsController.new,
    );
