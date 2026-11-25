import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_functions.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/core/logger/app_logger.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '/features/auth/data/model/user.model.dart';
import '/features/company/company.dart';
import '../model/body_guard.model.dart';
import '../model/service_item.model.dart';
import '../model/user_availability.model.dart';
import '../model/user_document.model.dart';

/// Bodyguards managed by the signed-in company (`public.bodyguards` rows with
/// `user_id = NULL` and `company_id` = the caller's company).
///
/// Self-registered bodyguards (GUARD accounts) keep using [UserRepository]:
/// their profile is read from `user_profiles` and written through
/// `updateProfileFields`. Their child rows (services, documents,
/// availability) are keyed by `user_id`; company-managed ones by
/// `bodyguard_id`. See documentation/user_profiles.md.
class BodyguardRepository {
  final SupabaseClient? _client;

  BodyguardRepository([this._client]);

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  static const String _detailsSelect = '''
    *,
    company:companies(*),
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
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw ApiException('Your session has expired. Please sign in again.');
    }
    return uid;
  }

  /// The `companies.id` of the signed-in COMPANY account.
  Future<String> getMyCompanyId() async {
    final row = await _supabase
        .from(DatabaseTables.companies)
        .select(JsonKeys.id)
        .eq(JsonKeys.userId, _currentUserId)
        .maybeSingle();

    final id = row?[JsonKeys.id] as String?;
    if (id == null || id.isEmpty) {
      throw ApiException('Company profile not found. Please complete your company profile.');
    }
    return id;
  }

  /// One page of the company's bodyguards, newest first.
  /// Optionally filters by a single [status] or a list of [statuses].
  Future<({List<BodyGuardModel> data, int total})> getCompanyBodyguards({
    required int page,
    required int pageSize,
    String? search,
    UserStatus? status,
    List<UserStatus>? statuses,
  }) async {
    final companyId = await getMyCompanyId();

    var query = _supabase
        .from(DatabaseTables.bodyguards)
        .select(_detailsSelect)
        .eq(JsonKeys.companyId, companyId)
        .isFilter(JsonKeys.userId, null);

    if (statuses != null && statuses.isNotEmpty) {
      final values = statuses.map((s) => s.apiValue).toList();
      query = query.inFilter(JsonKeys.status, values);
    } else if (status != null) {
      query = query.eq(JsonKeys.status, status.apiValue);
    }

    final term = search?.trim().replaceAll(RegExp(r'[%,()"]'), '') ?? '';
    if (term.isNotEmpty) {
      query = query.ilike(JsonKeys.name, '%$term%');
    }

    final response = await query
        .order(JsonKeys.createdAt, ascending: false)
        .range((page - 1) * pageSize, page * pageSize - 1)
        .count(CountOption.exact);

    final rows = response.data;
    return (
      data: rows.map(_toDetailedModel).toList(),
      total: response.count,
    );
  }

  /// A single bodyguard row the caller can read, or `null`.
  Future<BodyGuardModel?> getBodyguard(String bodyguardId) async {
    final row = await _supabase
        .from(DatabaseTables.bodyguards)
        .select(_detailsSelect)
        .eq(JsonKeys.id, bodyguardId)
        .maybeSingle();
    return row == null ? null : _toModel(row);
  }

  /// Comprehensive details of a bodyguard including joined company, documents,
  /// services, and availability.
  Future<BodyGuardModel> getDetails(String bodyguardId) async {
    try {
      final row = await _supabase
          .from(DatabaseTables.bodyguards)
          .select(_detailsSelect)
          .eq(JsonKeys.id, bodyguardId)
          .maybeSingle();

      if (row != null) {
        var model = _toDetailedModel(row);
        // Self-registered bodyguard: user_services are linked via user_id,
        // so bodyguard_id relation may be empty. Fetch by user_id if needed.
        if ((model.services == null || model.services!.isEmpty) && model.user.id.isNotEmpty) {
          final userServices = await _fetchServicesByUserId(model.user.id);
          if (userServices.isNotEmpty) {
            model = model.copyWith(services: userServices);
          }
        }
        // Self-registered bodyguard or missing availability: fetch by user_id or bodyguard_id
        if (model.userAvailabilities == null || model.userAvailabilities!.isEmpty) {
          final targetUserId = model.user.id.isNotEmpty ? model.user.id : (row['user_id']?.toString() ?? '');
          final availabilities = await _fetchAvailabilities(
            bodyguardId: bodyguardId,
            userId: targetUserId.isNotEmpty ? targetUserId : null,
          );
          if (availabilities.isNotEmpty) {
            model = model.copyWith(userAvailabilities: availabilities);
          }
        }
        return model;
      }
    } catch (e, st) {
      AppLogger.e('BodyguardRepository.getDetails (join)', tag: 'BodyguardRepository', error: e, stackTrace: st);
    }

    // Fallback: basic bodyguard fetch with company embed
    try {
      final baseRow = await _supabase
          .from(DatabaseTables.bodyguards)
          .select('*, company:companies(*)')
          .eq(JsonKeys.id, bodyguardId)
          .maybeSingle();

      if (baseRow != null) {
        var model = _toDetailedModel(baseRow);
        if ((model.services == null || model.services!.isEmpty) && model.user.id.isNotEmpty) {
          final userServices = await _fetchServicesByUserId(model.user.id);
          if (userServices.isNotEmpty) {
            model = model.copyWith(services: userServices);
          }
        }
        if (model.userAvailabilities == null || model.userAvailabilities!.isEmpty) {
          final targetUserId = model.user.id.isNotEmpty ? model.user.id : (baseRow['user_id']?.toString() ?? '');
          final availabilities = await _fetchAvailabilities(
            bodyguardId: bodyguardId,
            userId: targetUserId.isNotEmpty ? targetUserId : null,
          );
          if (availabilities.isNotEmpty) {
            model = model.copyWith(userAvailabilities: availabilities);
          }
        }
        return model;
      }
    } catch (e, st) {
      AppLogger.e('BodyguardRepository.getDetails (fallback)', tag: 'BodyguardRepository', error: e, stackTrace: st);
    }

    // Fallback to fake data if ID matches
    final mockMatch = BodyGuardModel.fakeData
        .where((b) => b.id == bodyguardId)
        .firstOrNull;
    if (mockMatch != null) return mockMatch;

    throw ApiException('Bodyguard details not found.');
  }

  /// Fetches services linked directly to a login account's user_id.
  Future<List<ServiceItemModel>> _fetchServicesByUserId(String userId) async {
    try {
      final rows = await _supabase
          .from(DatabaseTables.userServices)
          .select('id, service:services(id, name, description, icon_name, is_active, display_order)')
          .eq(JsonKeys.userId, userId);
      return _parseServiceItems(rows) ?? const [];
    } catch (e) {
      AppLogger.w('Error fetching user services for userId=$userId: $e', tag: 'BodyguardRepository');
      return const [];
    }
  }

  /// Fetches availability rows linked directly to a login account's user_id or bodyguard_id.
  Future<List<UserAvailabilityModel>> _fetchAvailabilities({
    required String bodyguardId,
    String? userId,
  }) async {
    try {
      final query = _supabase.from(DatabaseTables.userAvailabilities).select();
      final rows = (userId != null && userId.isNotEmpty)
          ? await query.or('bodyguard_id.eq.$bodyguardId,user_id.eq.$userId')
          : await query.eq('bodyguard_id', bodyguardId);

      final list = [
        for (final r in rows) UserAvailabilityModel.fromJson(r),
      ];
      return list;
    } catch (e) {
      AppLogger.w('Error fetching availabilities: $e', tag: 'BodyguardRepository');
      return const [];
    }
  }

  /// Creates ([bodyguardId] null) or updates a company-managed bodyguard.
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

    AppLogger.d('saveCompanyBodyguard: id=$bodyguardId', tag: 'BodyguardRepository');

    final Map<String, dynamic> row;
    if (bodyguardId == null) {
      row = await _supabase
          .from(DatabaseTables.bodyguards)
          .insert({JsonKeys.companyId: await getMyCompanyId(), ...payload})
          .select()
          .single();
    } else {
      final rows = await _supabase
          .from(DatabaseTables.bodyguards)
          .update(payload)
          .eq(JsonKeys.id, bodyguardId)
          .select();
      if (rows.isEmpty) {
        throw ApiException('This bodyguard could not be updated. It may have been removed.');
      }
      row = rows.first;
    }

    AppLogger.d('saveCompanyBodyguard success: id=${row[JsonKeys.id]}', tag: 'BodyguardRepository');
    return _toModel(row);
  }

  /// Removes a company-managed bodyguard. Its services, documents and
  /// availability are removed with it (ON DELETE CASCADE).
  Future<void> deleteCompanyBodyguard(String bodyguardId) async {
    final rows = await _supabase
        .from(DatabaseTables.bodyguards)
        .delete()
        .eq(JsonKeys.id, bodyguardId)
        .select(JsonKeys.id);
    if (rows.isEmpty) {
      throw ApiException('This bodyguard could not be removed.');
    }
  }

  /// Sends a company-managed bodyguard to admin review (INCOMPLETE /
  /// REJECTED -> PENDING_APPROVAL). Does nothing in any other state, e.g. an
  /// already approved bodyguard, or one a re-uploaded document already moved
  /// back to review.
  Future<void> submitForReview(String bodyguardId) async {
    await _supabase
        .from(DatabaseTables.bodyguards)
        .update({JsonKeys.status: UserStatus.pendingApproval.apiValue})
        .eq(JsonKeys.id, bodyguardId)
        .inFilter(JsonKeys.status, [
          UserStatus.incomplete.apiValue,
          UserStatus.rejected.apiValue,
        ]);
  }

  /// Service ids of a company-managed bodyguard.
  Future<List<String>> getServiceIds(String bodyguardId) async {
    final rows = await _supabase
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
    return _supabase.rpc(
      DatabaseFunctions.setBodyguardServices,
      params: {
        JsonKeys.pBodyguardId: bodyguardId,
        JsonKeys.pServiceIds: serviceIds,
      },
    );
  }

  /// Seeds default weekly availability (Monday-Friday 09:00 AM - 05:00 PM) for
  /// a company-managed bodyguard if none has been set yet.
  Future<void> initDefaultAvailability(String bodyguardId) async {
    try {
      final existing = await _supabase
          .from(DatabaseTables.userAvailabilities)
          .select('id')
          .eq('bodyguard_id', bodyguardId)
          .limit(1);
      if (existing.isNotEmpty) return;

      const workingDays = {'monday', 'tuesday', 'wednesday', 'thursday', 'friday'};
      const allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      final now = DateTime.now().toIso8601String();
      final rows = [
        for (final day in allDays)
          {
            'bodyguard_id': bodyguardId,
            'day_of_week': day,
            'is_available': workingDays.contains(day),
            'from_time': '09:00 AM',
            'to_time': '05:00 PM',
            'created_at': now,
            'updated_at': now,
          },
      ];
      await _supabase
          .from(DatabaseTables.userAvailabilities)
          .upsert(rows, onConflict: 'bodyguard_id, day_of_week');
    } catch (e) {
      AppLogger.e('initDefaultAvailability failed', tag: 'BodyguardRepository', error: e);
    }
  }

  List<UserAvailabilityModel>? _parseUserAvailabilities(Map<String, dynamic> row) {
    final rawAvail = row['availabilities'] ?? row['user_availabilities'];
    if (rawAvail is! List || rawAvail.isEmpty) return null;
    final list = <UserAvailabilityModel>[];
    for (final item in rawAvail) {
      if (item is Map<String, dynamic>) {
        list.add(UserAvailabilityModel.fromJson(item));
      }
    }
    return list.isNotEmpty ? list : null;
  }

  /// Maps a `bodyguards` row to the UI model. A company-managed bodyguard has
  /// no login, so its [UserModel.id] is empty.
  BodyGuardModel _toModel(Map<String, dynamic> row) {
    final imageUrl = (row[JsonKeys.profileImageUrl] as String?)?.trim();
    return BodyGuardModel(
      id: row[JsonKeys.id] as String,
      user: UserModel(
        id: (row[JsonKeys.userId] as String?) ?? '',
        name: (row[JsonKeys.name] as String?) ?? '',
        profileImageUrl: (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
        role: UserRole.guard,
      ),
      hourlyRate: _toDouble(row[JsonKeys.hourlyRate]),
      bio: (row[JsonKeys.bio] as String?) ?? '',
      languages: row[JsonKeys.languages] as String?,
      certifications: row[JsonKeys.certifications] as String?,
      qualifications: row[JsonKeys.qualifications] as String?,
      address: row[JsonKeys.address] as String?,
      latitude: _toDoubleNullable(row[JsonKeys.latitude]),
      longitude: _toDoubleNullable(row[JsonKeys.longitude]),
      experienceYears: _toDouble(row[JsonKeys.experienceYears]).toInt(),
      rating: _toDouble(row[JsonKeys.rating]),
      status: UserStatus.fromApiValue(row[JsonKeys.status] as String?),
      rejectionReason: (row[JsonKeys.rejectionReason] as String?)?.trim(),
      userAvailabilities: _parseUserAvailabilities(row),
      createdAt: row[JsonKeys.createdAt] != null
          ? DateTime.tryParse(row[JsonKeys.createdAt].toString())
          : null,
      updatedAt: row[JsonKeys.updatedAt] != null
          ? DateTime.tryParse(row[JsonKeys.updatedAt].toString())
          : null,
    );
  }

  /// Maps a joined `bodyguards` row including company, documents, and availability.
  BodyGuardModel _toDetailedModel(Map<String, dynamic> row) {
    final baseModel = _toModel(row);

    // 1. Company join mapping
    CompanyModel? company;
    final rawCompany = row['company'];
    final compMap = switch (rawCompany) {
      Map<String, dynamic> m => m,
      List<dynamic> l when l.isNotEmpty && l.first is Map<String, dynamic> =>
        l.first as Map<String, dynamic>,
      _ => null,
    };
    if (compMap != null) {
      company = CompanyModel(
        id: (compMap['id'] ?? '').toString(),
        userId: compMap['user_id']?.toString(),
        companyName: compMap['company_name']?.toString(),
        name: (compMap['company_name'] ?? compMap['name'] ?? 'Security Partner').toString(),
        businessEmail: compMap['business_email']?.toString(),
        companyPhoneNumber: compMap['company_phone_number']?.toString(),
        experienceYears: _toDouble(compMap['experience_years']).toInt(),
      );
    }

    // 2. Documents join mapping
    final documents = <UserDocumentModel>[];
    final rawDocs = row['documents'] ?? row['user_documents'];
    if (rawDocs is List) {
      for (final item in rawDocs) {
        if (item is Map<String, dynamic>) {
          documents.add(UserDocumentModel.fromJson(item));
        }
      }
    }

    // 3. User Availabilities join mapping
    final userAvailabilities = <UserAvailabilityModel>[];
    final rawAvail = row['availabilities'] ?? row['user_availabilities'];
    if (rawAvail is List) {
      for (final item in rawAvail) {
        if (item is Map<String, dynamic>) {
          userAvailabilities.add(UserAvailabilityModel.fromJson(item));
        }
      }
    }

    return baseModel.copyWith(
      company: company ?? baseModel.company,
      documents: documents.isNotEmpty ? documents : baseModel.documents,
      userAvailabilities: userAvailabilities.isNotEmpty
          ? userAvailabilities
          : baseModel.userAvailabilities,
      qualifications: row['qualifications']?.toString() ?? baseModel.qualifications,
      services: _parseServiceItems(row['services']) ?? baseModel.services,
    );
  }

  /// Maps `user_services(service:services(name, ...))` rows to [ServiceItemModel] items.
  static List<ServiceItemModel>? _parseServiceItems(Object? raw) {
    if (raw is! List) return null;
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>)
          if (item['service'] is Map<String, dynamic>)
            ServiceItemModel.fromJson(item['service'] as Map<String, dynamic>)
          else
            ServiceItemModel.fromJson(item),
    ];
  }

  static double _toDouble(Object? value) => switch (value) {
    num n => n.toDouble(),
    String s => double.tryParse(s) ?? 0,
    _ => 0,
  };

  static double? _toDoubleNullable(Object? value) => switch (value) {
    num n => n.toDouble(),
    String s => double.tryParse(s),
    _ => null,
  };
}
