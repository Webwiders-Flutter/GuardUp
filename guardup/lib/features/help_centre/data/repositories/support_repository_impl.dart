import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:guardup/core/utils/app_logs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/error_keys.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/support_repository.dart';
import '../models/ticket_model.dart';

class SupportRepositoryImpl implements SupportRepository {
  final SupabaseClient _supabaseClient;
  final FileUploadService _fileUploadService;

  SupportRepositoryImpl(this._supabaseClient, this._fileUploadService);

  @override
  Future<Either<Failure, TicketEntity>> createTicket({
    required String category,
    required String subject,
    required String message,
    required List<File> attachments,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure(ErrorKeys.userNotAuthenticated));
      }

      final attachmentUrls = <String>[];
      for (var file in attachments) {
        final url = await _fileUploadService.uploadFile(
          file: file,
          bucket: 'support_attachments',
          folder: userId,
        );
        attachmentUrls.add(url);
      }

      final response = await _supabaseClient
          .from(SupabaseTables.supportTickets)
          .insert({
            'user_id': userId,
            'category': category,
            'subject': subject,
            'message': message,
            'attachment_urls': attachmentUrls,
          })
          .select()
          .single();

      return Right(TicketModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TicketEntity>>> getMyTickets({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure(ErrorKeys.userNotAuthenticated));
      }

      final offset = (page - 1) * limit;

      final response = await _supabaseClient
          .from(SupabaseTables.supportTickets)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final tickets = (response as List)
          .map((json) => TicketModel.fromJson(json))
          .toList();
      return Right(tickets);
    } catch (e) {
      AppLogs.log("Error in getMyTickets: $e");
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TicketEntity>> getTicketById(String id) async {
    try {
      final response = await _supabaseClient
          .from(SupabaseTables.supportTickets)
          .select()
          .eq('id', id)
          .single();

      return Right(TicketModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TicketReplyEntity>>> getTicketReplies(
    String ticketId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(SupabaseTables.ticketReplies)
          .select('*, users!sender_id(name)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      final replies = (response as List)
          .map((json) => TicketReplyModel.fromJson(json))
          .toList();
      return Right(replies);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TicketReplyEntity>> addReply({
    required String ticketId,
    required String message,
    required List<File> attachments,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure(ErrorKeys.userNotAuthenticated));
      }

      final ticketData = await _supabaseClient
          .from(SupabaseTables.supportTickets)
          .select('status')
          .eq('id', ticketId)
          .maybeSingle();

      if (ticketData != null && ticketData['status'] == 'closed') {
        return const Left(
          ServerFailure("Cannot reply to a closed support ticket."),
        );
      }

      final attachmentUrls = <String>[];
      for (var file in attachments) {
        final url = await _fileUploadService.uploadFile(
          file: file,
          bucket: 'support_attachments',
          folder: '$userId/replies',
        );
        attachmentUrls.add(url);
      }

      final response = await _supabaseClient
          .from(SupabaseTables.ticketReplies)
          .insert({
            'ticket_id': ticketId,
            'sender_id': userId,
            'message': message,
            'attachment_urls': attachmentUrls,
          })
          .select('*, users!sender_id(name)')
          .single();

      // Also update ticket's updated_at
      await _supabaseClient
          .from(SupabaseTables.supportTickets)
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', ticketId);

      return Right(TicketReplyModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  RealtimeChannel subscribeToReplies({
    required String ticketId,
    required void Function() onNewReply,
    void Function(TicketEntity updatedTicket)? onTicketUpdated,
  }) {
    final channel = _supabaseClient.channel('public:ticket_details:$ticketId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'ticket_replies',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'ticket_id',
        value: ticketId,
      ),
      callback: (payload) => onNewReply(),
    );

    if (onTicketUpdated != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'support_tickets',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: ticketId,
        ),
        callback: (payload) {
          if (payload.newRecord.isNotEmpty) {
            try {
              final updatedTicket = TicketModel.fromJson(payload.newRecord);
              onTicketUpdated(updatedTicket);
            } catch (e) {
              AppLogs.log("Error parsing updated ticket realtime payload: $e");
            }
          }
        },
      );
    }

    return channel.subscribe();
  }
}
