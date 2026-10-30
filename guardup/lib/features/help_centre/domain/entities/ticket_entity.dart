import 'package:equatable/equatable.dart';

enum TicketStatus {
  pending,
  inProgress,
  closed;

  static TicketStatus fromString(String status) {
    switch (status) {
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case TicketStatus.inProgress:
        return 'in_progress';
      case TicketStatus.closed:
        return 'closed';
      default:
        return 'pending';
    }
  }
}

class TicketEntity extends Equatable {
  final String id;
  final String userId;
  final String category;
  final String subject;
  final String message;
  final TicketStatus status;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userName; // For admin view

  const TicketEntity({
    required this.id,
    required this.userId,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    required this.attachmentUrls,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    category,
    subject,
    message,
    status,
    attachmentUrls,
    createdAt,
    updatedAt,
    userName,
  ];
}

class TicketReplyEntity extends Equatable {
  final String id;
  final String ticketId;
  final String senderId;
  final String message;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final String? senderName;

  const TicketReplyEntity({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.message,
    required this.attachmentUrls,
    required this.createdAt,
    this.senderName,
  });

  @override
  List<Object?> get props => [
    id,
    ticketId,
    senderId,
    message,
    attachmentUrls,
    createdAt,
    senderName,
  ];
}
