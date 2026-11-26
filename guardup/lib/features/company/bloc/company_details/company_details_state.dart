import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '../../data/model/company.model.dart';

class CompanyDetailsState extends Equatable {
  const CompanyDetailsState({
    this.status = const ApiState.initial(),
    this.company,
  });

  final ApiState<CompanyModel> status;

  /// Latest loaded or preview company model so the UI can render immediately
  /// while full joined details (bio, verified documents) load in the background.
  final CompanyModel? company;

  bool get isLoading => status.isLoading && company == null;
  bool get isRefreshing => status.isLoading && company != null;
  bool get isFailure => status.isFailure && company == null;

  CompanyDetailsState copyWith({
    ApiState<CompanyModel>? status,
    CompanyModel? company,
  }) {
    return CompanyDetailsState(
      status: status ?? this.status,
      company: company ?? this.company,
    );
  }

  @override
  List<Object?> get props => [status, company];
}
