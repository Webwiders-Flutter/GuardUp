import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '../../data/model/service_item.model.dart';

/// Cubit managing the globally cached active services from `public.services`.
/// Fetched once at app start / splash screen and shared across Customer and Bodyguard.
class ServicesCubit extends Cubit<List<ServiceItemModel>> {
  final SupabaseClient _supabase;
  bool _isLoading = false;

  ServicesCubit([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client,
        super(const []);

  bool get isLoading => _isLoading;

  /// Loads active services from `public.services`.
  /// If services are already loaded and [forceRefresh] is false, returns existing cached list immediately.
  Future<List<ServiceItemModel>> loadServices({bool forceRefresh = false}) async {
    if (!forceRefresh && state.isNotEmpty) {
      return state;
    }
    if (_isLoading) return state;
    _isLoading = true;

    try {
      final rows = await _supabase
          .from(DatabaseTables.services)
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final services = (rows as List<dynamic>)
          .map((r) => ServiceItemModel.fromJson(r as Map<String, dynamic>))
          .toList();

      emit(services);
      return services;
    } catch (e, stack) {
      debugPrint('Error loading services in ServicesCubit: $e\n$stack');
      return state;
    } finally {
      _isLoading = false;
    }
  }
}
