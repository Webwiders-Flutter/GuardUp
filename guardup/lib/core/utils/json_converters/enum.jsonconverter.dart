import 'package:freezed_annotation/freezed_annotation.dart';

/// A generic, case-insensitive, and fault-tolerant [JsonConverter] for non-nullable Enums.
///
/// Matches against:
/// 1. [Enum.name] (case-insensitive)
/// 2. [apiValue] or [value] property if present on the enum (case-insensitive)
/// 3. Normalized hyphens/underscores
///
/// Falls back to [defaultValue] if no match is found, preventing runtime crashes.
class SafeEnumConverter<E extends Enum> implements JsonConverter<E, dynamic> {
  final List<E> values;
  final E defaultValue;

  const SafeEnumConverter(this.values, {required this.defaultValue});

  @override
  E fromJson(dynamic json) {
    if (json == null) return defaultValue;
    return SafeEnumParser.parse<E>(json, values, defaultValue: defaultValue);
  }

  @override
  dynamic toJson(E object) => _getApiValue(object);
}

/// A generic, case-insensitive, and fault-tolerant [JsonConverter] for nullable Enums.
///
/// Returns `null` (or [defaultValue] if provided) when the value is missing or unrecognized.
class NullableEnumConverter<E extends Enum>
    implements JsonConverter<E?, dynamic> {
  final List<E> values;
  final E? defaultValue;

  const NullableEnumConverter(this.values, {this.defaultValue});

  @override
  E? fromJson(dynamic json) {
    if (json == null) return defaultValue;
    return SafeEnumParser.parseNullable<E>(
      json,
      values,
      defaultValue: defaultValue,
    );
  }

  @override
  dynamic toJson(E? object) => object == null ? null : _getApiValue(object);
}

/// Standalone parser utilities and extensions for safe enum resolution.
abstract final class SafeEnumParser {
  /// Safely resolves an enum from [json], falling back to [defaultValue].
  static E parse<E extends Enum>(
    dynamic json,
    List<E> values, {
    required E defaultValue,
  }) {
    return parseNullable<E>(json, values, defaultValue: defaultValue) ??
        defaultValue;
  }

  /// Safely resolves a nullable enum from [json].
  static E? parseNullable<E extends Enum>(
    dynamic json,
    List<E> values, {
    E? defaultValue,
  }) {
    if (json == null) return defaultValue;
    final raw = json.toString().trim();
    if (raw.isEmpty) return defaultValue;

    final upper = raw.toUpperCase();
    final normalized = upper.replaceAll('-', '_');

    // 1. Check direct match on enum.name (case-insensitive)
    for (final val in values) {
      final nameUpper = val.name.toUpperCase();
      if (nameUpper == upper || nameUpper == normalized) {
        return val;
      }
    }

    // 2. Check match on apiValue or value property if available
    for (final val in values) {
      try {
        final dynamic v = val;
        final apiVal = (v.apiValue ?? v.value)?.toString();
        if (apiVal != null) {
          final apiUpper = apiVal.toUpperCase();
          if (apiUpper == upper ||
              apiUpper.replaceAll('-', '_') == normalized) {
            return val;
          }
        }
      } catch (_) {}
    }

    return defaultValue;
  }
}

dynamic _getApiValue<E extends Enum>(E object) {
  try {
    final dynamic v = object;
    if (v.apiValue != null) return v.apiValue;
    if (v.value != null) return v.value;
  } catch (_) {}
  return object.name;
}

/// Extension on enum lists/iterables to allow `MyEnum.values.fromValue(json)`.
extension SafeEnumIterableExtension<E extends Enum> on Iterable<E> {
  E? fromValue(dynamic value, {E? defaultValue}) {
    return SafeEnumParser.parseNullable<E>(
      value,
      toList(),
      defaultValue: defaultValue,
    );
  }

  E parse(dynamic value, {required E defaultValue}) {
    return SafeEnumParser.parse<E>(value, toList(), defaultValue: defaultValue);
  }
}
