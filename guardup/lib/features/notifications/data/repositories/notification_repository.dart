import 'package:guardup/core/utils/app_logs.dart';
import 'package:guardup/features/notifications/data/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final SupabaseClient supabase;

  NotificationRepository({required this.supabase});

  Future<List<NotificationModel>> fetchNotifications(
    String userId, {
    int page = 0,
    int limit = 10,
  }) async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      AppLogs.debugPrint('Supabase Notifications Response: $response');

      return (response as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    } catch (e, stacktrace) {
      AppLogs.debugPrint('Failed to fetch notifications: $e\n$stacktrace');
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await supabase.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  Future<void> clearAll(String userId) async {
    try {
      await supabase.from('notifications').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to clear all notifications: $e');
    }
  }
}
