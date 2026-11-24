import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase/supabase.provider.dart';
import '/features/company_bodyguards/data/repositories/company_bodyguards.repository.dart';
import '/features/company_bodyguards/presentation/controllers/company_bodyguard_review.controller.dart';
import '/features/company_bodyguards/presentation/controllers/company_bodyguards.controller.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/bodyguard.model.dart';
import '/shared/states/pagination.state.dart';

final companyBodyguardsRepositoryProvider =
    Provider<CompanyBodyguardsRepository>((ref) {
      return CompanyBodyguardsRepository(ref.watch(supabaseClientProvider));
    });

/// Admin listing of company-managed bodyguards with the given status.
final companyBodyguardsControllerProvider =
    AsyncNotifierProvider.family<
      CompanyBodyguardsController,
      PaginationState<BodyguardModel>,
      UserStatus
    >(CompanyBodyguardsController.new);

/// One company-managed bodyguard with its company, services, documents and
/// availability.
final companyBodyguardDetailsProvider = FutureProvider.autoDispose
    .family<BodyguardModel, String>((ref, bodyguardId) {
      return ref
          .read(companyBodyguardsRepositoryProvider)
          .getDetails(bodyguardId);
    });

/// Company-managed bodyguards of the company with the given `companies.id`
/// (company details screen).
final companyBodyguardsProvider = FutureProvider.autoDispose
    .family<List<BodyguardModel>, String>((ref, companyId) {
      return ref
          .read(companyBodyguardsRepositoryProvider)
          .getCompanyBodyguards(companyId);
    });

/// Review actions (the bodyguard and its documents) for the bodyguard with
/// the given id.
final companyBodyguardReviewControllerProvider = AsyncNotifierProvider
    .autoDispose
    .family<CompanyBodyguardReviewController, void, String>(
      CompanyBodyguardReviewController.new,
    );
