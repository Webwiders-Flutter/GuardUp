part of 'content_cubit.dart';

abstract class ContentState {}

class ContentInitial extends ContentState {}

class ContentLoading extends ContentState {}

class ContentLoaded extends ContentState {
  final String htmlData;

  ContentLoaded(this.htmlData);
}

class ContentError extends ContentState {
  final String message;

  ContentError(this.message);
}
