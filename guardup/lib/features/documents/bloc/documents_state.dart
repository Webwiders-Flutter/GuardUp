import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '/core/state/api_state.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import '../data/models/document_type.model.dart';
import '../data/models/user_document.model.dart';

class DocumentsState extends Equatable {
  const DocumentsState({
    this.loadStatus = const ApiState.initial(),
    this.submitStatus = const ApiState.initial(),
    this.types = const [],
    this.uploaded = const {},
    this.picked = const {},
  });

  final ApiState<void> loadStatus;
  final ApiState<void> submitStatus;
  final List<DocumentTypeModel> types;
  final Map<String, UserDocumentModel> uploaded;
  final Map<String, XFile> picked;

  bool get hasRejectedDoc =>
      uploaded.values.any((d) => d.status == DocumentStatus.rejected);

  /// True when every required document has either a local picked file or an
  /// uploaded document that is not rejected, and no rejected optional doc is
  /// left un-replaced.
  bool get canSubmit {
    for (final doc in types) {
      final remote = uploaded[doc.docKey];
      final hasLocal = picked.containsKey(doc.docKey);
      if (remote?.status == DocumentStatus.rejected && !hasLocal) {
        return false;
      }
      if (doc.isRequired && !hasLocal && remote == null) {
        return false;
      }
    }
    return true;
  }

  DocumentsState copyWith({
    ApiState<void>? loadStatus,
    ApiState<void>? submitStatus,
    List<DocumentTypeModel>? types,
    Map<String, UserDocumentModel>? uploaded,
    Map<String, XFile>? picked,
  }) {
    return DocumentsState(
      loadStatus: loadStatus ?? this.loadStatus,
      submitStatus: submitStatus ?? this.submitStatus,
      types: types ?? this.types,
      uploaded: uploaded ?? this.uploaded,
      picked: picked ?? this.picked,
    );
  }

  @override
  List<Object?> get props => [loadStatus, submitStatus, types, uploaded, picked];
}

