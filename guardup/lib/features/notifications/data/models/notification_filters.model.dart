import '../enums/notification_type.enum.dart';

const _sentinel = Object();

/// Immutable filter criteria for querying notifications in the app.
class NotificationFilters {
  final NotificationCategory? category;
  final NotificationType? type;
  final bool? isRead;
  final String? userId;

  const NotificationFilters({
    this.category,
    this.type,
    this.isRead,
    this.userId,
  });

  static const NotificationFilters empty = NotificationFilters();

  /// Whether any filter criteria is active.
  bool get hasFilters =>
      category != null ||
      type != null ||
      isRead != null ||
      (userId != null && userId!.trim().isNotEmpty);

  /// Whether no filter is currently active.
  bool get isEmpty => !hasFilters;

  /// Returns a new instance with cleared filters.
  NotificationFilters clear() => const NotificationFilters();

  /// Creates a copy with the given fields replaced.
  NotificationFilters copyWith({
    Object? category = _sentinel,
    Object? type = _sentinel,
    Object? isRead = _sentinel,
    Object? userId = _sentinel,
  }) {
    return NotificationFilters(
      category:
          identical(category, _sentinel)
              ? this.category
              : category as NotificationCategory?,
      type: identical(type, _sentinel) ? this.type : type as NotificationType?,
      isRead: identical(isRead, _sentinel) ? this.isRead : isRead as bool?,
      userId: identical(userId, _sentinel) ? this.userId : userId as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationFilters &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          type == other.type &&
          isRead == other.isRead &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(category, type, isRead, userId);

  @override
  String toString() =>
      'NotificationFilters(category: $category, type: $type, isRead: $isRead, userId: $userId)';
}
