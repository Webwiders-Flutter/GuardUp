enum NotificationType {
  supportTicket('support_ticket'),
  ticket('ticket'),
  general('general'),
  unknown('unknown');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => NotificationType.unknown,
    );
  }
}
