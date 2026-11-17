import '../enums/notification_type.enum.dart';

const _sentinel = Object();

/// Immutable filter criteria for querying notifications.
class NotificationFilters {
  final NotificationType? type;
  final bool? isRead;
  final String? userId;

  const NotificationFilters({this.type, this.isRead, this.userId});

  static const NotificationFilters empty = NotificationFilters();

  /// Whether any filter criteria is active.
  bool get hasFilters =>
      type != null ||
      isRead != null ||
      (userId != null && userId!.trim().isNotEmpty);

  /// Whether no filter is currently active.
  bool get isEmpty => !hasFilters;

  /// Returns a new instance with cleared filters.
  NotificationFilters clear() => const NotificationFilters();

  /// Creates a copy with the given fields replaced.
  /// Passing `null` explicitly resets that field.
  NotificationFilters copyWith({
    Object? type = _sentinel,
    Object? isRead = _sentinel,
    Object? userId = _sentinel,
  }) {
    return NotificationFilters(
      type: identical(type, _sentinel) ? this.type : type as NotificationType?,
      isRead: identical(isRead, _sentinel) ? this.isRead : isRead as bool?,
      userId: identical(userId, _sentinel) ? this.userId : userId as String?,
    );
  }

  /// Converts active filters into a map of query parameters.
  Map<String, dynamic> toMap() {
    return {
      if (type != null) 'type': type!.apiValue,
      if (isRead != null) 'is_read': isRead,
      if (userId != null && userId!.trim().isNotEmpty)
        'user_id': userId!.trim(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationFilters &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          isRead == other.isRead &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(type, isRead, userId);

  @override
  String toString() =>
      'NotificationFilters(type: $type, isRead: $isRead, userId: $userId)';
}
