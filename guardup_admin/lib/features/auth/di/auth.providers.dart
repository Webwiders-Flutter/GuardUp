import '/core/providers/supabase/supabase.provider.dart';
import '/features/users/data/models/user_model.dart';
import '/features/auth/data/repositories/admin_user.repository.dart';
import '/features/auth/data/repositories/auth.repository.dart';
import '/features/auth/presentation/controllers/admin_user.controller.dart';
import '/features/auth/presentation/controllers/auth.controller.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(goTrueClientProvider));
});

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);

final adminUserRepositoryProvider = Provider<AdminUserRepository>(
  (ref) => AdminUserRepository(ref.watch(supabaseClientProvider)),
);

final adminUserControllerProvider =
    AsyncNotifierProvider<AdminUserController, UserModel?>(
      AdminUserController.new,
    );
