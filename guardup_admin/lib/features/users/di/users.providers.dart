import '/core/providers/supabase/supabase.provider.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/bodyguard.model.dart';
import '/features/users/data/models/user_model.dart';
import '/features/users/data/repositories/bodyguards.repository.dart';
import '/features/users/data/repositories/user_review.repository.dart';
import '/features/users/data/repositories/users.repository.dart';
import '/features/users/presentation/controllers/bodyguard_review.controller.dart';
import '/features/users/presentation/controllers/user_review.controller.dart';
import '/features/users/presentation/controllers/users.controller.dart';
import '/shared/states/pagination.state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(supabaseClientProvider));
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

final userReviewRepositoryProvider = Provider<UserReviewRepository>((ref) {
  return UserReviewRepository(ref.watch(supabaseClientProvider));
});

/// Application review actions (approve / reject documents and profile) for
/// the user with the given id.
final userReviewControllerProvider = AsyncNotifierProvider.autoDispose
    .family<UserReviewController, void, String>(UserReviewController.new);

final bodyguardsRepositoryProvider = Provider<BodyguardsRepository>((ref) {
  return BodyguardsRepository(ref.watch(supabaseClientProvider));
});

/// Company-managed bodyguards of the company with the given `companies.id`.
final companyBodyguardsProvider = FutureProvider.autoDispose
    .family<List<BodyguardModel>, String>((ref, companyId) {
      return ref
          .read(bodyguardsRepositoryProvider)
          .getCompanyBodyguards(companyId);
    });

/// Review actions (bodyguards and their documents) for one company's
/// bodyguards.
final bodyguardReviewControllerProvider = AsyncNotifierProvider.autoDispose
    .family<BodyguardReviewController, void, String>(
      BodyguardReviewController.new,
    );
