import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/repositories/base.repository.dart';
import '../models/notification.model.dart';
import '../models/notification_filters.model.dart';

/// Repository for managing user notifications in Supabase `public.notifications`.
final class NotificationRepository
    extends BaseSupabaseRepository<NotificationModel> {
  NotificationRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.notifications,
        fromJson: NotificationModel.fromJson,
        entityName: 'notification',
        searchFields: const [
          JsonKeys.title,
          JsonKeys.titleHi,
          JsonKeys.body,
          JsonKeys.bodyHi,
        ],
        primarySortColumn: JsonKeys.createdAt,
        primarySortAscending: false,
      );

  @override
  Future<({List<NotificationModel> data, int total})> getPaginated({
    required int page,
    required int pageSize,
    NotificationFilters? filters,
    String? search,
    bool? isActive,
    CustomQueryBuilder? customQuery,
  }) {
    return super.getPaginated(
      page: page,
      pageSize: pageSize,
      search: search,
      isActive: isActive,
      customQuery: (query) {
        if (filters?.type != null) {
          query = query.eq(JsonKeys.type, filters!.type!.apiValue);
        }
        if (filters?.isRead != null) {
          query = query.eq(JsonKeys.isRead, filters!.isRead!);
        }
        if (filters?.userId != null && filters!.userId!.isNotEmpty) {
          query = query.eq(JsonKeys.userId, filters.userId!);
        }
        if (customQuery != null) {
          query = customQuery(query);
        }
        return query;
      },
    );
  }

  /// Returns total count of unread notifications for [userId].
  Future<int> getUnreadCount(String userId) async {
    final response = await client
        .from(tableName)
        .select(JsonKeys.id)
        .eq(JsonKeys.userId, userId)
        .eq(JsonKeys.isRead, false)
        .count(CountOption.exact);

    return response.count;
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead({required String notificationId}) async {
    await client
        .from(tableName)
        .update({
          JsonKeys.isRead: true,
          JsonKeys.readAt: DateTime.now().toIso8601String(),
        })
        .eq(JsonKeys.id, notificationId);
  }

  /// Marks all unread notifications for [userId] as read.
  Future<void> markAllAsRead(String userId) async {
    await client
        .from(tableName)
        .update({
          JsonKeys.isRead: true,
          JsonKeys.readAt: DateTime.now().toIso8601String(),
        })
        .eq(JsonKeys.userId, userId)
        .eq(JsonKeys.isRead, false);
  }

  /// Real-time stream of notifications for [userId].
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return client
        .from(tableName)
        .stream(primaryKey: [JsonKeys.id])
        .eq(JsonKeys.userId, userId)
        .order(JsonKeys.createdAt, ascending: false)
        .map((rows) => rows.map((json) => fromJson(json)).toList());
  }
}
