import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/support_repository.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  final SupportRepository _supportRepository;
  static const int _limit = 20;
  RealtimeChannel? _repliesChannel;

  SupportCubit(this._supportRepository) : super(SupportInitial());

  Future<void> createTicket({
    required String category,
    required String subject,
    required String message,
    required List<File> attachments,
  }) async {
    emit(SupportActionLoading());
    final result = await _supportRepository.createTicket(
      category: category,
      subject: subject,
      message: message,
      attachments: attachments,
    );
    result.fold(
      (failure) => emit(SupportError(failure.message)),
      (ticket) => emit(
        SupportSuccess(message: 'Ticket created successfully', ticket: ticket),
      ),
    );
  }

  Future<void> getMyTickets() async {
    emit(SupportLoading());
    final result = await _supportRepository.getMyTickets(
      page: 1,
      limit: _limit,
    );
    result.fold(
      (failure) => emit(SupportError(failure.message)),
      (tickets) => emit(
        MyTicketsLoaded(
          tickets: tickets,
          hasReachedMax: tickets.length < _limit,
          currentPage: 1,
        ),
      ),
    );
  }

  void updateTicketLocally(TicketEntity updatedTicket) {
    if (state is MyTicketsLoaded) {
      final currentState = state as MyTicketsLoaded;
      final updatedTickets = currentState.tickets.map((t) {
        return t.id == updatedTicket.id ? updatedTicket : t;
      }).toList();
      emit(currentState.copyWith(tickets: updatedTickets));
    }
  }

  void insertTicket(TicketEntity ticket) {
    if (state is MyTicketsLoaded) {
      final currentState = state as MyTicketsLoaded;
      if (!currentState.tickets.any((t) => t.id == ticket.id)) {
        emit(currentState.copyWith(tickets: [ticket, ...currentState.tickets]));
      }
    } else {
      emit(
        MyTicketsLoaded(tickets: [ticket], hasReachedMax: true, currentPage: 1),
      );
    }
  }

  bool _isFetchingMore = false;

  Future<void> loadMoreMyTickets() async {
    if (state is! MyTicketsLoaded || _isFetchingMore) return;

    final currentState = state as MyTicketsLoaded;
    if (currentState.hasReachedMax) return;

    _isFetchingMore = true;
    final nextPage = currentState.currentPage + 1;

    final result = await _supportRepository.getMyTickets(
      page: nextPage,
      limit: _limit,
    );

    result.fold((failure) => null, (newTickets) {
      emit(
        newTickets.isEmpty
            ? currentState.copyWith(hasReachedMax: true)
            : currentState.copyWith(
                tickets: List.of(currentState.tickets)..addAll(newTickets),
                hasReachedMax: newTickets.length < _limit,
                currentPage: nextPage,
              ),
      );
    });
    _isFetchingMore = false;
  }

  Future<void> getTicketReplies(
    String ticketId, {
    bool showLoading = true,
  }) async {
    if (showLoading) emit(SupportLoading());
    final result = await _supportRepository.getTicketReplies(ticketId);
    result.fold(
      (failure) => emit(SupportError(failure.message)),
      (replies) => emit(TicketRepliesLoaded(replies)),
    );
  }

  void subscribeToReplies(
    String ticketId, {
    void Function(TicketEntity updatedTicket)? onTicketUpdated,
  }) {
    unsubscribeFromReplies();
    _repliesChannel = _supportRepository.subscribeToReplies(
      ticketId: ticketId,
      onNewReply: () => getTicketReplies(ticketId, showLoading: false),
      onTicketUpdated: onTicketUpdated,
    );
  }

  void unsubscribeFromReplies() {
    _repliesChannel?.unsubscribe();
    _repliesChannel = null;
  }

  Future<void> addReply({
    required String ticketId,
    required String message,
    required List<File> attachments,
  }) async {
    emit(SupportActionLoading());
    final result = await _supportRepository.addReply(
      ticketId: ticketId,
      message: message,
      attachments: attachments,
    );
    result.fold(
      (failure) => emit(SupportError(failure.message)),
      (_) => getTicketReplies(ticketId, showLoading: false),
    );
  }

  @override
  Future<void> close() {
    unsubscribeFromReplies();
    return super.close();
  }
}
