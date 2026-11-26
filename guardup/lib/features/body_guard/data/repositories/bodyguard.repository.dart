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
import '../enum/week_day.enum.dart';
import '../model/body_guard.model.dart';
import '../model/bodyguard_filters.model.dart';
import '../model/bodyguard_profile_request.model.dart';
import 'availability.repository.dart';

/// Company-managed bodyguards (`public.bodyguards` with `user_id = NULL`):
/// listings, single operative details, creation, update, and service management.
/// See documentation/user_profiles.md.
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
    $_companySelect,
    services:user_services!user_services_bodyguard_id_fkey(
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
    availabilities:user_availabilities!user_availabilities_bodyguard_id_fkey(
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

  /// Standard paginated listing supporting search, status, availability status,
  /// and company filtering directly within the single Supabase query.
  @override
  Future<({List<BodyGuardModel> data, int total})> getPaginated({
    required int page,
    required int pageSize,
    bool? isActive,
    String? search,
    String? selectColumnsOverride,
    String? companyId,
    UserStatus? status,
    List<UserStatus>? statuses,
    BodyguardAvailabilityStatus? availabilityStatus,
    BodyguardFilters? filters,
    CustomQueryBuilder? customQuery,
  }) {
    final effectiveCompanyId = filters?.companyId ?? companyId;
    final effectiveStatuses = filters?.statuses ?? statuses;
    final effectiveAvailability = filters?.availability ?? availabilityStatus;

    // If a companyId is supplied but is not a valid UUID, querying PostgREST directly
    // causes a PostgreSQL syntax error (code 22P02: invalid input syntax for type uuid).
    // Safely return an empty list because no rows in the DB can match a non-UUID.
    if (effectiveCompanyId != null &&
        effectiveCompanyId.isNotEmpty &&
        !AppRegex.uuid.hasMatch(effectiveCompanyId)) {
      return Future.value((data: <BodyGuardModel>[], total: 0));
    }

    // When availabilityStatus is requested, embed an !inner join on the current day's
    // availability row so the database filter and count pagination stay fully synchronized.
    final now = DateTime.now();
    final currentDay = WeekDay.fromDateTime(now).apiValue.toLowerCase();

    final selectQuery = effectiveAvailability != null
        ? '''
          $_detailsSelect,
          availability_filter:user_availabilities!user_availabilities_bodyguard_id_fkey!inner(
            id,
            day_of_week,
            is_available
          )
        '''
        : _detailsSelect;

    return super.getPaginated(
      page: page,
      pageSize: pageSize,
      isActive: isActive,
      search: search,
      selectColumnsOverride: selectQuery,
      customQuery: (query) {
        query = query.isFilter(JsonKeys.userId, null);

        if (effectiveCompanyId != null && effectiveCompanyId.isNotEmpty) {
          query = query.eq(JsonKeys.companyId, effectiveCompanyId);
        }

        if (effectiveStatuses != null && effectiveStatuses.isNotEmpty) {
          final values = effectiveStatuses.map((s) => s.apiValue).toList();
          query = query.inFilter(JsonKeys.status, values);
        } else if (status != null) {
          query = query.eq(JsonKeys.status, status.apiValue);
        }

        // Inner join filter on current day slot
        if (effectiveAvailability != null) {
          query = query.eq('availability_filter.day_of_week', currentDay);
          if (effectiveAvailability == BodyguardAvailabilityStatus.available) {
            query = query.eq('availability_filter.is_available', true);
          } else if (effectiveAvailability ==
              BodyguardAvailabilityStatus.notAvailable) {
            query = query.eq('availability_filter.is_available', false);
          }
        }

        return customQuery?.call(query) ?? query;
      },
    );
  }

  /// One page of the signed-in company's bodyguards using [getPaginated].
  Future<({List<BodyGuardModel> data, int total})> getCompanyBodyguards({
    required int page,
    required int pageSize,
    String? search,
    UserStatus? status,
    List<UserStatus>? statuses,
    BodyguardAvailabilityStatus? availabilityStatus,
  }) async {
    final companyId = await getMyCompanyId();
    return getPaginated(
      page: page,
      pageSize: pageSize,
      search: search,
      companyId: companyId,
      status: status,
      statuses: statuses,
      availabilityStatus: availabilityStatus,
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
