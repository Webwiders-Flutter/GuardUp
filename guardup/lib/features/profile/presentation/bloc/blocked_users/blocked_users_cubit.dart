import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_blocked_users_usecase.dart';
import '../../../domain/usecases/unblock_user_usecase.dart';
import 'blocked_users_state.dart';

class BlockedUsersCubit extends Cubit<BlockedUsersState> {
  final GetBlockedUsersUseCase getBlockedUsersUseCase;
  final UnblockUserUseCase unblockUserUseCase;
  static const int _limit = 20;

  BlockedUsersCubit({
    required this.getBlockedUsersUseCase,
    required this.unblockUserUseCase,
  }) : super(BlockedUsersInitial());

  Future<void> fetchBlockedUsers() async {
    emit(BlockedUsersLoading());
    final result = await getBlockedUsersUseCase(page: 1, limit: _limit);

    result.fold(
      (failure) => emit(BlockedUsersError(failure.message)),
      (users) => emit(
        BlockedUsersLoaded(
          users: users,
          hasReachedMax: users.length < _limit,
          currentPage: 1,
        ),
      ),
    );
  }

  bool _isFetchingMore = false;

  Future<void> loadMore() async {
    if (state is! BlockedUsersLoaded || _isFetchingMore) return;

    final currentState = state as BlockedUsersLoaded;
    if (currentState.hasReachedMax) return;

    _isFetchingMore = true;
    final nextPage = currentState.currentPage + 1;

    final result = await getBlockedUsersUseCase(page: nextPage, limit: _limit);

    result.fold(
      (failure) => null, // Silently fail or handle error
      (newUsers) {
        emit(
          newUsers.isEmpty
              ? currentState.copyWith(hasReachedMax: true)
              : currentState.copyWith(
                  users: List.of(currentState.users)..addAll(newUsers),
                  hasReachedMax: newUsers.length < _limit,
                  currentPage: nextPage,
                ),
        );
      },
    );
    _isFetchingMore = false;
  }

  Future<void> unblockUser(String userId) async {
    final currentState = state;
    if (currentState is! BlockedUsersLoaded) return;

    final result = await unblockUserUseCase(userId);

    result.fold((failure) => emit(BlockedUsersError(failure.message)), (_) {
      final updatedUsers = currentState.users
          .where((u) => u.id != userId)
          .toList();
      emit(currentState.copyWith(users: updatedUsers));
    });
  }
}
