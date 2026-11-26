import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_functions.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/constants/app_regx.dart';
import '/core/error/api_exception.dart';
import '/core/logger/app_logger.dart';
import '/core/repositories/base.repository.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '/shared/models/record_owner.model.dart';
import '../enum/bodyguard_availability_status.enum.dart';
import '../enum/bodyguard_ownership.enum.dart';
import '../model/body_guard.model.dart';
import '../model/bodyguard_filters.model.dart';
import '../model/bodyguard_profile_request.model.dart';
import 'availability.repository.dart';

/// Bodyguard profiles (`public.bodyguards`): self-registered (solo, `user_id`
/// set) and company-managed (`user_id = NULL`). Listings with
/// [BodyguardFilters], details, and managing company bodyguards.
/// See documentation/user_profiles.md ("Listings and filters").
///
/// Inherits [BaseSupabaseRepository] for standard CRUD, pagination, and sorting.
class BodyguardRepository extends BaseSupabaseRepository<BodyGuardModel> {
  BodyguardRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.bodyguards,
        fromJson: BodyGuardModel.fromJson,
        entityName: 'bodyguard',
        searchFields: const [JsonKeys.name],
        selectColumns: _detailsSelect,
        primarySortColumn: JsonKeys.createdAt,
        primarySortAscending: false,
      );

  static const String _companySelect =
      'company:companies!bodyguards_company_id_fkey(id, user_id, company_name, company_phone_code, company_phone_number)';

  static const String _detailsSelect =
      '''
    *,
    ${JsonKeys.isAvailableNow},
    $_companySelect,
    services:${DatabaseFunctions.listingServices}(
      id,
      service:services(id, name, description, icon_name, is_active, display_order)
    ),
    documents:user_documents!user_documents_bodyguard_id_fkey(
      id,
      user_id,
      bodyguard_id,
      document_type_id,
      file_url,
      file_name,
      status,
      rejection_reason,
      valid_till,
      uploaded_at,
      updated_at,
      document_type:document_types(
        id, name, description, target_role, is_required, is_active, display_order
      )
    ),
    availabilities:${DatabaseFunctions.listingAvailabilities}(
      id,
      user_id,
      bodyguard_id,
      day_of_week,
      is_available,
      from_time,
      to_time,
      created_at,
      updated_at
    )
  ''';

  String get _currentUserId {
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw ApiException('Your session has expired. Please sign in again.');
    }
    return uid;
  }

  /// The `companies.id` of the signed-in COMPANY account (or [companyUserId] if supplied).
  Future<String> getMyCompanyId([String? companyUserId]) async {
    final uid = companyUserId ?? _currentUserId;
    final row = await client
        .from(DatabaseTables.companies)
        .select(JsonKeys.id)
        .eq(JsonKeys.userId, uid)
        .maybeSingle();

    final id = row?[JsonKeys.id] as String?;
    if (id == null || id.isEmpty) {
      throw ApiException(
        'Company profile not found. Please complete your company profile.',
      );
    }
    return id;
  }

  /// Alias of the `!inner` embed that only exists to filter parent rows.
  static const String _serviceFilter = 'service_filter';

  /// One page of bodyguards matching [filters], in a single query so the
  /// exact count stays in sync with the filters.
  ///
  /// Services and availability use the `listing_*` computed relationships,
  /// which cover both company-managed (`bodyguard_id`) and self-registered
  /// (`user_id`) bodyguards.
  @override
  Future<({List<BodyGuardModel> data, int total})> getPaginated({
    required int page,
    required int pageSize,
    bool? isActive,
    String? search,
    String? selectColumnsOverride,
    BodyguardFilters filters = const BodyguardFilters(),
    CustomQueryBuilder? customQuery,
  }) {
    final companyId = filters.companyId;

    // A non-UUID company id makes PostgreSQL fail (22P02 invalid input syntax
    // for type uuid). No row can match it, so return an empty page.
    if (companyId != null &&
        companyId.isNotEmpty &&
        !AppRegex.uuid.hasMatch(companyId)) {
      return Future.value((data: <BodyGuardModel>[], total: 0));
    }

    final availability = filters.availability;
    final serviceIds = filters.serviceIds;
    final filterByServices = serviceIds != null && serviceIds.isNotEmpty;

    final selectQuery = [
      selectColumnsOverride ?? _detailsSelect,
      if (filterByServices)
        '$_serviceFilter:${DatabaseFunctions.listingServices}!inner'
            '(${JsonKeys.serviceId})',
    ].join(',');

    return super.getPaginated(
      page: page,
      pageSize: pageSize,
      isActive: isActive,
      search: search,
      selectColumnsOverride: selectQuery,
      customQuery: (query) {
        query = switch (filters.ownership) {
          BodyguardOwnership.solo => query.isFilter(JsonKeys.companyId, null),
          BodyguardOwnership.companyManaged => query.isFilter(
            JsonKeys.userId,
            null,
          ),
          null => query,
        };

        if (companyId != null && companyId.isNotEmpty) {
          query = query.eq(JsonKeys.companyId, companyId);
        }

        final statuses = filters.statuses;
        if (statuses != null && statuses.isNotEmpty) {
          query = query.inFilter(
            JsonKeys.status,
            statuses.map((s) => s.apiValue).toList(),
          );
        }

        if (filters.minHourlyRate != null) {
          query = query.gte(JsonKeys.hourlyRate, filters.minHourlyRate!);
        }
        if (filters.maxHourlyRate != null) {
          query = query.lte(JsonKeys.hourlyRate, filters.maxHourlyRate!);
        }
        if (filters.minRating != null) {
          query = query.gte(JsonKeys.rating, filters.minRating!);
        }

        final address = filters.address?.trim();
        if (address != null && address.isNotEmpty) {
          query = query.ilike(JsonKeys.address, '%$address%');
        }

        if (filterByServices) {
          query = query.inFilter(
            '$_serviceFilter.${JsonKeys.serviceId}',
            serviceIds,
          );
        }

        // Operational availability filter using computed `is_available_now` or today's inner join.
        if (availability != null) {
          switch (availability) {
            case BodyguardAvailabilityStatus.available:
              query = query.eq(JsonKeys.isAvailableNow, true);
            case BodyguardAvailabilityStatus.notAvailable:
              query = query.eq(JsonKeys.isAvailableNow, false);
            case BodyguardAvailabilityStatus.notSet:
              break;
          }
        }

        return customQuery?.call(query) ?? query;
      },
    );
  }

  /// One company-managed bodyguard with its company, services, documents,
  /// and availability.
  @override
  Future<BodyGuardModel> getDetails(String id) async {
    final row = await client
        .from(tableName)
        .select(_detailsSelect)
        .eq(JsonKeys.id, id)
        .maybeSingle();

    if (row == null) {
      throw ApiException('Bodyguard not found. It may have been removed.');
    }

    return fromJson(row);
  }

  /// Saves a company-managed bodyguard with typed [request].
  Future<BodyGuardModel> saveManaged({
    String? id,
    required String companyId,
    required BodyguardProfileRequest request,
  }) async {
    final payload = <String, dynamic>{
      ...request.toJson(includeIdentity: true),
      JsonKeys.companyId: companyId,
    };
    return addOrUpdate(payload, id: id);
  }

  /// Upserts profile details of a self-registered bodyguard account.
  Future<void> upsertForAccount(
    String userId,
    BodyguardProfileRequest request,
  ) async {
    await client.from(tableName).upsert({
      JsonKeys.userId: userId,
      ...request.toJson(includeIdentity: false),
    }, onConflict: JsonKeys.userId);
  }

  /// Updates a subset of columns on the `bodyguards` row identified by [owner].
  Future<void> updateForOwner(
    RecordOwner owner,
    Map<String, dynamic> fields,
  ) async {
    final column = switch (owner) {
      AccountOwner() => JsonKeys.userId,
      ManagedBodyguardOwner() => JsonKeys.id,
    };
    await client.from(tableName).update(fields).eq(column, owner.id);
  }

  /// Updates only `bio` for [owner]'s `bodyguards` row.
  Future<void> updateBio(RecordOwner owner, String bio) =>
      updateForOwner(owner, {JsonKeys.bio: bio.trim()});

  /// Updates operational key details for [owner]'s `bodyguards` row.
  Future<void> updateKeyDetails(
    RecordOwner owner, {
    required int experienceYears,
    required num hourlyRate,
    required String address,
    double? latitude,
    double? longitude,
    required String languages,
    required String certifications,
    required String qualifications,
  }) => updateForOwner(owner, {
    JsonKeys.experienceYears: experienceYears,
    JsonKeys.hourlyRate: hourlyRate,
    JsonKeys.languages: languages.trim(),
    JsonKeys.certifications: certifications.trim(),
    JsonKeys.qualifications: qualifications.trim(),
    JsonKeys.address: address.trim(),
    JsonKeys.latitude: ?latitude,
    JsonKeys.longitude: ?longitude,
  });

  /// Creates ([bodyguardId] null) or updates a company-managed bodyguard.
  @Deprecated('Use saveManaged instead')
  Future<BodyGuardModel> saveCompanyBodyguard({
    String? bodyguardId,
    required String name,
    required double hourlyRate,
    required String bio,
    int? experienceYears,
    String? languages,
    String? certifications,
    String? qualifications,
    String? address,
    double? latitude,
    double? longitude,
    String? profileImageUrl,
  }) async {
    final payload = <String, dynamic>{
      JsonKeys.name: name,
      JsonKeys.hourlyRate: hourlyRate,
      JsonKeys.bio: bio,
      JsonKeys.experienceYears: ?experienceYears,
      JsonKeys.languages: ?languages,
      JsonKeys.certifications: ?certifications,
      JsonKeys.qualifications: ?qualifications,
      JsonKeys.address: ?address,
      JsonKeys.latitude: ?latitude,
      JsonKeys.longitude: ?longitude,
      JsonKeys.profileImageUrl: ?profileImageUrl,
    };

    if (bodyguardId == null) {
      payload[JsonKeys.companyId] = await getMyCompanyId();
    }

    return addOrUpdate(payload, id: bodyguardId);
  }

  /// Removes a company-managed bodyguard. Cascades related child records.
  Future<void> deleteCompanyBodyguard(String bodyguardId) =>
      delete(bodyguardId);

  /// Sends a company-managed bodyguard to admin review (INCOMPLETE /
  /// REJECTED -> PENDING_APPROVAL).
  Future<void> submitForReview(String bodyguardId) async {
    await client
        .from(tableName)
        .update({JsonKeys.status: UserStatus.pendingApproval.apiValue})
        .eq(JsonKeys.id, bodyguardId)
        .inFilter(JsonKeys.status, [
          UserStatus.incomplete.apiValue,
          UserStatus.rejected.apiValue,
        ]);
  }

  /// Service ids of a company-managed bodyguard.
  Future<List<String>> getServiceIds(String bodyguardId) async {
    final rows = await client
        .from(DatabaseTables.userServices)
        .select(JsonKeys.serviceId)
        .eq(JsonKeys.bodyguardId, bodyguardId);
    return rows
        .map((r) => r[JsonKeys.serviceId]?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// Replaces the services of a company-managed bodyguard atomically.
  Future<void> setServices(String bodyguardId, List<String> serviceIds) {
    return client.rpc(
      DatabaseFunctions.setBodyguardServices,
      params: {
        JsonKeys.pBodyguardId: bodyguardId,
        JsonKeys.pServiceIds: serviceIds,
      },
    );
  }

  /// Seeds default weekly availability for a company-managed bodyguard.
  @Deprecated('Use AvailabilityRepository.seedDefaults(owner)')
  Future<void> initDefaultAvailability(String bodyguardId) async {
    try {
      await AvailabilityRepository(client)
          .seedDefaults(ManagedBodyguardOwner(bodyguardId));
    } catch (e) {
      AppLogger.e(
        'initDefaultAvailability failed',
        tag: 'BodyguardRepository',
        error: e,
      );
    }
  }
}
