import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '../../data/model/company.model.dart';
import '../../data/repositories/company.repository.dart';
import 'company_details_event.dart';
import 'company_details_state.dart';

export 'company_details_event.dart';
export 'company_details_state.dart';

/// Loads full details (joined verified documents, bio) for a company by [companyId],
/// optionally seeded with a [preview] model from the listing.
class CompanyDetailsBloc
    extends Bloc<CompanyDetailsEvent, CompanyDetailsState> {
  CompanyDetailsBloc(
    this._repository, {
    required this.companyId,
    CompanyModel? preview,
  }) : super(CompanyDetailsState(company: preview)) {
    on<CompanyDetailsStarted>(
      (_, emit) => _load(emit),
      transformer: restartable(),
    );
    on<CompanyDetailsRefreshed>(
      (_, emit) => _load(emit),
      transformer: restartable(),
    );
  }

  final CompanyRepository _repository;
  final String companyId;

  Future<void> _load(Emitter<CompanyDetailsState> emit) async {
    if (companyId.isEmpty ||
        companyId.startsWith('00000000-0000-0000-0000-')) {
      if (state.company == null) {
        emit(
          state.copyWith(
            status: const ApiState.failure('Company not found.'),
          ),
        );
      } else {
        emit(state.copyWith(status: ApiState.success(state.company!)));
      }
      return;
    }

    emit(state.copyWith(status: ApiState.loading(previousData: state.company)));

    try {
      final detailed = await asyncHandler(
        () => _repository.getDetails(companyId),
      );
      emit(
        CompanyDetailsState(
          company: detailed,
          status: ApiState.success(detailed),
        ),
      );
    } catch (e) {
      if (state.company != null) {
        emit(state.copyWith(status: ApiState.success(state.company!)));
      } else {
        emit(state.copyWith(status: ApiState.failure(e.toString())));
      }
    }
  }
}
