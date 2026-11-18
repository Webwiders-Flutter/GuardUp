import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/repositories/base.repository.dart';
import '../models/membership_plan.model.dart';

final class MembershipPlanRepository
    extends BaseSupabaseRepository<MembershipPlan> {
  MembershipPlanRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.membershipPlans,
        fromJson: MembershipPlan.fromJson,
        entityName: 'membership plan',
        // `description` is a text[] column, so `ilike` can't search it.
        searchFields: const [JsonKeys.name],
        primarySortColumn: JsonKeys.displayOrder,
        primarySortAscending: true,
      );
}
