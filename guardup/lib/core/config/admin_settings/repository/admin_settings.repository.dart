import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/error/api_exception.dart';
import '/core/repositories/base.repository.dart';
import '../models/admin_settings.model.dart';

/// Repository managing platform global admin settings from `public.admin_settings`.
class AdminSettingsRepository extends BaseSupabaseRepository<AdminSettingsModel> {
  AdminSettingsRepository(SupabaseClient client)
      : super(
          client: client,
          tableName: DatabaseTables.adminSettings,
          fromJson: AdminSettingsModel.fromJson,
          entityName: 'admin settings',
        );

  /// Fetches the singleton platform admin settings record once.
  Future<AdminSettingsModel> getSettings() async {
    try {
      final response = await client
          .from(tableName)
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return fromJson(response);
      }
      return AdminSettingsModel.initial();
    } catch (e, st) {
      throw ApiException(
        'Failed to fetch admin settings: $e',
        raw: e,
        stackTrace: st,
      );
    }
  }

  /// Realtime stream emitting updated [AdminSettingsModel] whenever settings change in Supabase.
  Stream<AdminSettingsModel> streamSettings() {
    return client
        .from(tableName)
        .stream(primaryKey: ['id'])
        .map((records) {
          if (records.isEmpty) {
            return AdminSettingsModel.initial();
          }
          return fromJson(records.first);
        });
  }
}
