import 'package:equatable/equatable.dart';

sealed class CompanyDetailsEvent extends Equatable {
  const CompanyDetailsEvent();

  @override
  List<Object?> get props => [];
}

final class CompanyDetailsStarted extends CompanyDetailsEvent {
  const CompanyDetailsStarted();
}

final class CompanyDetailsRefreshed extends CompanyDetailsEvent {
  const CompanyDetailsRefreshed();
}
