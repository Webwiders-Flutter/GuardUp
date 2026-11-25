import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '/core/constants/api/database_tables.dart';
import '/core/di/injection_container.dart';
import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '../../data/model/legal_content.model.dart';
import 'legal_content_event.dart';
import 'legal_content_state.dart';

class LegalContentBloc extends Bloc<LegalContentEvent, LegalContentState> {
  LegalContentBloc() : super(const LegalContentState()) {
    on<LegalContentRequested>(_onLegalContentRequested);
  }

  Future<void> _onLegalContentRequested(
    LegalContentRequested event,
    Emitter<LegalContentState> emit,
  ) async {
    // 1. Emit loading with static fake data for Skeletonizer
    final fallbackData = LegalContentModel.staticContent(event.contentType);
    emit(
      state.copyWith(
        contentState: ApiState.loading(previousData: fallbackData),
      ),
    );

    try {
      // 2. Resolve target role: from event, or from AuthBloc current state, or default to CUSTOMER
      UserRole targetRole = event.role ?? UserRole.customer;
      if (event.role == null && sl.isRegistered<AuthBloc>()) {
        targetRole = sl<AuthBloc>().state.sessionRole;
      }

      // 3. Query public.legal_content table
      final row = await Supabase.instance.client
          .from(DatabaseTables.legalContent)
          .select()
          .eq('role', targetRole.apiValue)
          .eq('content_type', event.contentType.apiValue)
          .eq('language', event.language)
          .order('last_published_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row != null && (row['content_html'] as String?)?.isNotEmpty == true) {
        final html = row['content_html'] as String;
        final updatedAtStr = row['updated_at'] ?? row['last_published_at'];
        final dynamicModel = LegalContentModel(
          id: (row['id'] as String?) ?? 'legal_${event.contentType.name}',
          contentType: event.contentType,
          title: event.contentType.name,
          contentHtml: html,
          clauses: const [],
          updatedAt: updatedAtStr != null
              ? DateTime.tryParse(updatedAtStr.toString())
              : null,
        );

        emit(state.copyWith(contentState: ApiState.success(dynamicModel)));
      } else {
        // Fallback to static content if no database record exists
        emit(state.copyWith(contentState: ApiState.success(fallbackData)));
      }
    } catch (e, st) {
      AppLogger.d('Error fetching legal content from Supabase: $e', tag: 'LegalContentBloc', error: e, stackTrace: st);
      emit(state.copyWith(contentState: ApiState.success(fallbackData)));
    }
  }
}
