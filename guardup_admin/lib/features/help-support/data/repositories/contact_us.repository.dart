import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/error/api_exception.dart';
import '/core/repositories/base.repository.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '../../../users/data/enums/user_role.enum.dart';
import '../models/contact_us.model.dart';

final class ContactUsRepository extends BaseSupabaseRepository<ContactUs> {
  ContactUsRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.contactUs,
        fromJson: ContactUs.fromJson,
        entityName: 'support request',
        searchFields: const [
          JsonKeys.fullName,
          JsonKeys.email,
          JsonKeys.mobileNumber,
          JsonKeys.message,
        ],
        primarySortColumn: JsonKeys.createdAt,
        primarySortAscending: false,
      );

  @override
  Future<({List<ContactUs> data, int total})> getPaginated({
    required int page,
    required int pageSize,
    bool? isActive,
    bool? isResolved,
    UserRoleType? role,
    String? search,
    CustomQueryBuilder? customQuery,
  }) {
    return super.getPaginated(
      page: page,
      pageSize: pageSize,
      search: search,
      customQuery: (query) {
        if (isResolved != null) {
          query = query.eq(JsonKeys.isResolved, isResolved);
        }
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

  Future<ContactUs> toggleResolved(String id, bool isResolved) async {
    final response = await client
        .from(tableName)
        .update({JsonKeys.isResolved: isResolved})
        .eq(JsonKeys.id, id)
        .select();

    if (response.isEmpty) {
      throw ApiException(
        "Unable to update support request status. Please try again.",
      );
    }

    return ContactUs.fromJson(response.first);
  }
}
