import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase/supabase.provider.dart';

import '../data/models/user_device.model.dart';
import '../data/repositories/user_device.repository.dart';
import '../presentation/controllers/user_device.controller.dart';

final userDeviceRepositoryProvider = Provider<UserDeviceRepository>((ref) {
  return UserDeviceRepository(ref.watch(supabaseClientProvider));
});

final userDeviceControllerProvider =
    AsyncNotifierProvider<UserDeviceController, UserDeviceModel?>(
      UserDeviceController.new,
    );
