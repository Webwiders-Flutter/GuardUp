import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';

/// Callback type for customizing or chaining Supabase queries with arbitrary filters.
typedef CustomQueryBuilder =
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
    );

/// Alias for backwards compatibility.
typedef SupabaseQueryFilter = CustomQueryBuilder;

/// Enterprise Abstract Base Repository interface for standard CRUD & pagination.
abstract interface class BaseRepository<T> {
  Future<({List<T> data, int total})> getPaginated({
    required int page,
    required int pageSize,
    bool? isActive,
    String? search,
    String? selectColumnsOverride,
    CustomQueryBuilder? customQuery,
  });

  Future<T> getDetails(String id);

  Future<T> addOrUpdate(Map<String, dynamic> data, {String? id});

  Future<void> delete(String id);

  /// Bulk delete multiple records matching [ids].
  Future<void> deleteMany(List<String> ids);

  /// Bulk update multiple records matching [ids] with [data].
  Future<List<T>> updateMany(Map<String, dynamic> data, List<String> ids);
}

/// Enterprise Supabase Concrete Base Repository implementation providing standardized
/// CRUD operations, pagination, search, sorting, and exception handling across all features.
abstract class BaseSupabaseRepository<T> implements BaseRepository<T> {
  final SupabaseClient client;
  final String tableName;
  final T Function(Map<String, dynamic> json) fromJson;
  final String entityName;
  final List<String> searchFields;
  final String primarySortColumn;
  final bool primarySortAscending;
  final String? secondarySortColumn;
  final bool secondarySortAscending;
  final String selectColumns;

  const BaseSupabaseRepository({
    required this.client,
    required this.tableName,
    required this.fromJson,
    this.selectColumns = '*',
    this.entityName = 'record',
    this.searchFields = const [
      JsonKeys.name,
      JsonKeys.description,
      JsonKeys.nameHi,
      JsonKeys.descriptionHi,
    ],
    this.primarySortColumn = JsonKeys.sortOrder,
    this.primarySortAscending = true,
    this.secondarySortColumn,
    this.secondarySortAscending = true,
  });

  @override
  Future<({List<T> data, int total})> getPaginated({
    required int page,
    required int pageSize,
    bool? isActive,
    String? search,
    String? selectColumnsOverride,
    CustomQueryBuilder? customQuery,
  }) async {
    var query = client
        .from(tableName)
        .select(selectColumnsOverride ?? selectColumns);

    if (isActive != null) {
      query = query.eq(JsonKeys.isActive, isActive);
    }

    if (search != null && search.trim().isNotEmpty) {
      final searchFilter = buildSearchFilter(search.trim());
      if (searchFilter != null && searchFilter.isNotEmpty) {
        query = query.or(searchFilter);
      }
    }

    if (customQuery != null) {
      query = customQuery(query);
    }

    var orderedQuery = query.order(
      primarySortColumn,
      ascending: primarySortAscending,
    );

    if (secondarySortColumn != null) {
      orderedQuery = orderedQuery.order(
        secondarySortColumn!,
        ascending: secondarySortAscending,
      );
    }

    if (primarySortColumn != JsonKeys.name &&
        secondarySortColumn != JsonKeys.name &&
        searchFields.contains(JsonKeys.name)) {
      orderedQuery = orderedQuery.order(JsonKeys.name, ascending: true);
    }

    final response = await orderedQuery
        .limit(pageSize)
        .range((page - 1) * pageSize, page * pageSize - 1)
        .count(CountOption.exact);

    final data = response.data as List;
    final count = response.count;
    return (
      data: data.map((json) => fromJson(json as Map<String, dynamic>)).toList(),
      total: count,
    );
  }

  /// Builds the PostgREST `or()` filter for [queryStr].
  ///
  /// The pattern is quoted and `"` is stripped so commas or parentheses typed
  /// in a search box cannot break the `or()` expression. Subclasses can
  /// override this for domain-specific search.
  String? buildSearchFilter(String queryStr) {
    final sanitized = queryStr.replaceAll('"', '');
    final searchFilters = searchFields
        .map((field) => '$field.ilike."%$sanitized%"')
        .join(',');
    return searchFilters.isNotEmpty ? searchFilters : null;
  }

  @override
  Future<T> getDetails(String id) async {
    final response = await client
        .from(tableName)
        .select(selectColumns)
        .eq(JsonKeys.id, id)
        .maybeSingle();
    if (response == null) {
      throw ApiException(
        "Unable to get $entityName details. Please try again later.",
        type: ApiErrorType.notFound,
      );
    }
    return fromJson(response);
  }

  @override
  Future<T> addOrUpdate(Map<String, dynamic> data, {String? id}) async {
    final payload = Map<String, dynamic>.from(data)..remove(JsonKeys.id);
    final List<dynamic> response;
    if (id == null) {
      response = await client.from(tableName).insert(payload).select();
    } else {
      response = await client
          .from(tableName)
          .update(payload)
          .eq(JsonKeys.id, id)
          .select();
    }

    if (response.isEmpty) {
      throw ApiException("Unable to save $entityName. Please try again later.");
    }

    return fromJson(response.first);
  }

  @override
  Future<void> delete(String id) async {
    await client.from(tableName).delete().eq(JsonKeys.id, id);
  }

  @override
  Future<void> deleteMany(List<String> ids) async {
    if (ids.isEmpty) return;
    await client.from(tableName).delete().inFilter(JsonKeys.id, ids);
  }

  @override
  Future<List<T>> updateMany(
    Map<String, dynamic> data,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final payload = Map<String, dynamic>.from(data)..remove(JsonKeys.id);
    final List<dynamic> response = await client
        .from(tableName)
        .update(payload)
        .inFilter(JsonKeys.id, ids)
        .select();

    return response
        .map((json) => fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
