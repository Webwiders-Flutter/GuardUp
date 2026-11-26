import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class DocumentsEvent extends Equatable {
  const DocumentsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads active document types for the role and uploaded documents for owner.
final class DocumentsStarted extends DocumentsEvent {
  const DocumentsStarted();
}

/// Attaches a local picked [file] for document type [typeId].
final class DocumentPicked extends DocumentsEvent {
  const DocumentPicked(this.typeId, this.file);

  final String typeId;
  final XFile file;

  @override
  List<Object?> get props => [typeId, file];
}

/// Removes an un-uploaded local file selection for [typeId].
final class DocumentRemoved extends DocumentsEvent {
  const DocumentRemoved(this.typeId);

  final String typeId;

  @override
  List<Object?> get props => [typeId];
}

/// Uploads any picked files and optionally submits the application for review.
final class DocumentsSubmitted extends DocumentsEvent {
  const DocumentsSubmitted({this.submitApplication = true});

  final bool submitApplication;

  @override
  List<Object?> get props => [submitApplication];
}

