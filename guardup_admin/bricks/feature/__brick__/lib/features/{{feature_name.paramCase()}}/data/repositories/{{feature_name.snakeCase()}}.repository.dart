import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/repositories/base.repository.dart';
import '/core/constants/api/database_tables.dart';
import '../models/{{feature_name.snakeCase()}}.model.dart';

final class {{feature_name.pascalCase()}}Repository
    extends BaseSupabaseRepository<{{feature_name.pascalCase()}}> {
  {{feature_name.pascalCase()}}Repository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.{{table_name.camelCase()}},
        fromJson: {{feature_name.pascalCase()}}.fromJson,
        entityName: '{{entity_name.lowerCase()}}',
      );
}
