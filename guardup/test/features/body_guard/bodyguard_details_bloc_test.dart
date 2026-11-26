import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/body_guard/bloc/bodyguard_details/bodyguard_details_bloc.dart';
import 'package:guardup/features/body_guard/data/model/body_guard.model.dart';
import 'package:guardup/features/body_guard/data/repositories/bodyguard.repository.dart';
import 'package:mocktail/mocktail.dart';

class MockBodyguardRepository extends Mock implements BodyguardRepository {}

void main() {
  group('BodyguardDetailsBloc', () {
    late MockBodyguardRepository mockRepo;

    setUp(() {
      mockRepo = MockBodyguardRepository();
    });

    const preview = BodyGuardModel(
      id: 'g1',
      name: 'Preview Guard',
      hourlyRate: 45.0,
    );

    const detailed = BodyGuardModel(
      id: 'g1',
      name: 'Detailed Guard',
      hourlyRate: 50.0,
      bio: 'Full bio',
    );

    blocTest<BodyguardDetailsBloc, BodyguardDetailsState>(
      'emits loading then success when started without preview',
      build: () {
        when(() => mockRepo.getDetails('g1')).thenAnswer((_) async => detailed);
        return BodyguardDetailsBloc(mockRepo, bodyguardId: 'g1');
      },
      act: (bloc) => bloc.add(const BodyguardDetailsStarted()),
      expect: () => [
        const BodyguardDetailsState(status: ApiState.loading()),
        const BodyguardDetailsState(
          guard: detailed,
          status: ApiState.success(detailed),
        ),
      ],
    );

    blocTest<BodyguardDetailsBloc, BodyguardDetailsState>(
      'keeps preview guard while loading in background and updates on success',
      build: () {
        when(() => mockRepo.getDetails('g1')).thenAnswer((_) async => detailed);
        return BodyguardDetailsBloc(
          mockRepo,
          bodyguardId: 'g1',
          preview: preview,
        );
      },
      act: (bloc) => bloc.add(const BodyguardDetailsStarted()),
      expect: () => [
        const BodyguardDetailsState(
          guard: preview,
          status: ApiState.loading(previousData: preview),
        ),
        const BodyguardDetailsState(
          guard: detailed,
          status: ApiState.success(detailed),
        ),
      ],
    );

    blocTest<BodyguardDetailsBloc, BodyguardDetailsState>(
      'emits failure with ApiException when loading fails without preview',
      build: () {
        when(() => mockRepo.getDetails('g1'))
            .thenThrow(ApiException('Bodyguard not found'));
        return BodyguardDetailsBloc(mockRepo, bodyguardId: 'g1');
      },
      act: (bloc) => bloc.add(const BodyguardDetailsStarted()),
      expect: () => [
        const BodyguardDetailsState(status: ApiState.loading()),
        isA<BodyguardDetailsState>()
            .having((s) => s.isFailure, 'isFailure', true)
            .having((s) => s.guard, 'guard', isNull)
            .having(
              (s) => s.status.errorMessageOrNull,
              'message',
              'Bodyguard not found',
            ),
      ],
    );

    blocTest<BodyguardDetailsBloc, BodyguardDetailsState>(
      'preserves preview guard when refresh fails',
      build: () {
        when(() => mockRepo.getDetails('g1'))
            .thenThrow(ApiException('Network error'));
        return BodyguardDetailsBloc(
          mockRepo,
          bodyguardId: 'g1',
          preview: preview,
        );
      },
      act: (bloc) => bloc.add(const BodyguardDetailsRefreshed()),
      expect: () => [
        const BodyguardDetailsState(
          guard: preview,
          status: ApiState.loading(previousData: preview),
        ),
        isA<BodyguardDetailsState>()
            .having((s) => s.guard, 'guard', preview)
            .having((s) => s.isFailure, 'isFailure', false)
            .having((s) => s.status.isFailure, 'status.isFailure', true),
      ],
    );

    blocTest<BodyguardDetailsBloc, BodyguardDetailsState>(
      'emits failure when bodyguardId is empty and no preview is given',
      build: () => BodyguardDetailsBloc(mockRepo, bodyguardId: ''),
      act: (bloc) => bloc.add(const BodyguardDetailsStarted()),
      expect: () => [
        const BodyguardDetailsState(
          status: ApiState.failure('Bodyguard not found.'),
        ),
      ],
      verify: (_) {
        verifyNever(() => mockRepo.getDetails(any()));
      },
    );
  });
}

