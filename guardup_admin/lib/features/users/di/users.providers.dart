import '/core/providers/supabase/supabase.provider.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/user_model.dart';
import '/features/users/data/repositories/users.repository.dart';
import '/features/users/presentation/controllers/users.controller.dart';
import '/shared/states/pagination.state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(supabaseFunctionProvider),
  );
});
final usersControllerProvider =
    AsyncNotifierProvider.family<
      UsersController,
      PaginationState<UserModel>,
      ({UserRoleType role, UserStatus status})
    >(UsersController.new);

/// Fetches a single user's detailed profile by their [userId].
final userDetailsProvider = FutureProvider.autoDispose
    .family<UserModel, String>((ref, userId) async {
      final repository = ref.read(usersRepositoryProvider);
      return repository.getDetails(userId);
    });
