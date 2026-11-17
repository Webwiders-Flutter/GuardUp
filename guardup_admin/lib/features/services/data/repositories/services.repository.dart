import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/repositories/base.repository.dart';
import '../models/service.model.dart';

final class ServicesRepository extends BaseSupabaseRepository<ServiceModel> {
  ServicesRepository(SupabaseClient client)
      : super(
          client: client,
          tableName: DatabaseTables.services,
          fromJson: ServiceModel.fromJson,
          entityName: 'service',
          searchFields: const [JsonKeys.name, JsonKeys.description],
          primarySortColumn: JsonKeys.displayOrder,
          primarySortAscending: true,
        );
}
