import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/error/api_exception.dart';
import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '/features/auth/data/model/user_account_request.model.dart';
import '/features/auth/domain/repositories/user_repository.dart';
import '/features/body_guard/data/repositories/bodyguard.repository.dart';
import '/shared/models/record_owner.model.dart';
import '../data/models/user_document.model.dart';
import '../data/repositories/document_types.repository.dart';
import '../data/repositories/user_documents.repository.dart';
import 'documents_event.dart';
import 'documents_state.dart';

export 'documents_event.dart';
export 'documents_state.dart';

/// Manages fetching document requirements, tracking local picks, uploading
/// compliance files, and submitting applications for review.
class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  DocumentsBloc({
    required this.typesRepository,
    required this.documentsRepository,
    required this.userRepository,
    required this.bodyguardRepository,
    required this.owner,
    required this.role,
    required this.getCurrentUserId,
    this.onAccountSubmitted,
  }) : super(const DocumentsState()) {
    on<DocumentsStarted>(_onStarted, transformer: restartable());
    on<DocumentPicked>(_onPicked);
    on<DocumentRemoved>(_onRemoved);
    on<DocumentsSubmitted>(_onSubmitted);
  }

  final DocumentTypesRepository typesRepository;
  final UserDocumentsRepository documentsRepository;
  final UserRepository userRepository;
  final BodyguardRepository bodyguardRepository;
  final RecordOwner owner;
  final UserRole role;
  final String? Function() getCurrentUserId;
  final void Function()? onAccountSubmitted;

  Future<void> _onStarted(
    DocumentsStarted event,
    Emitter<DocumentsState> emit,
  ) async {
    emit(state.copyWith(loadStatus: const ApiState.loading()));

    try {
      final types = await asyncHandler(
        () => typesRepository.getActiveFor(role),
      );
      final docs = owner.id.isNotEmpty
          ? await asyncHandler(() => documentsRepository.getFor(owner))
          : const <UserDocumentModel>[];

      final uploadedMap = <String, UserDocumentModel>{
        for (final doc in docs) doc.documentTypeId: doc,
      };

      emit(
        state.copyWith(
          types: types,
          uploaded: uploadedMap,
          loadStatus: const ApiState.success(null),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          loadStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }

  void _onPicked(
    DocumentPicked event,
    Emitter<DocumentsState> emit,
  ) {
    final nextPicked = Map.of(state.picked)..[event.typeId] = event.file;
    emit(state.copyWith(picked: nextPicked));
  }

  void _onRemoved(
    DocumentRemoved event,
    Emitter<DocumentsState> emit,
  ) {
    final nextPicked = Map.of(state.picked)..remove(event.typeId);
    emit(state.copyWith(picked: nextPicked));
  }

  Future<void> _onSubmitted(
    DocumentsSubmitted event,
    Emitter<DocumentsState> emit,
  ) async {
    if (owner.id.isEmpty) {
      emit(
        state.copyWith(
          submitStatus: const ApiState.failure(
            'Your session has expired. Please sign in again.',
          ),
        ),
      );
      return;
    }

    final storageUserId = switch (owner) {
      AccountOwner(:final id) => id,
      ManagedBodyguardOwner() => getCurrentUserId() ?? '',
    };

    if (storageUserId.isEmpty) {
      emit(
        state.copyWith(
          submitStatus: const ApiState.failure(
            'Your session has expired. Please sign in again.',
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(submitStatus: const ApiState.loading()));

    final nextUploaded = Map.of(state.uploaded);
    String? uploadedLogoUrl;

    try {
      for (final entry in state.picked.entries) {
        final type = state.types.firstWhere(
          (t) => t.docKey == entry.key || t.id == entry.key,
          orElse: () => state.types.first,
        );

        final uploadedDoc = await asyncHandler(
          () => documentsRepository.upload(
            storageUserId: storageUserId,
            owner: owner,
            type: type,
            file: entry.value,
          ),
        );

        nextUploaded[uploadedDoc.documentTypeId] = uploadedDoc;

        if (owner is AccountOwner &&
            role == UserRole.company &&
            type.allowCrop) {
          uploadedLogoUrl = uploadedDoc.fileUrl;
        }
      }

      if (uploadedLogoUrl != null && uploadedLogoUrl.isNotEmpty) {
        try {
          await userRepository.updateAccount(
            owner.id,
            UserAccountRequest(profileImageUrl: uploadedLogoUrl),
          );
        } catch (e, st) {
          AppLogger.d(
            'Failed to sync company logo URL: $e',
            tag: 'DocumentsBloc',
            error: e,
            stackTrace: st,
          );
        }
      }

      if (event.submitApplication) {
        switch (owner) {
          case AccountOwner(:final id):
            if (state.picked.isEmpty) {
              await asyncHandler(() => userRepository.submitForReview(id));
            }
          case ManagedBodyguardOwner(:final id):
            await asyncHandler(() => bodyguardRepository.submitForReview(id));
        }
      }

      if (owner is AccountOwner) {
        onAccountSubmitted?.call();
      }

      emit(
        state.copyWith(
          uploaded: nextUploaded,
          picked: const {},
          submitStatus: const ApiState.success(null),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          uploaded: nextUploaded,
          submitStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }
}
