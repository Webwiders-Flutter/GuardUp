import '../../domain/entities/ticket_entity.dart';

class TicketModel extends TicketEntity {
  const TicketModel({
    required super.id,
    required super.userId,
    required super.category,
    required super.subject,
    required super.message,
    required super.status,
    required super.attachmentUrls,
    required super.createdAt,
    required super.updatedAt,
    super.userName,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      userId: json['user_id'],
      category: json['category'],
      subject: json['subject'],
      message: json['message'],
      status: TicketStatus.fromString(json['status']),
      attachmentUrls: List<String>.from(json['attachment_urls'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userName: json['users']?['name'] ?? json['users']?['fullName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category': category,
      'subject': subject,
      'message': message,
      'status': status.toDbString(),
      'attachment_urls': attachmentUrls,
    };
  }
}

class TicketReplyModel extends TicketReplyEntity {
  const TicketReplyModel({
    required super.id,
    required super.ticketId,
    required super.senderId,
    required super.message,
    required super.attachmentUrls,
    required super.createdAt,
    super.senderName,
  });

  factory TicketReplyModel.fromJson(Map<String, dynamic> json) {
    return TicketReplyModel(
      id: json['id'],
      ticketId: json['ticket_id'],
      senderId: json['sender_id'],
      message: json['message'],
      attachmentUrls: List<String>.from(json['attachment_urls'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['users']?['name'] ?? json['users']?['fullName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'sender_id': senderId,
      'message': message,
      'attachment_urls': attachmentUrls,
    };
  }
}
