import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_functions.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/repositories/base.repository.dart';
import '/shared/models/record_owner.model.dart';
import '../models/service.model.dart';

/// `public.services` (admin-managed catalogue) and the owner links in
/// `public.user_services`. See documentation/services.md.
final class ServicesRepository extends BaseSupabaseRepository<ServiceModel> {
  ServicesRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.services,
        fromJson: ServiceModel.fromJson,
        entityName: 'service',
        searchFields: const [JsonKeys.name, JsonKeys.description],
        primarySortColumn: JsonKeys.sortOrder,
      );

  /// Active services in display order.
  Future<List<ServiceModel>> getActive() async {
    final rows = await client
        .from(tableName)
        .select(selectColumns)
        .eq(JsonKeys.isActive, true)
        .order(JsonKeys.sortOrder, ascending: true);
    return rows.map(ServiceModel.fromJson).toList();
  }

  /// Ids of the services linked to [owner].
  Future<List<String>> getAssignedIds(RecordOwner owner) async {
    final rows = await client
        .from(DatabaseTables.userServices)
        .select(JsonKeys.serviceId)
        .eq(owner.column, owner.id);
    return [
      for (final row in rows)
        if (row[JsonKeys.serviceId] case final String id when id.isNotEmpty) id,
    ];
  }

  /// Replaces the services of [owner] atomically via RPC
  /// (`set_user_services` for an account, `set_bodyguard_services` for a
  /// company-managed bodyguard).
  Future<void> assign(RecordOwner owner, List<String> serviceIds) {
    return switch (owner) {
      AccountOwner(:final id) => client.rpc(
        DatabaseFunctions.setUserServices,
        params: {JsonKeys.pUserId: id, JsonKeys.pServiceIds: serviceIds},
      ),
      ManagedBodyguardOwner(:final id) => client.rpc(
        DatabaseFunctions.setBodyguardServices,
        params: {JsonKeys.pBodyguardId: id, JsonKeys.pServiceIds: serviceIds},
      ),
    };
  }
}
