import 'package:equatable/equatable.dart';
import 'package:guardup/features/auth/domain/entities/user_entity.dart';

abstract class BlockedUsersState extends Equatable {
  const BlockedUsersState();

  @override
  List<Object?> get props => [];
}

class BlockedUsersInitial extends BlockedUsersState {}

class BlockedUsersLoading extends BlockedUsersState {}

class BlockedUsersLoaded extends BlockedUsersState {
  final List<UserEntity> users;
  final bool hasReachedMax;
  final int currentPage;

  const BlockedUsersLoaded({
    required this.users,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  BlockedUsersLoaded copyWith({
    List<UserEntity>? users,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return BlockedUsersLoaded(
      users: users ?? this.users,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [users, hasReachedMax, currentPage];
}

class BlockedUsersError extends BlockedUsersState {
  final String message;

  const BlockedUsersError(this.message);

  @override
  List<Object?> get props => [message];
}

class UnblockingInProgress extends BlockedUsersState {
  final String userId;

  const UnblockingInProgress(this.userId);

  @override
  List<Object?> get props => [userId];
}
