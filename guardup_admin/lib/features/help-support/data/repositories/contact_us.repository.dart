import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/core/repositories/base.repository.dart';
import '/features/help-support/data/enums/contact_us_status.enum.dart';
import '/features/help-support/data/models/contact_us.model.dart';
import '/features/users/data/enums/user_role.enum.dart';

final class ContactUsRepository extends BaseSupabaseRepository<ContactUs> {
  ContactUsRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.contactUs,
        fromJson: ContactUs.fromJson,
        entityName: 'support request',
        searchFields: const [
          JsonKeys.contactFullName,
          JsonKeys.email,
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
    ContactUsStatus? status,
    UserRoleType? role,
    String? search,
    CustomQueryBuilder? customQuery,
  }) {
    return super.getPaginated(
      page: page,
      pageSize: pageSize,
      search: search,
      customQuery: (query) {
        if (status != null) {
          query = query.eq(JsonKeys.status, status.apiValue);
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

  Future<ContactUs> updateStatus(String id, ContactUsStatus status) async {
    final response = await client
        .from(tableName)
        .update({JsonKeys.status: status.apiValue})
        .eq(JsonKeys.id, id)
        .select();

    if (response.isEmpty) {
      throw ApiException(
        'Unable to update support request status. Please try again.',
      );
    }

    return ContactUs.fromJson(response.first);
  }

  Future<List<ContactUs>> updateStatusMany(
    List<String> ids,
    ContactUsStatus status,
  ) => updateMany({JsonKeys.status: status.apiValue}, ids);
}
