import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/features/auth/data/enum/user_status.enum.dart';
import 'package:guardup/features/body_guard/data/enum/bodyguard_availability_status.enum.dart';
import 'package:guardup/features/body_guard/data/enum/bodyguard_ownership.enum.dart';
import 'package:guardup/features/body_guard/data/model/bodyguard_filters.model.dart';
import 'package:guardup/features/body_guard/data/repositories/bodyguard.repository.dart';
import 'package:guardup/features/company/data/model/company_filters.model.dart';
import 'package:guardup/features/company/data/repositories/company.repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Builds the real PostgREST request through the repositories and captures
/// its URL, so the tests check exactly what is sent to Supabase.
({SupabaseClient client, List<Uri> requests}) _capturingClient(
  List<Map<String, dynamic>> rows,
) {
  final requests = <Uri>[];
  final httpClient = MockClient((request) async {
    requests.add(request.url);
    return http.Response(
      jsonEncode(rows),
      200,
      request: request, // postgrest reads response.request
      headers: {
        'content-type': 'application/json',
        'content-range': rows.isEmpty
            ? '*/0'
            : '0-${rows.length - 1}/${rows.length}',
      },
    );
  });
  final client = SupabaseClient(
    'https://example.supabase.co',
    'anon-key',
    httpClient: httpClient,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  return (client: client, requests: requests);
}

Map<String, String> _params(Uri uri) => uri.queryParameters;

String _select(Uri uri) =>
    _params(uri)['select']!.replaceAll(RegExp(r'\s+'), '');

void main() {
  group('CompanyRepository.getPaginated', () {
    test(
      'filters status through account_status, never an inner users join',
      () async {
        final c = _capturingClient([
          {
            'id': 'c1',
            'user_id': 'u1',
            'company_name': 'Shield',
            'account_status': 'ACTIVE',
            'user': null, // customers cannot read users
          },
        ]);
        final result = await CompanyRepository(c.client).getPaginated(
          page: 1,
          pageSize: 10,
          filters: CompanyFilters.customerDefault,
        );

        final uri = c.requests.single;
        expect(uri.path, '/rest/v1/companies');
        expect(_select(uri), contains('account_status'));
        expect(_select(uri), isNot(contains('!inner')));
        expect(_params(uri)['account_status'], 'in.("ACTIVE")');
        expect(_params(uri).keys, isNot(contains('user.status')));

        expect(result.total, 1);
        expect(result.data.single.accountStatus, UserStatus.active);
        expect(result.data.single.user, isNull);
      },
    );

    test('no statuses -> no status filter', () async {
      final c = _capturingClient([]);
      await CompanyRepository(c.client).getPaginated(page: 1, pageSize: 10);
      expect(
        _params(c.requests.single).keys,
        isNot(contains('account_status')),
      );
    });

    test('getPaginated never embeds documents', () async {
      final c = _capturingClient([]);
      await CompanyRepository(c.client).getPaginated(page: 1, pageSize: 10);
      final uri = c.requests.single;
      expect(_select(uri), isNot(contains('documents')));
      expect(_select(uri), isNot(contains('listing_documents')));
    });

    test('getDetails embeds documents via listing_documents', () async {
      final c = _capturingClient([
        {
          'id': 'c1',
          'user_id': 'u1',
          'company_name': 'Shield',
          'bio': 'Elite protection firm',
          'created_at': '2025-01-01T00:00:00Z',
          'account_status': 'ACTIVE',
          'user': null,
          'documents': [
            {
              'id': 'd1',
              'user_id': 'u1',
              'document_type_id': 'dt1',
              'file_url': 'https://example.com/doc.pdf',
              'file_name': 'License.pdf',
              'status': 'APPROVED',
            },
          ],
        },
      ]);
      final detailed = await CompanyRepository(c.client).getDetails('c1');
      final uri = c.requests.single;
      expect(_select(uri), contains('documents:listing_documents'));
      expect(detailed.bio, 'Elite protection firm');
      expect(detailed.documents?.length, 1);
      expect(detailed.documents?.first.fileName, 'License.pdf');
    });
  });

  group('BodyguardRepository.getPaginated', () {
    test('solo ownership: ACTIVE solo guards only', () async {
      final c = _capturingClient([]);
      await BodyguardRepository(c.client).getPaginated(
        page: 1,
        pageSize: 10,
        filters: const BodyguardFilters(
          statuses: [UserStatus.active],
          ownership: BodyguardOwnership.solo,
        ),
      );

      final params = _params(c.requests.single);
      expect(params['company_id'], 'is.null');
      expect(params['status'], 'in.("ACTIVE")');
      expect(params.keys, isNot(contains('user_id')));
    });

    test('company-managed ownership filters user_id IS NULL', () async {
      final c = _capturingClient([]);
      await BodyguardRepository(c.client).getPaginated(
        page: 1,
        pageSize: 10,
        filters: const BodyguardFilters(
          ownership: BodyguardOwnership.companyManaged,
          companyId: '6f1c1e9a-1d2b-4c3d-8e4f-5a6b7c8d9e0f',
        ),
      );

      final params = _params(c.requests.single);
      expect(params['user_id'], 'is.null');
      expect(params['company_id'], 'eq.6f1c1e9a-1d2b-4c3d-8e4f-5a6b7c8d9e0f');
    });

    test('company-managed ownership with availability filters via is_available_now', () async {
      final c = _capturingClient([]);
      await BodyguardRepository(c.client).getPaginated(
        page: 1,
        pageSize: 10,
        filters: const BodyguardFilters(
          ownership: BodyguardOwnership.companyManaged,
          companyId: '6f1c1e9a-1d2b-4c3d-8e4f-5a6b7c8d9e0f',
          statuses: [UserStatus.active],
          availability: BodyguardAvailabilityStatus.available,
        ),
      );

      final params = _params(c.requests.single);
      expect(params['user_id'], 'is.null');
      expect(params['company_id'], 'eq.6f1c1e9a-1d2b-4c3d-8e4f-5a6b7c8d9e0f');
      expect(params['status'], 'in.("ACTIVE")');
      expect(params['is_available_now'], 'eq.true');
    });

    test('rate, rating and services filters', () async {
      final c = _capturingClient([]);
      await BodyguardRepository(c.client).getPaginated(
        page: 1,
        pageSize: 10,
        filters: const BodyguardFilters(
          minHourlyRate: 20,
          maxHourlyRate: 80,
          minRating: 4,
          serviceIds: ['s1', 's2'],
        ),
      );

      final uri = c.requests.single;
      final all = uri.queryParametersAll;
      expect(all['hourly_rate'], containsAll(['gte.20.0', 'lte.80.0']));
      expect(_params(uri)['rating'], 'gte.4.0');
      expect(
        _select(uri),
        contains('service_filter:listing_services!inner(service_id)'),
      );
      expect(_params(uri)['service_filter.service_id'], 'in.("s1","s2")');
    });

    test('services and availability embeds cover solo guards', () async {
      final c = _capturingClient([]);
      await BodyguardRepository(c.client).getPaginated(page: 1, pageSize: 10);

      final select = _select(c.requests.single);
      expect(select, contains('services:listing_services('));
      expect(select, contains('availabilities:listing_availabilities('));
      expect(
        select,
        isNot(contains('user_services!user_services_bodyguard_id_fkey')),
      );
    });

    test('availability filters via is_available_now', () async {
      final c = _capturingClient([]);
      await BodyguardRepository(c.client).getPaginated(
        page: 1,
        pageSize: 10,
        filters: const BodyguardFilters(
          availability: BodyguardAvailabilityStatus.available,
        ),
      );

      final uri = c.requests.single;
      expect(_select(uri), contains('is_available_now'));
      expect(_params(uri)['is_available_now'], 'eq.true');
    });

    test(
      'non-UUID company id returns an empty page without a request',
      () async {
        final c = _capturingClient([]);
        final result = await BodyguardRepository(c.client).getPaginated(
          page: 1,
          pageSize: 10,
          filters: const BodyguardFilters(companyId: 'not-a-uuid'),
        );
        expect(result.total, 0);
        expect(c.requests, isEmpty);
      },
    );
  });

  group('BodyguardFilters', () {
    test('customerDefault contains ACTIVE status', () {
      expect(BodyguardFilters.customerDefault.statuses, [UserStatus.active]);
    });

    test('copyWith sets and clears every new filter', () {
      const filters = BodyguardFilters(
        minHourlyRate: 10,
        maxHourlyRate: 50,
        minRating: 3,
        serviceIds: ['s1'],
        ownership: BodyguardOwnership.solo,
        address: 'Mumbai',
      );
      expect(filters.copyWith(), filters);
      expect(filters.hasActiveFilters, isTrue);

      final cleared = filters.copyWith(
        minHourlyRate: null,
        maxHourlyRate: null,
        minRating: null,
        serviceIds: null,
        ownership: null,
        address: null,
      );
      expect(cleared, const BodyguardFilters());
      expect(cleared.hasActiveFilters, isFalse);
      expect(const BodyguardFilters(serviceIds: []).hasActiveFilters, isFalse);
      expect(const BodyguardFilters(address: '  ').hasActiveFilters, isFalse);
    });

    test('BodyguardRepository.getPaginated filters by address using ilike', () async {
      final c = _capturingClient([]);
      await BodyguardRepository(c.client).getPaginated(
        page: 1,
        pageSize: 10,
        filters: const BodyguardFilters(address: ' Mumbai '),
      );

      final params = _params(c.requests.single);
      expect(params['address'], 'ilike.%Mumbai%');
    });
  });
}
