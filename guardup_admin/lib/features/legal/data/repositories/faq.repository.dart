import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/repositories/base.repository.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '../../../users/data/enums/user_role.enum.dart';
import '../models/faq.model.dart';

final class FaqRepository extends BaseSupabaseRepository<Faq> {
  FaqRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.faqs,
        fromJson: Faq.fromJson,
        entityName: 'FAQ',
        searchFields: const [
          JsonKeys.question,
          JsonKeys.answer,
          JsonKeys.questionHi,
          JsonKeys.answerHi,
        ],
        secondarySortColumn: JsonKeys.createdAt,
        secondarySortAscending: false,
      );

  @override
  Future<({List<Faq> data, int total})> getPaginated({
    required int page,
    required int pageSize,
    bool? isActive,
    UserRoleType? role,
    String? search,
    CustomQueryBuilder? customQuery,
  }) {
    return super.getPaginated(
      page: page,
      pageSize: pageSize,
      isActive: isActive,
      search: search,
      customQuery: (query) {
        if (role != null) {
          query = query.eq(JsonKeys.role, role.apiValue);
        }
        if (customQuery != null) {
          query = customQuery(query);
        }
        return query;
      },
    );
  }
}
