/// Generic helper for parsing Supabase/PostgREST embedded relations.
///
/// PostgREST can return embedded relations as:
/// - A JSON Object `Map<String, dynamic>` (for single relations / Many-to-One)
/// - A single-element JSON Array `[{...}]` (if the relation is resolved as a collection)
/// - An Array of Objects `[{...}, {...}]` (for One-to-Many relations)
/// - `null`
abstract final class EmbeddedParser {
  /// Safely parses an embedded object from [json].
  static T? parseObject<T>(
    dynamic json,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) {
      return fromJson(json);
    }
    if (json is Map) {
      return fromJson(Map<String, dynamic>.from(json));
    }
    if (json is List && json.isNotEmpty) {
      final first = json.first;
      if (first is Map<String, dynamic>) {
        return fromJson(first);
      }
      if (first is Map) {
        return fromJson(Map<String, dynamic>.from(first));
      }
    }
    return null;
  }

  /// Safely parses an embedded list of objects from [json].
  static List<T>? parseList<T>(
    dynamic json,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (json == null) return null;
    if (json is List) {
      return json
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return null;
  }
}
