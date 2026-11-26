import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/repositories/base.repository.dart';
import '../model/contact_us.model.dart';
import '../model/contact_us_request.model.dart';

/// `public.contact_us`: User and principal support submissions.
final class ContactUsRepository extends BaseSupabaseRepository<ContactUsModel> {
  ContactUsRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.contactUs,
        fromJson: ContactUsModel.fromJson,
        entityName: 'contact inquiry',
        searchFields: const [
          JsonKeys.fullName,
          JsonKeys.email,
          JsonKeys.message,
        ],
        primarySortColumn: JsonKeys.createdAt,
        primarySortAscending: false,
      );

  /// Submits an inquiry to `public.contact_us`.
  Future<void> submit(ContactUsRequest request) async {
    await client.from(tableName).insert(request.toJson());
  }
}
