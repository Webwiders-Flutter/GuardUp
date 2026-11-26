import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/auth/data/enum/user_role.enum.dart';
import 'package:guardup/features/legal/bloc/contact_us/contact_us_bloc.dart';
import 'package:guardup/features/legal/bloc/contact_us/contact_us_event.dart';
import 'package:guardup/features/legal/bloc/contact_us/contact_us_state.dart';
import 'package:guardup/features/legal/bloc/legal_content/legal_content_bloc.dart';
import 'package:guardup/features/legal/bloc/legal_content/legal_content_event.dart';
import 'package:guardup/features/legal/bloc/legal_content/legal_content_state.dart';
import 'package:guardup/features/legal/data/enum/contact_us_status.enum.dart';
import 'package:guardup/features/legal/data/enum/content_type.enum.dart';
import 'package:guardup/features/legal/data/model/contact_us.model.dart';
import 'package:guardup/features/legal/data/model/contact_us_request.model.dart';
import 'package:guardup/features/legal/data/model/legal_content.model.dart';
import 'package:guardup/features/legal/data/repositories/contact_us.repository.dart';
import 'package:guardup/features/legal/data/repositories/legal_content.repository.dart';
import 'package:mocktail/mocktail.dart';

class MockLegalContentRepository extends Mock
    implements LegalContentRepository {}

class MockContactUsRepository extends Mock implements ContactUsRepository {}

class FakeContactUsRequest extends Fake implements ContactUsRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeContactUsRequest());
    registerFallbackValue(ContentType.privacyPolicy);
    registerFallbackValue(UserRole.customer);
  });

  group('LegalContentBloc', () {
    late MockLegalContentRepository mockRepo;

    setUp(() {
      mockRepo = MockLegalContentRepository();
    });

    final fallbackData = LegalContentModel.staticContent(ContentType.privacyPolicy);
    final dynamicModel = LegalContentModel(
      id: 'dynamic_id',
      contentType: ContentType.privacyPolicy,
      title: 'Dynamic Title',
      contentHtml: '<p>Dynamic content</p>',
      clauses: const [],
      updatedAt: DateTime(2026, 2, 1),
    );

    blocTest<LegalContentBloc, LegalContentState>(
      'emits loading then success with dynamic model from repository',
      build: () {
        when(
          () => mockRepo.getLatest(
            role: any(named: 'role'),
            type: any(named: 'type'),
            language: any(named: 'language'),
          ),
        ).thenAnswer((_) async => dynamicModel);
        return LegalContentBloc(
          repository: mockRepo,
          getCurrentRole: () => UserRole.customer,
        );
      },
      act: (bloc) => bloc.add(const LegalContentRequested(ContentType.privacyPolicy)),
      expect: () => [
        LegalContentState(
          contentState: ApiState.loading(previousData: fallbackData),
        ),
        LegalContentState(
          contentState: ApiState.success(dynamicModel),
        ),
      ],
      verify: (_) {
        verify(
          () => mockRepo.getLatest(
            role: UserRole.customer,
            type: ContentType.privacyPolicy,
            language: 'en',
          ),
        ).called(1);
      },
    );

    blocTest<LegalContentBloc, LegalContentState>(
      'falls back to staticContent when repository returns null',
      build: () {
        when(
          () => mockRepo.getLatest(
            role: any(named: 'role'),
            type: any(named: 'type'),
            language: any(named: 'language'),
          ),
        ).thenAnswer((_) async => null);
        return LegalContentBloc(
          repository: mockRepo,
          getCurrentRole: () => UserRole.guard,
        );
      },
      act: (bloc) => bloc.add(const LegalContentRequested(ContentType.privacyPolicy)),
      expect: () => [
        LegalContentState(
          contentState: ApiState.loading(previousData: fallbackData),
        ),
        LegalContentState(
          contentState: ApiState.success(fallbackData),
        ),
      ],
    );

    blocTest<LegalContentBloc, LegalContentState>(
      'falls back to staticContent when repository throws exception',
      build: () {
        when(
          () => mockRepo.getLatest(
            role: any(named: 'role'),
            type: any(named: 'type'),
            language: any(named: 'language'),
          ),
        ).thenThrow(Exception('Network error'));
        return LegalContentBloc(
          repository: mockRepo,
          getCurrentRole: () => UserRole.company,
        );
      },
      act: (bloc) => bloc.add(const LegalContentRequested(ContentType.privacyPolicy)),
      expect: () => [
        LegalContentState(
          contentState: ApiState.loading(previousData: fallbackData),
        ),
        LegalContentState(
          contentState: ApiState.success(fallbackData),
        ),
      ],
    );

    blocTest<LegalContentBloc, LegalContentState>(
      'respects role provided in event over callback',
      build: () {
        when(
          () => mockRepo.getLatest(
            role: any(named: 'role'),
            type: any(named: 'type'),
            language: any(named: 'language'),
          ),
        ).thenAnswer((_) async => dynamicModel);
        return LegalContentBloc(
          repository: mockRepo,
          getCurrentRole: () => UserRole.customer,
        );
      },
      act: (bloc) => bloc.add(
        const LegalContentRequested(ContentType.privacyPolicy, role: UserRole.guard),
      ),
      verify: (_) {
        verify(
          () => mockRepo.getLatest(
            role: UserRole.guard,
            type: ContentType.privacyPolicy,
            language: 'en',
          ),
        ).called(1);
      },
    );
  });

  group('ContactUsBloc', () {
    late MockContactUsRepository mockRepo;

    setUp(() {
      mockRepo = MockContactUsRepository();
    });

    final submission = ContactUsSubmission(
      fullName: 'John Doe',
      email: 'john@example.com',
      mobileNumber: '',
      message: 'Need bodyguard service info',
      submittedAt: DateTime(2026, 1, 1),
    );

    blocTest<ContactUsBloc, ContactUsState>(
      'emits loading then success when repository submit succeeds',
      build: () {
        when(() => mockRepo.submit(any())).thenAnswer((_) async {});
        return ContactUsBloc(
          repository: mockRepo,
          getCurrentUserId: () => 'user-456',
          getCurrentRole: () => UserRole.guard,
        );
      },
      act: (bloc) => bloc.add(SubmitContactUsRequested(submission)),
      expect: () => [
        const ContactUsState(submissionState: ApiState.loading()),
        const ContactUsState(
          submissionState: ApiState.success(
            'Your message has been sent successfully. Our support desk will contact you shortly.',
          ),
        ),
      ],
      verify: (_) {
        final captured = verify(() => mockRepo.submit(captureAny())).captured;
        expect(captured.length, 1);
        final request = captured.first as ContactUsRequest;
        expect(request.userId, 'user-456');
        expect(request.role, UserRole.guard);
        expect(request.fullName, 'John Doe');
        expect(request.email, 'john@example.com');
        expect(request.message, 'Need bodyguard service info');
        expect(request.status, ContactUsStatus.pending);
      },
    );

    final apiEx = ApiException('Submission failed due to server error');

    blocTest<ContactUsBloc, ContactUsState>(
      'emits failure when repository throws ApiException',
      build: () {
        when(() => mockRepo.submit(any())).thenThrow(apiEx);
        return ContactUsBloc(
          repository: mockRepo,
          getCurrentUserId: () => null,
          getCurrentRole: () => UserRole.customer,
        );
      },
      act: (bloc) => bloc.add(SubmitContactUsRequested(submission)),
      expect: () => [
        const ContactUsState(submissionState: ApiState.loading()),
        ContactUsState(
          submissionState: ApiState.failure(
            'Submission failed due to server error',
            error: apiEx,
          ),
        ),
      ],
    );
  });
}
