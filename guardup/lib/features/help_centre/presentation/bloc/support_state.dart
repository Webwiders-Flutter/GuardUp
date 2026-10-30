import 'package:equatable/equatable.dart';
import '../../domain/entities/ticket_entity.dart';

abstract class SupportState extends Equatable {
  const SupportState();
  @override
  List<Object?> get props => [];
}

class SupportInitial extends SupportState {}

class SupportLoading extends SupportState {}

class SupportActionLoading extends SupportState {}

class SupportSuccess extends SupportState {
  final String? message;
  final TicketEntity? ticket;
  const SupportSuccess({this.message, this.ticket});
  @override
  List<Object?> get props => [message, ticket];
}

class MyTicketsLoaded extends SupportState {
  final List<TicketEntity> tickets;
  final bool hasReachedMax;
  final int currentPage;

  const MyTicketsLoaded({
    required this.tickets,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  MyTicketsLoaded copyWith({
    List<TicketEntity>? tickets,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return MyTicketsLoaded(
      tickets: tickets ?? this.tickets,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [tickets, hasReachedMax, currentPage];
}

class AllTicketsLoaded extends SupportState {
  final List<TicketEntity> tickets;
  const AllTicketsLoaded(this.tickets);
  @override
  List<Object?> get props => [tickets];
}

class TicketRepliesLoaded extends SupportState {
  final List<TicketReplyEntity> replies;
  const TicketRepliesLoaded(this.replies);
  @override
  List<Object?> get props => [replies];
}

class SupportError extends SupportState {
  final String message;
  const SupportError(this.message);
  @override
  List<Object?> get props => [message];
}
