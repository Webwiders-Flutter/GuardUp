import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:guardup/core/utils/extensions/datetime_extensions.dart';
import 'package:guardup/core/utils/extensions/numeral_extensions.dart';

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String userId;
  final DateTime createdAt;
  final Map<String, dynamic> otherData;
  final String type;
  final String? titleEn;
  final String? titleAr;
  final String? bodyEn;
  final String? bodyAr;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
    required this.createdAt,
    required this.otherData,
    this.type = '',
    this.titleEn,
    this.titleAr,
    this.bodyEn,
    this.bodyAr,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      createdAt:
          json['created_at']?.toString().parseNullableLocal() ?? DateTime.now(),
      otherData: () {
        if (json['metadata'] is Map) {
          return Map<String, dynamic>.from(json['metadata']);
        } else if (json['metadata'] is String) {
          try {
            return Map<String, dynamic>.from(jsonDecode(json['metadata']));
          } catch (_) {}
        }
        if (json['otherData'] is Map) {
          return Map<String, dynamic>.from(json['otherData']);
        }
        return <String, dynamic>{};
      }(),
      type: json['type'] as String? ?? '',
      titleEn: json['title_en'] as String?,
      titleAr: json['title_ar'] as String?,
      bodyEn: json['body_en'] as String?,
      bodyAr: json['body_ar'] as String?,
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? userId,
    DateTime? createdAt,
    Map<String, dynamic>? otherData,
    String? type,
    String? titleEn,
    String? titleAr,
    String? bodyEn,
    String? bodyAr,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      otherData: otherData ?? this.otherData,
      type: type ?? this.type,
      titleEn: titleEn ?? this.titleEn,
      titleAr: titleAr ?? this.titleAr,
      bodyEn: bodyEn ?? this.bodyEn,
      bodyAr: bodyAr ?? this.bodyAr,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    userId,
    createdAt,
    otherData,
    type,
    titleEn,
    titleAr,
    bodyEn,
    bodyAr,
    isRead,
  ];

  String displayTitle(String locale) {
    String text = title;
    if (locale == 'ar' && titleAr != null && titleAr!.isNotEmpty) {
      text = titleAr!;
    } else if (locale == 'en' && titleEn != null && titleEn!.isNotEmpty) {
      text = titleEn!;
    }
    return text.localizeWithLocale(locale);
  }

  String displayBody(String locale) {
    String text = body;
    if (locale == 'ar' && bodyAr != null && bodyAr!.isNotEmpty) {
      text = bodyAr!;
    } else if (locale == 'en' && bodyEn != null && bodyEn!.isNotEmpty) {
      text = bodyEn!;
    }
    return text.localizeWithLocale(locale);
  }
}
