import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/auth/data/enum/user_role.enum.dart';
import 'package:guardup/features/auth/data/model/user.model.dart';
import 'package:guardup/features/auth/data/model/user_account_request.model.dart';
import 'package:guardup/features/auth/data/repositories/user_repository.dart';
import 'package:guardup/features/body_guard/data/enum/document_status.enum.dart';
import 'package:guardup/features/body_guard/data/repositories/bodyguard.repository.dart';
import 'package:guardup/features/documents/bloc/documents_bloc.dart';
import 'package:guardup/features/documents/data/models/document_type.model.dart';
import 'package:guardup/features/documents/data/models/user_document.model.dart';
import 'package:guardup/features/documents/data/repositories/document_types.repository.dart';
import 'package:guardup/features/documents/data/repositories/user_documents.repository.dart';
import 'package:guardup/shared/models/record_owner.model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentTypesRepository extends Mock
    implements DocumentTypesRepository {}

class MockUserDocumentsRepository extends Mock
    implements UserDocumentsRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockBodyguardRepository extends Mock implements BodyguardRepository {}

class FakeUserAccountRequest extends Fake implements UserAccountRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(UserRole.guard);
    registerFallbackValue(const AccountOwner('fallback'));
    registerFallbackValue(
      const DocumentTypeModel(id: 'fallback', name: 'Fallback'),
    );
    registerFallbackValue(XFile('/tmp/fake.png'));
    registerFallbackValue(FakeUserAccountRequest());
  });

  group('DocumentsBloc', () {
    late MockDocumentTypesRepository typesRepo;
    late MockUserDocumentsRepository docsRepo;
    late MockUserRepository userRepo;
    late MockBodyguardRepository bodyguardRepo;

    const idType = DocumentTypeModel(
      id: 'type-id',
      name: 'Government ID',
      targetRole: UserRole.guard,
      isRequired: true,
    );
    const optType = DocumentTypeModel(
      id: 'type-opt',
      name: 'Optional Cert',
      targetRole: UserRole.guard,
      isRequired: false,
    );
    const logoType = DocumentTypeModel(
      id: 'type-logo',
      name: 'Company Logo',
      targetRole: UserRole.company,
      isRequired: true,
    );

    final pickedFile = XFile('/tmp/id.jpg', name: 'id.jpg');

    setUp(() {
      typesRepo = MockDocumentTypesRepository();
      docsRepo = MockUserDocumentsRepository();
      userRepo = MockUserRepository();
      bodyguardRepo = MockBodyguardRepository();
    });

    test('canSubmit validates required and rejected documents', () {
      const incomplete = DocumentsState(
        types: [idType, optType],
        uploaded: {},
        picked: {},
      );
      expect(incomplete.canSubmit, false);

      final pickedRequired = DocumentsState(
        types: const [idType, optType],
        uploaded: const {},
        picked: {'type-id': pickedFile},
      );
      expect(pickedRequired.canSubmit, true);

      const rejectedNotReplaced = DocumentsState(
        types: [idType, optType],
        uploaded: {
          'type-id': UserDocumentModel(
            id: 'd1',
            documentTypeId: 'type-id',
            fileUrl: 'https://x/id.jpg',
            status: DocumentStatus.rejected,
          ),
        },
        picked: {},
      );
      expect(rejectedNotReplaced.canSubmit, false);
      expect(rejectedNotReplaced.hasRejectedDoc, true);
    });

    blocTest<DocumentsBloc, DocumentsState>(
      'Started loads active types and existing documents for owner',
      build: () {
        when(() => typesRepo.getActiveFor(UserRole.guard))
            .thenAnswer((_) async => const [idType, optType]);
        when(() => docsRepo.getFor(const AccountOwner('u1'))).thenAnswer(
          (_) async => const [
            UserDocumentModel(
              id: 'doc-1',
              userId: 'u1',
              documentTypeId: 'type-id',
              fileUrl: 'https://x/id.jpg',
              status: DocumentStatus.approved,
            ),
          ],
        );
        return DocumentsBloc(
          typesRepository: typesRepo,
          documentsRepository: docsRepo,
          userRepository: userRepo,
          bodyguardRepository: bodyguardRepo,
          owner: const AccountOwner('u1'),
          role: UserRole.guard,
          getCurrentUserId: () => 'u1',
        );
      },
      act: (bloc) => bloc.add(const DocumentsStarted()),
      expect: () => [
        const DocumentsState(loadStatus: ApiState.loading()),
        isA<DocumentsState>()
            .having((s) => s.loadStatus.isSuccess, 'isSuccess', true)
            .having((s) => s.types.length, 'types', 2)
            .having((s) => s.uploaded['type-id']?.id, 'uploaded id', 'doc-1')
            .having((s) => s.canSubmit, 'canSubmit', true),
      ],
    );

    blocTest<DocumentsBloc, DocumentsState>(
      'Picked and Removed update picked map',
      build: () => DocumentsBloc(
        typesRepository: typesRepo,
        documentsRepository: docsRepo,
        userRepository: userRepo,
        bodyguardRepository: bodyguardRepo,
        owner: const AccountOwner('u1'),
        role: UserRole.guard,
        getCurrentUserId: () => 'u1',
      ),
      act: (bloc) => bloc
        ..add(DocumentPicked('type-id', pickedFile))
        ..add(const DocumentRemoved('type-id')),
      expect: () => [
        DocumentsState(picked: {'type-id': pickedFile}),
        const DocumentsState(picked: {}),
      ],
    );

    var accountCallbackCalled = false;

    blocTest<DocumentsBloc, DocumentsState>(
      'Submitted uploads company logo, syncs profile_image_url, and fires onAccountSubmitted',
      build: () {
        accountCallbackCalled = false;
        when(
          () => docsRepo.upload(
            storageUserId: 'comp-u1',
            owner: const AccountOwner('comp-u1'),
            type: logoType,
            file: pickedFile,
          ),
        ).thenAnswer(
          (_) async => const UserDocumentModel(
            id: 'doc-logo',
            userId: 'comp-u1',
            documentTypeId: 'type-logo',
            fileUrl: 'https://cdn/logo.png',
            status: DocumentStatus.pending,
          ),
        );
        when(() => userRepo.updateAccount('comp-u1', any())).thenAnswer(
          (_) async => UserModel.fromJson({
            'id': 'comp-u1',
            'email': 'c@example.com',
            'role': 'COMPANY',
          }),
        );
        return DocumentsBloc(
          typesRepository: typesRepo,
          documentsRepository: docsRepo,
          userRepository: userRepo,
          bodyguardRepository: bodyguardRepo,
          owner: const AccountOwner('comp-u1'),
          role: UserRole.company,
          getCurrentUserId: () => 'comp-u1',
          onAccountSubmitted: () => accountCallbackCalled = true,
        )..add(DocumentPicked('type-logo', pickedFile));
      },
      seed: () => const DocumentsState(
        types: [logoType],
        loadStatus: ApiState.success(null),
      ),
      act: (bloc) => bloc.add(const DocumentsSubmitted(submitApplication: true)),
      verify: (_) {
        final req = verify(() => userRepo.updateAccount('comp-u1', captureAny()))
            .captured
            .single as UserAccountRequest;
        expect(req.profileImageUrl, 'https://cdn/logo.png');
        expect(accountCallbackCalled, true);
        verifyNever(() => userRepo.submitForReview(any()));
      },
    );

    blocTest<DocumentsBloc, DocumentsState>(
      'Submitted with empty picked calls submitForReview for AccountOwner',
      build: () {
        accountCallbackCalled = false;
        when(() => userRepo.submitForReview('u1')).thenAnswer((_) async {});
        return DocumentsBloc(
          typesRepository: typesRepo,
          documentsRepository: docsRepo,
          userRepository: userRepo,
          bodyguardRepository: bodyguardRepo,
          owner: const AccountOwner('u1'),
          role: UserRole.guard,
          getCurrentUserId: () => 'u1',
          onAccountSubmitted: () => accountCallbackCalled = true,
        );
      },
      seed: () => const DocumentsState(
        types: [idType],
        uploaded: {
          'type-id': UserDocumentModel(
            id: 'doc-1',
            documentTypeId: 'type-id',
            fileUrl: 'https://x/id.jpg',
          ),
        },
        loadStatus: ApiState.success(null),
      ),
      act: (bloc) => bloc.add(const DocumentsSubmitted(submitApplication: true)),
      expect: () => [
        isA<DocumentsState>()
            .having((s) => s.submitStatus.isLoading, 'isLoading', true),
        isA<DocumentsState>()
            .having((s) => s.submitStatus.isSuccess, 'isSuccess', true),
      ],
      verify: (_) {
        expect(accountCallbackCalled, true);
        verify(() => userRepo.submitForReview('u1')).called(1);
      },
    );

    blocTest<DocumentsBloc, DocumentsState>(
      'Submitted for ManagedBodyguardOwner uses currentUserId for storage and calls BodyguardRepository.submitForReview',
      build: () {
        accountCallbackCalled = false;
        when(
          () => docsRepo.upload(
            storageUserId: 'company-user-1',
            owner: const ManagedBodyguardOwner('bg-1'),
            type: idType,
            file: pickedFile,
          ),
        ).thenAnswer(
          (_) async => const UserDocumentModel(
            id: 'doc-bg',
            bodyguardId: 'bg-1',
            documentTypeId: 'type-id',
            fileUrl: 'https://cdn/bg_id.jpg',
          ),
        );
        when(() => bodyguardRepo.submitForReview('bg-1'))
            .thenAnswer((_) async {});
        return DocumentsBloc(
          typesRepository: typesRepo,
          documentsRepository: docsRepo,
          userRepository: userRepo,
          bodyguardRepository: bodyguardRepo,
          owner: const ManagedBodyguardOwner('bg-1'),
          role: UserRole.guard,
          getCurrentUserId: () => 'company-user-1',
          onAccountSubmitted: () => accountCallbackCalled = true,
        );
      },
      seed: () => DocumentsState(
        types: const [idType],
        picked: {'type-id': pickedFile},
        loadStatus: const ApiState.success(null),
      ),
      act: (bloc) => bloc.add(const DocumentsSubmitted(submitApplication: true)),
      expect: () => [
        isA<DocumentsState>()
            .having((s) => s.submitStatus.isLoading, 'isLoading', true),
        isA<DocumentsState>()
            .having((s) => s.submitStatus.isSuccess, 'isSuccess', true)
            .having((s) => s.picked, 'picked', isEmpty)
            .having((s) => s.uploaded['type-id']?.id, 'uploaded id', 'doc-bg'),
      ],
      verify: (_) {
        expect(accountCallbackCalled, false);
        verify(() => bodyguardRepo.submitForReview('bg-1')).called(1);
        verifyNever(() => userRepo.submitForReview(any()));
      },
    );

    blocTest<DocumentsBloc, DocumentsState>(
      'Submitted emits failure carrying ApiException on upload error',
      build: () {
        when(
          () => docsRepo.upload(
            storageUserId: any(named: 'storageUserId'),
            owner: any(named: 'owner'),
            type: any(named: 'type'),
            file: any(named: 'file'),
          ),
        ).thenThrow(ApiException('Upload failed'));
        return DocumentsBloc(
          typesRepository: typesRepo,
          documentsRepository: docsRepo,
          userRepository: userRepo,
          bodyguardRepository: bodyguardRepo,
          owner: const AccountOwner('u1'),
          role: UserRole.guard,
          getCurrentUserId: () => 'u1',
        );
      },
      seed: () => DocumentsState(
        types: const [idType],
        picked: {'type-id': pickedFile},
        loadStatus: const ApiState.success(null),
      ),
      act: (bloc) => bloc.add(const DocumentsSubmitted()),
      expect: () => [
        isA<DocumentsState>()
            .having((s) => s.submitStatus.isLoading, 'isLoading', true),
        isA<DocumentsState>().having(
          (s) => s.submitStatus,
          'submitStatus',
          isA<ApiFailure<void>>()
              .having((f) => f.message, 'message', 'Upload failed')
              .having((f) => f.error, 'error', isA<ApiException>()),
        ),
      ],
    );
  });
}
