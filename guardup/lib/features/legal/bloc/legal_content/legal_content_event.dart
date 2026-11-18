import 'package:equatable/equatable.dart';

import '/features/auth/data/enum/user_role.enum.dart';
import '../../data/enum/content_type.enum.dart';

abstract class LegalContentEvent extends Equatable {
  const LegalContentEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to load content for a specific [ContentType] and [UserRole].
class LegalContentRequested extends LegalContentEvent {
  final ContentType contentType;
  final UserRole? role;
  final String language;
  final bool forceRefresh;

  const LegalContentRequested(
    this.contentType, {
    this.role, 
    this.language = 'en',
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [contentType, role, language, forceRefresh];
}
