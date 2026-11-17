import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/repositories/base.repository.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '../models/document_type.model.dart';

final class DocumentTypeRepository
    extends BaseSupabaseRepository<DocumentTypeModel> {
  DocumentTypeRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.documentTypes,
        fromJson: DocumentTypeModel.fromJson,
        entityName: 'document type',
        searchFields: const [JsonKeys.name, JsonKeys.description],
        primarySortColumn: JsonKeys.displayOrder,
        primarySortAscending: true,
      );

  @override
  Future<({List<DocumentTypeModel> data, int total})> getPaginated({
    required int page,
    required int pageSize,
    bool? isActive,
    UserRoleType? targetRole,
    String? search,
    CustomQueryBuilder? customQuery,
  }) {
    return super.getPaginated(
      page: page,
      pageSize: pageSize,
      isActive: isActive,
      search: search,
      customQuery: (query) {
        if (targetRole != null) {
          query = query.eq(JsonKeys.targetRole, targetRole.apiValue);
        }
        if (customQuery != null) {
          query = customQuery(query);
        }
        return query;
      },
    );
  }
}
