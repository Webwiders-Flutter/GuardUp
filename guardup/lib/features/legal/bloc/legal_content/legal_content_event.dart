import 'package:equatable/equatable.dart';

import '../../data/enum/content_type.enum.dart';

abstract class LegalContentEvent extends Equatable {
  const LegalContentEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to load content for a specific [ContentType].
class LegalContentRequested extends LegalContentEvent {
  final ContentType contentType;
  final bool forceRefresh;

  const LegalContentRequested(this.contentType, {this.forceRefresh = false});

  @override
  List<Object?> get props => [contentType, forceRefresh];
}
