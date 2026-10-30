import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../entities/ticket_entity.dart';

abstract class SupportRepository {
  Future<Either<Failure, TicketEntity>> createTicket({
    required String category,
    required String subject,
    required String message,
    required List<File> attachments,
  });

  Future<Either<Failure, List<TicketEntity>>> getMyTickets({
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, TicketEntity>> getTicketById(String id);

  Future<Either<Failure, List<TicketReplyEntity>>> getTicketReplies(
    String ticketId,
  );

  Future<Either<Failure, TicketReplyEntity>> addReply({
    required String ticketId,
    required String message,
    required List<File> attachments,
  });

  RealtimeChannel subscribeToReplies({
    required String ticketId,
    required void Function() onNewReply,
    void Function(TicketEntity updatedTicket)? onTicketUpdated,
  });
}
