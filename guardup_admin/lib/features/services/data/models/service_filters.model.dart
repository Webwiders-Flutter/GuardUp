import 'package:flutter/foundation.dart';

const _sentinel = Object();

@immutable
class ServiceFilters {
  final bool? isActive;

  const ServiceFilters({this.isActive});

  bool get hasActiveFilters => isActive != null;

  ServiceFilters copyWith({Object? isActive = _sentinel}) {
    return ServiceFilters(
      isActive: identical(isActive, _sentinel)
          ? this.isActive
          : isActive as bool?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceFilters &&
          runtimeType == other.runtimeType &&
          isActive == other.isActive;

  @override
  int get hashCode => isActive.hashCode;
}
