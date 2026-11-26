import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/repositories/base.repository.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '../models/document_type.model.dart';

/// `public.document_types`: Admin-configured document definitions.
final class DocumentTypesRepository
    extends BaseSupabaseRepository<DocumentTypeModel> {
  DocumentTypesRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.documentTypes,
        fromJson: DocumentTypeModel.fromJson,
        entityName: 'document type',
        searchFields: const [JsonKeys.name, JsonKeys.description],
        primarySortColumn: JsonKeys.displayOrder,
        primarySortAscending: true,
      );

  /// Active document types applicable to [role] in display order.
  Future<List<DocumentTypeModel>> getActiveFor(UserRole role) async {
    final targetRole = role == UserRole.company
        ? UserRole.company.apiValue
        : UserRole.guard.apiValue;
    final rows = await client
        .from(tableName)
        .select()
        .eq(JsonKeys.targetRole, targetRole)
        .eq(JsonKeys.isActive, true)
        .order(JsonKeys.displayOrder, ascending: true);
    return (rows as List<dynamic>)
        .map((r) => DocumentTypeModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
