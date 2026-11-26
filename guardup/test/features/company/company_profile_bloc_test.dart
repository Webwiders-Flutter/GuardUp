import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:guardup/core/constants/api/storage_buckets.dart';
import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/core/services/file_storage/file_storage.service.dart';
import 'package:guardup/core/services/file_storage/models/file_upload_request.model.dart';
import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/auth/data/model/user.model.dart';
import 'package:guardup/features/auth/data/model/user_account_request.model.dart';
import 'package:guardup/features/auth/domain/repositories/user_repository.dart';
import 'package:guardup/features/company/bloc/company_profile/company_profile_bloc.dart';
import 'package:guardup/features/company/data/enum/business_type.enum.dart';
import 'package:guardup/features/company/data/model/company.model.dart';
import 'package:guardup/features/company/data/model/company_profile_request.model.dart';
import 'package:guardup/features/company/data/repositories/company.repository.dart';

class _MockCompanyRepository extends Mock implements CompanyRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockFileStorageService extends Mock implements FileStorageService {}

void main() {
  late _MockCompanyRepository companyRepository;
  late _MockUserRepository userRepository;
  late _MockFileStorageService fileStorageService;

  setUpAll(() {
    registerFallbackValue(
      const CompanyProfileRequest(
        companyName: 'Apex',
        businessEmail: 'ops@apex.io',
        companyPhoneNumber: '9876543210',
      ),
    );
    registerFallbackValue(const UserAccountRequest(name: 'Apex'));
    registerFallbackValue(
      FileUploadRequest.fromXFile(
        bucket: StorageBuckets.documents,
        path: 'u1/logo.jpg',
        xFile: XFile('logo.jpg'),
      ),
    );
  });

  setUp(() {
    companyRepository = _MockCompanyRepository();
    userRepository = _MockUserRepository();
    fileStorageService = _MockFileStorageService();
  });

  CompanyProfileBloc buildBloc({
    String? currentUserId = 'comp-user-1',
    void Function()? onAccountUpdated,
  }) => CompanyProfileBloc(
    companyRepository: companyRepository,
    userRepository: userRepository,
    fileStorageService: fileStorageService,
    getCurrentUserId: () => currentUserId,
    onAccountUpdated: onAccountUpdated,
  );

  const sampleCompany = CompanyModel(
    id: 'comp-1',
    userId: 'comp-user-1',
    companyName: 'Apex Security',
    businessEmail: 'ops@apex.io',
    companyType: BusinessType.pvtLtd,
    companyPhoneCode: '+91',
    companyPhoneNumber: '9876543210',
    experienceYears: 8,
  );

  group('CompanyProfileBloc', () {
    blocTest<CompanyProfileBloc, CompanyProfileState>(
      'Started loads saved company record by user id',
      build: () {
        when(
          () => companyRepository.getByUserId('comp-user-1'),
        ).thenAnswer((_) async => sampleCompany);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CompanyProfileStarted()),
      expect: () => [
        const CompanyProfileState(loadStatus: ApiState.loading()),
        const CompanyProfileState(
          company: sampleCompany,
          loadStatus: ApiState.success(null),
        ),
      ],
    );

    test(
      'Submitted uploads logo, writes companies row before users account, submits for review when requested, and refreshes auth',
      () async {
        final callOrder = <String>[];
        var refreshed = 0;

        when(
          () => fileStorageService.uploadSingleFile(any()),
        ).thenAnswer((_) async {
          callOrder.add('upload');
          return 'https://cdn.example.com/logo.png';
        });
        when(
          () => companyRepository.upsertForAccount('comp-user-1', any()),
        ).thenAnswer((_) async {
          callOrder.add('upsertForAccount');
        });
        when(
          () => userRepository.updateAccount('comp-user-1', any()),
        ).thenAnswer((_) async {
          callOrder.add('updateAccount');
          return const UserModel(id: 'comp-user-1', name: 'Apex Security');
        });
        when(() => userRepository.submitForReview('comp-user-1')).thenAnswer((
          _,
        ) async {
          callOrder.add('submitForReview');
        });

        final bloc = buildBloc(onAccountUpdated: () => refreshed++);

        bloc.add(CompanyProfileLogoPicked(XFile('/tmp/logo.png')));
        bloc.add(
          const CompanyProfileSubmitted(
            CompanyProfileRequest(
              companyName: 'Apex Security',
              businessEmail: 'ops@apex.io',
              companyType: BusinessType.pvtLtd,
              companyPhoneNumber: '9876543210',
              experienceYears: 8,
            ),
            resubmitForReview: true,
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<CompanyProfileState>(
              (s) => s.submitStatus.isSuccess && s.resubmittedForReview,
            ),
          ),
        );

        expect(callOrder, [
          'upload',
          'upsertForAccount',
          'updateAccount',
          'submitForReview',
        ]);
        expect(refreshed, 1);

        final capturedUpload =
            verify(() => fileStorageService.uploadSingleFile(captureAny()))
                .captured
                .single as FileUploadRequest;
        expect(capturedUpload.bucket, StorageBuckets.documents);
        expect(capturedUpload.path, startsWith('comp-user-1/logo_'));
        expect(capturedUpload.path, endsWith('.png'));

        final capturedAccount =
            verify(
                  () =>
                      userRepository.updateAccount('comp-user-1', captureAny()),
                ).captured.single
                as UserAccountRequest;
        expect(capturedAccount.name, 'Apex Security');
        expect(
          capturedAccount.profileImageUrl,
          'https://cdn.example.com/logo.png',
        );

        await bloc.close();
      },
    );

    blocTest<CompanyProfileBloc, CompanyProfileState>(
      'Submitted emits failure carrying ApiException when repository throws',
      build: () {
        when(
          () => companyRepository.upsertForAccount('comp-user-1', any()),
        ).thenThrow(ApiException('Save failed'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const CompanyProfileSubmitted(
          CompanyProfileRequest(
            companyName: 'Apex',
            businessEmail: 'ops@apex.io',
            companyPhoneNumber: '9876543210',
          ),
        ),
      ),
      expect: () => [
        const CompanyProfileState(submitStatus: ApiState.loading()),
        predicate<CompanyProfileState>(
          (s) =>
              s.submitStatus.isFailure &&
              (s.submitStatus.errorOrNull as ApiException?)?.message ==
                  'Save failed',
        ),
      ],
    );
  });
}

