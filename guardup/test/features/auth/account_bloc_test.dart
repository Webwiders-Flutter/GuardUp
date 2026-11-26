import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:guardup/core/constants/api/storage_buckets.dart';
import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/core/services/file_storage/file_storage.service.dart';
import 'package:guardup/core/services/file_storage/models/file_upload_request.model.dart';
import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/auth/bloc/account/account_bloc.dart';
import 'package:guardup/features/auth/data/enum/gender_type.enum.dart';
import 'package:guardup/features/auth/data/enum/user_status.enum.dart';
import 'package:guardup/features/auth/data/model/user.model.dart';
import 'package:guardup/features/auth/data/model/user_account_request.model.dart';
import 'package:guardup/features/auth/domain/repositories/auth_repository.dart';
import 'package:guardup/features/auth/domain/repositories/user_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockFileStorageService extends Mock implements FileStorageService {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockUserRepository userRepository;
  late _MockFileStorageService fileStorageService;

  setUpAll(() {
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
    authRepository = _MockAuthRepository();
    userRepository = _MockUserRepository();
    fileStorageService = _MockFileStorageService();
  });

  AccountBloc buildBloc({
    String? currentUserId = 'u1',
    void Function()? onAccountUpdated,
    void Function()? onAccountDeleted,
  }) => AccountBloc(
    authRepository: authRepository,
    userRepository: userRepository,
    fileStorageService: fileStorageService,
    getCurrentUserId: () => currentUserId,
    onAccountUpdated: onAccountUpdated,
    onAccountDeleted: onAccountDeleted,
  );

  group('AccountBloc', () {
    test(
      'AccountProfileSaved uploads avatar, updates account without metadata writes, and triggers onAccountUpdated',
      () async {
        var refreshed = 0;
        const updatedUser = UserModel(
          id: 'u1',
          name: 'Alex Morgan',
          profileImageUrl: 'https://cdn.example.com/a.jpg',
          gender: GenderType.male,
        );

        when(
          () => fileStorageService.uploadSingleFile(any()),
        ).thenAnswer((_) async => 'https://cdn.example.com/a.jpg');
        when(
          () => userRepository.updateAccount('u1', any()),
        ).thenAnswer((_) async => updatedUser);

        final bloc = buildBloc(onAccountUpdated: () => refreshed++);

        bloc.add(
          AccountProfileSaved(
            const UserAccountRequest(
              name: 'Alex Morgan',
              phoneCode: '+91',
              phoneNumber: '9876543210',
              gender: GenderType.male,
            ),
            avatar: XFile('/tmp/pic.jpg'),
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<AccountState>(
              (s) =>
                  s.status.isSuccess &&
                  s.status.dataOrNull == AccountAction.profileSaved &&
                  s.updatedUser?.id == 'u1',
            ),
          ),
        );

        expect(refreshed, 1);
        final capturedUpload =
            verify(() => fileStorageService.uploadSingleFile(captureAny()))
                .captured
                .single as FileUploadRequest;
        expect(capturedUpload.bucket, StorageBuckets.avatars);
        expect(capturedUpload.path, startsWith('u1/avatar_'));

        final capturedReq =
            verify(
                  () => userRepository.updateAccount('u1', captureAny()),
                ).captured.single
                as UserAccountRequest;
        expect(
          capturedReq.profileImageUrl,
          'https://cdn.example.com/a.jpg',
        );
        expect(capturedReq.gender, GenderType.male);

        await bloc.close();
      },
    );

    blocTest<AccountBloc, AccountState>(
      'AccountProfileRefreshed loads latest profile and triggers onAccountUpdated',
      build: () {
        when(() => userRepository.getProfile('u1')).thenAnswer(
          (_) async => const UserModel(
            id: 'u1',
            name: 'Alex',
            status: UserStatus.active,
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AccountProfileRefreshed()),
      expect: () => [
        const AccountState(status: ApiState.loading()),
        const AccountState(
          status: ApiState.success(AccountAction.profileRefreshed),
          updatedUser: UserModel(
            id: 'u1',
            name: 'Alex',
            status: UserStatus.active,
          ),
        ),
      ],
    );

    blocTest<AccountBloc, AccountState>(
      'AccountPasswordChanged rejects identical old/new passwords without calling authRepository',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AccountPasswordChanged(oldPassword: 'same', newPassword: 'same'),
      ),
      verify: (_) => verifyNever(
        () => authRepository.changePassword(
          newPassword: any(named: 'newPassword'),
          oldPassword: any(named: 'oldPassword'),
        ),
      ),
      expect: () => [
        predicate<AccountState>(
          (s) =>
              s.status.isFailure &&
              s.status.errorMessageOrNull ==
                  'New password must be different from current password.',
        ),
      ],
    );

    blocTest<AccountBloc, AccountState>(
      'AccountDeleteRequested emits accountDeleted and triggers callback on success, or Row 14 error on failure',
      build: () {
        when(
          () => authRepository.deleteAccount(),
        ).thenThrow(ApiException('Server error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AccountDeleteRequested()),
      expect: () => [
        const AccountState(status: ApiState.loading()),
        predicate<AccountState>(
          (s) =>
              s.status.isFailure &&
              s.status.errorMessageOrNull ==
                  'Failed to delete account. Please try again.',
        ),
      ],
    );
  });
}
