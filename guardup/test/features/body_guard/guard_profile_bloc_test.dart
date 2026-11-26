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
import 'package:guardup/features/auth/data/repositories/user_repository.dart';
import 'package:guardup/features/body_guard/bloc/guard_profile/guard_profile_bloc.dart';
import 'package:guardup/features/body_guard/data/model/body_guard.model.dart';
import 'package:guardup/features/body_guard/data/model/bodyguard_profile_request.model.dart';
import 'package:guardup/features/body_guard/data/repositories/availability.repository.dart';
import 'package:guardup/features/body_guard/data/repositories/bodyguard.repository.dart';
import 'package:guardup/features/services/data/models/service.model.dart';
import 'package:guardup/features/services/data/repositories/services.repository.dart';
import 'package:guardup/shared/models/record_owner.model.dart';

class _MockBodyguardRepository extends Mock implements BodyguardRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockServicesRepository extends Mock implements ServicesRepository {}

class _MockAvailabilityRepository extends Mock
    implements AvailabilityRepository {}

class _MockFileStorageService extends Mock implements FileStorageService {}

void main() {
  late _MockBodyguardRepository bodyguardRepository;
  late _MockUserRepository userRepository;
  late _MockServicesRepository servicesRepository;
  late _MockAvailabilityRepository availabilityRepository;
  late _MockFileStorageService fileStorageService;

  setUpAll(() {
    registerFallbackValue(const AccountOwner('u1'));
    registerFallbackValue(
      const BodyguardProfileRequest(name: 'Alex', hourlyRate: 50, bio: 'Bio'),
    );
    registerFallbackValue(const UserAccountRequest(name: 'Alex'));
    registerFallbackValue(
      FileUploadRequest.fromXFile(
        bucket: StorageBuckets.avatars,
        path: 'u1/avatar.jpg',
        xFile: XFile('avatar.jpg'),
      ),
    );
  });

  setUp(() {
    bodyguardRepository = _MockBodyguardRepository();
    userRepository = _MockUserRepository();
    servicesRepository = _MockServicesRepository();
    availabilityRepository = _MockAvailabilityRepository();
    fileStorageService = _MockFileStorageService();
  });

  GuardProfileBloc buildBloc({
    required RecordOwner owner,
    BodyGuardModel? preview,
    String? currentUserId = 'user-1',
    void Function()? onAccountUpdated,
  }) => GuardProfileBloc(
    bodyguardRepository: bodyguardRepository,
    userRepository: userRepository,
    servicesRepository: servicesRepository,
    availabilityRepository: availabilityRepository,
    fileStorageService: fileStorageService,
    owner: owner,
    preview: preview,
    getCurrentUserId: () => currentUserId,
    onAccountUpdated: onAccountUpdated,
  );

  const activeServices = [
    ServiceModel(id: 'svc-1', name: 'VIP Protection'),
    ServiceModel(id: 'svc-2', name: 'Event Security'),
  ];

  final guardProfile = BodyGuardModel(
    id: 'guard-1',
    userId: 'user-1',
    name: 'Alex',
    hourlyRate: 75,
    bio: 'Close protection specialist',
    profileImageUrl: 'https://example.com/a.jpg',
  );

  group('GuardProfileBloc (AccountOwner)', () {
    blocTest<GuardProfileBloc, GuardProfileState>(
      'Started loads active services, user profile and filters assigned ids to active services',
      build: () {
        when(() => servicesRepository.getActive()).thenAnswer(
          (_) async => activeServices,
        );
        when(() => userRepository.getProfile('user-1')).thenAnswer(
          (_) async => UserModel(
            id: 'user-1',
            name: 'Alex',
            profileImageUrl: 'https://example.com/a.jpg',
            bodyguard: guardProfile,
          ),
        );
        when(
          () => servicesRepository.getAssignedIds(const AccountOwner('user-1')),
        ).thenAnswer((_) async => ['svc-1', 'stale-svc']);
        return buildBloc(owner: const AccountOwner('user-1'));
      },
      act: (bloc) => bloc.add(const GuardProfileStarted()),
      expect: () => [
        const GuardProfileState(loadStatus: ApiState.loading()),
        GuardProfileState(
          activeServices: activeServices,
          profile: guardProfile,
          initialAccountName: 'Alex',
          initialAccountAvatar: 'https://example.com/a.jpg',
          selectedServiceIds: const ['svc-1'],
          loadStatus: const ApiState.success(null),
        ),
      ],
    );

    test(
      'Submitted uploads avatar, writes bodyguards row before users account, assigns services, and submits for review when requested',
      () async {
        final eventsOrder = <String>[];
        var refreshedCount = 0;

        when(
          () => fileStorageService.uploadSingleFile(any()),
        ).thenAnswer((_) async {
          eventsOrder.add('upload');
          return 'https://cdn.example.com/avatar.jpg';
        });
        when(
          () => bodyguardRepository.upsertForAccount('user-1', any()),
        ).thenAnswer((_) async {
          eventsOrder.add('upsertForAccount');
        });
        when(
          () => userRepository.updateAccount('user-1', any()),
        ).thenAnswer((inv) async {
          eventsOrder.add('updateAccount');
          return const UserModel(id: 'user-1', name: 'Alex Updated');
        });
        when(
          () => servicesRepository.assign(const AccountOwner('user-1'), ['svc-2']),
        ).thenAnswer((_) async {
          eventsOrder.add('assignServices');
        });
        when(() => userRepository.submitForReview('user-1')).thenAnswer((_) async {
          eventsOrder.add('submitForReview');
        });

        final bloc = buildBloc(
          owner: const AccountOwner('user-1'),
          onAccountUpdated: () => refreshedCount++,
        );

        bloc.add(GuardProfileAvatarPicked(XFile('/tmp/pic.jpg')));
        bloc.add(const GuardProfileServicesChanged(['svc-2']));
        bloc.add(
          const GuardProfileSubmitted(
            BodyguardProfileRequest(
              name: 'Alex Updated',
              hourlyRate: 80,
              bio: 'Veteran close protection',
            ),
            resubmitForReview: true,
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<GuardProfileState>(
              (s) =>
                  s.submitStatus.isSuccess &&
                  s.submitStatus.dataOrNull == 'user-1' &&
                  s.resubmittedForReview,
            ),
          ),
        );

        expect(eventsOrder, [
          'upload',
          'upsertForAccount',
          'updateAccount',
          'assignServices',
          'submitForReview',
        ]);
        expect(refreshedCount, 1);

        final capturedUpload =
            verify(() => fileStorageService.uploadSingleFile(captureAny()))
                .captured
                .single as FileUploadRequest;
        expect(capturedUpload.bucket, StorageBuckets.avatars);
        expect(capturedUpload.path, startsWith('user-1/avatar_'));

        final capturedAccount =
            verify(() => userRepository.updateAccount('user-1', captureAny()))
                .captured
                .single as UserAccountRequest;
        expect(capturedAccount.name, 'Alex Updated');
        expect(
          capturedAccount.profileImageUrl,
          'https://cdn.example.com/avatar.jpg',
        );

        await bloc.close();
      },
    );

    blocTest<GuardProfileBloc, GuardProfileState>(
      'BioSaved updates bodyguards bio and triggers onAccountUpdated',
      build: () {
        when(
          () => bodyguardRepository.updateBio(
            const AccountOwner('user-1'),
            'New bio',
          ),
        ).thenAnswer((_) async {});
        return buildBloc(
          owner: const AccountOwner('user-1'),
          preview: guardProfile,
        );
      },
      act: (bloc) => bloc.add(const GuardProfileBioSaved('New bio')),
      expect: () => [
        GuardProfileState(
          profile: guardProfile,
          editStatus: const ApiState.loading(),
        ),
        GuardProfileState(
          profile: guardProfile.copyWith(bio: 'New bio'),
          editStatus: const ApiState.success(GuardProfileEditKind.bio),
        ),
      ],
    );

    blocTest<GuardProfileBloc, GuardProfileState>(
      'KeyDetailsSaved emits ApiState.failure carrying ApiException on error',
      build: () {
        when(
          () => bodyguardRepository.updateKeyDetails(
            const AccountOwner('user-1'),
            experienceYears: 5,
            hourlyRate: 90,
            address: 'Austin, TX',
            latitude: 30.26,
            longitude: -97.74,
            languages: 'English',
            certifications: 'CPR',
            qualifications: 'Ex-Military',
          ),
        ).thenThrow(ApiException('Update denied'));
        return buildBloc(owner: const AccountOwner('user-1'));
      },
      act: (bloc) => bloc.add(
        const GuardProfileKeyDetailsSaved(
          experienceYears: 5,
          hourlyRate: 90,
          address: 'Austin, TX',
          latitude: 30.26,
          longitude: -97.74,
          languages: 'English',
          certifications: 'CPR',
          qualifications: 'Ex-Military',
        ),
      ),
      expect: () => [
        const GuardProfileState(editStatus: ApiState.loading()),
        predicate<GuardProfileState>(
          (s) =>
              s.editStatus.isFailure &&
              (s.editStatus.errorOrNull as ApiException?)?.message ==
                  'Update denied',
        ),
      ],
    );
  });

  group('GuardProfileBloc (ManagedBodyguardOwner)', () {
    test(
      'Submitted creates managed bodyguard, uploads under company user folder, assigns services, and seeds default availability',
      () async {
        final createdGuard = BodyGuardModel(
          id: 'bg-new',
          companyId: 'comp-1',
          name: 'Sam',
          hourlyRate: 65,
          bio: 'Executive protection officer',
          profileImageUrl: 'https://cdn.example.com/managed.jpg',
        );

        when(
          () => fileStorageService.uploadSingleFile(any()),
        ).thenAnswer((_) async => 'https://cdn.example.com/managed.jpg');
        when(
          () => bodyguardRepository.getMyCompanyId('company-user-1'),
        ).thenAnswer((_) async => 'comp-1');
        when(
          () => bodyguardRepository.saveManaged(
            id: null,
            companyId: 'comp-1',
            request: any(named: 'request'),
          ),
        ).thenAnswer((_) async => createdGuard);
        when(
          () => servicesRepository.assign(
            const ManagedBodyguardOwner('bg-new'),
            ['svc-1'],
          ),
        ).thenAnswer((_) async {});
        when(
          () => availabilityRepository.seedDefaults(
            const ManagedBodyguardOwner('bg-new'),
          ),
        ).thenAnswer((_) async {});

        final bloc = buildBloc(
          owner: const ManagedBodyguardOwner(''),
          currentUserId: 'company-user-1',
        );

        bloc.add(GuardProfileAvatarPicked(XFile('/tmp/sam.jpg')));
        bloc.add(const GuardProfileServicesChanged(['svc-1']));
        bloc.add(
          const GuardProfileSubmitted(
            BodyguardProfileRequest(
              name: 'Sam',
              hourlyRate: 65,
              bio: 'Executive protection officer',
            ),
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<GuardProfileState>(
              (s) =>
                  s.submitStatus.isSuccess &&
                  s.submitStatus.dataOrNull == 'bg-new' &&
                  s.profile?.id == 'bg-new',
            ),
          ),
        );

        final capturedUpload =
            verify(() => fileStorageService.uploadSingleFile(captureAny()))
                .captured
                .single as FileUploadRequest;
        expect(
          capturedUpload.path,
          startsWith('company-user-1/bodyguards/avatar_'),
        );

        verify(
          () => availabilityRepository.seedDefaults(
            const ManagedBodyguardOwner('bg-new'),
          ),
        ).called(1);

        await bloc.close();
      },
    );
  });
}
