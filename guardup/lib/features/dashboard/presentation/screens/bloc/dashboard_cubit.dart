import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardState extends Equatable {
  final int currentIndex;
  final bool isFullScreen;

  const DashboardState({required this.currentIndex, this.isFullScreen = false});

  DashboardState copyWith({int? currentIndex, bool? isFullScreen}) {
    return DashboardState(
      currentIndex: currentIndex ?? this.currentIndex,
      isFullScreen: isFullScreen ?? this.isFullScreen,
    );
  }

  @override
  List<Object?> get props => [currentIndex, isFullScreen];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState(currentIndex: 0));

  void changeTab(int index) {
    emit(state.copyWith(currentIndex: index, isFullScreen: false));
  }

  void setFullScreen(bool isFullScreen) {
    emit(state.copyWith(isFullScreen: isFullScreen));
  }
}
