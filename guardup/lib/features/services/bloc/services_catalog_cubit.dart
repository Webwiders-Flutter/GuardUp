import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/error/api_exception.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '../data/models/service.model.dart';
import '../data/repositories/services.repository.dart';

/// App-wide cache of the active services (`public.services`).
///
/// Loaded once when the app starts (`..load()` in `App`); screens read
/// `state.dataOrNull`. A failed load keeps the previous list.
class ServicesCatalogCubit extends Cubit<ApiState<List<ServiceModel>>> {
  ServicesCatalogCubit(this._repository) : super(const ApiState.initial());

  final ServicesRepository _repository;

  /// Loads the active services. Without [force], does nothing while a load is
  /// running or once the list has loaded.
  Future<void> load({bool force = false}) async {
    if (state.isLoading) return;
    if (!force && state.isSuccess) return;

    final previous = state.dataOrNull;
    emit(ApiState.loading(previousData: previous));
    try {
      final services = await asyncHandler(_repository.getActive);
      emit(ApiState.success(services));
    } on ApiException catch (e) {
      emit(ApiState.failure(e.message, error: e, previousData: previous));
    }
  }
}
