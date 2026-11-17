import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/notification_type.enum.dart';

part 'notification.model.freezed.dart';
part 'notification.model.g.dart';

@freezed
sealed class NotificationModel with _$NotificationModel {
  const NotificationModel._();

  const factory NotificationModel({
    required String id,
    required String userId,
    required NotificationType type,
    required String title,
    String? titleHi,
    required String body,
    String? bodyHi,
    @Default({}) Map<String, dynamic> data,
    String? imageUrl,
    @Default(false) bool isRead,
    String? readAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  /// Helper to return localized title based on current language
  String displayTitle(bool isHindi) {
    if (isHindi && titleHi != null && titleHi!.trim().isNotEmpty) {
      return titleHi!;
    }
    return title;
  }

  /// Helper to return localized body based on current language
  String displayBody(bool isHindi) {
    if (isHindi && bodyHi != null && bodyHi!.trim().isNotEmpty) {
      return bodyHi!;
    }
    return body;
  }

  /// Factory providing realistic sample data for skeleton loading or previews.
  factory NotificationModel.fake({
    String id = 'fake-notification',
    String userId = 'fake-user-id',
    NotificationType type = NotificationType.tripCreated,
    String title = 'Trip Assigned Successfully',
    String? titleHi,
    String body = 'A new trip #TR-8823 has been assigned to your vehicle with scheduled pickup.',
    String? bodyHi,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    bool isRead = false,
    String? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      titleHi: titleHi,
      body: body,
      bodyHi: bodyHi,
      data: data,
      imageUrl: imageUrl,
      isRead: isRead,
      readAt: readAt,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// List of realistic fake notifications for skeleton loaders or previews.
  static List<NotificationModel> fakeList({int count = 6}) {
    final sampleData =
        <
          ({
            NotificationType type,
            String title,
            String body,
            bool isRead,
            Duration ago,
          })
        >[
          (
            type: NotificationType.tripCreated,
            title: 'New Trip Assigned',
            body: 'Trip #TR-8921 has been assigned to your vehicle for route Delhi to Jaipur.',
            isRead: false,
            ago: const Duration(minutes: 10),
          ),
          (
            type: NotificationType.documentApproved,
            title: 'Vehicle Registration Approved',
            body: 'Your RC document verification has been successfully approved by admin.',
            isRead: false,
            ago: const Duration(hours: 1),
          ),
          (
            type: NotificationType.paymentReceived,
            title: 'Advance Payment Credited',
            body: 'Advance payment of ₹15,000 for Trip #TR-8812 has been credited to your wallet.',
            isRead: true,
            ago: const Duration(hours: 3),
          ),
          (
            type: NotificationType.orderUpdated,
            title: 'Order Status Updated',
            body: 'Consignment delivery timestamp has been updated by the dispatch team.',
            isRead: true,
            ago: const Duration(hours: 6),
          ),
          (
            type: NotificationType.system,
            title: 'System Maintenance Scheduled',
            body: 'Platform maintenance scheduled tonight from 2:00 AM to 4:00 AM IST.',
            isRead: true,
            ago: const Duration(days: 1),
          ),
          (
            type: NotificationType.tripUpdated,
            title: 'Route Updated by Dispatcher',
            body: 'Route checkpoint added near toll plaza for trip #TR-8740.',
            isRead: true,
            ago: const Duration(days: 2),
          ),
        ];

    final now = DateTime.now();
    return List.generate(count, (index) {
      final sample = sampleData[index % sampleData.length];
      return NotificationModel.fake(
        id: 'fake-notification-$index',
        type: sample.type,
        title: sample.title,
        body: sample.body,
        isRead: sample.isRead,
        createdAt: now.subtract(sample.ago),
        updatedAt: now.subtract(sample.ago),
      );
    });
  }
}
