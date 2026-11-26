import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/repositories/base.repository.dart';
import '../model/membership_plan.model.dart';

/// `public.membership_plans`: Customer VIP membership tiers.
class MembershipPlanRepository
    extends BaseSupabaseRepository<MembershipPlanModel> {
  MembershipPlanRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.membershipPlans,
        fromJson: MembershipPlanModel.fromJson,
        entityName: 'membership plan',
        searchFields: const [JsonKeys.name],
        primarySortColumn: JsonKeys.displayOrder,
        primarySortAscending: true,
      );

  /// Active membership plans in display order.
  Future<List<MembershipPlanModel>> getActive() async {
    final rows = await client
        .from(tableName)
        .select()
        .eq(JsonKeys.isActive, true)
        .order(JsonKeys.displayOrder, ascending: true);
    return (rows as List<dynamic>)
        .map((r) => MembershipPlanModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
