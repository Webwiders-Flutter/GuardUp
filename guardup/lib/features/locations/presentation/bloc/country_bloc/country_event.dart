import 'package:equatable/equatable.dart';

abstract class CountryEvent extends Equatable {
  const CountryEvent();

  @override
  List<Object?> get props => [];
}

class FetchCountries extends CountryEvent {
  final int limit;
  final bool isRefresh;
  final String? searchQuery;
  final bool? showInVideoHub;

  const FetchCountries({
    this.limit = 20,
    this.isRefresh = false,
    this.searchQuery,
    this.showInVideoHub,
  });

  @override
  List<Object?> get props => [limit, isRefresh, searchQuery, showInVideoHub];
}

class LoadMoreCountries extends CountryEvent {
  final String? searchQuery;
  final bool? showInVideoHub;

  const LoadMoreCountries({this.searchQuery, this.showInVideoHub});

  @override
  List<Object?> get props => [searchQuery, showInVideoHub];
}
