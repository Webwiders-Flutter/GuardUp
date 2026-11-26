import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/body_guard/bloc/availability/availability_bloc.dart';
import 'package:guardup/features/body_guard/data/enum/week_day.enum.dart';
import 'package:guardup/features/body_guard/data/model/availability_request.model.dart';
import 'package:guardup/features/body_guard/data/model/user_availability.model.dart';
import 'package:guardup/features/body_guard/data/repositories/availability.repository.dart';
import 'package:guardup/shared/models/record_owner.model.dart';
import 'package:mocktail/mocktail.dart';

class MockAvailabilityRepository extends Mock
    implements AvailabilityRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AccountOwner('fallback'));
    registerFallbackValue(<AvailabilityRequest>[]);
  });

  group('AvailabilityBloc', () {
    late MockAvailabilityRepository mockRepo;
    const owner = AccountOwner('user-1');

    setUp(() {
      mockRepo = MockAvailabilityRepository();
    });

    blocTest<AvailabilityBloc, AvailabilityState>(
      'Started defaults to Mon-Fri available when repository returns empty list',
      build: () {
        when(() => mockRepo.getFor(owner)).thenAnswer((_) async => const []);
        return AvailabilityBloc(mockRepo, owner: owner);
      },
      act: (bloc) => bloc.add(const AvailabilityStarted()),
      expect: () => [
        isA<AvailabilityState>()
            .having((s) => s.loadStatus.isLoading, 'isLoading', true),
        isA<AvailabilityState>()
            .having((s) => s.loadStatus.isSuccess, 'isSuccess', true)
            .having(
              (s) => s.selectedDays,
              'selectedDays',
              const [
                WeekDay.monday,
                WeekDay.tuesday,
                WeekDay.wednesday,
                WeekDay.thursday,
                WeekDay.friday,
              ],
            ),
      ],
    );

    blocTest<AvailabilityBloc, AvailabilityState>(
      'Started populates schedule from existing database rows',
      build: () {
        when(() => mockRepo.getFor(owner)).thenAnswer(
          (_) async => [
            const UserAvailabilityModel(
              id: '1',
              userId: 'user-1',
              dayOfWeek: WeekDay.saturday,
              isAvailable: true,
              fromTime: '10:00 AM',
              toTime: '06:00 PM',
            ),
          ],
        );
        return AvailabilityBloc(mockRepo, owner: owner);
      },
      act: (bloc) => bloc.add(const AvailabilityStarted()),
      expect: () => [
        isA<AvailabilityState>()
            .having((s) => s.loadStatus.isLoading, 'isLoading', true),
        isA<AvailabilityState>()
            .having((s) => s.loadStatus.isSuccess, 'isSuccess', true)
            .having((s) => s.selectedDays, 'selectedDays', const [WeekDay.saturday])
            .having(
              (s) => s.schedule[WeekDay.saturday]?.fromTime,
              'saturday from',
              '10:00 AM',
            )
            .having(
              (s) => s.schedule[WeekDay.saturday]?.toTime,
              'saturday to',
              '06:00 PM',
            ),
      ],
    );

    blocTest<AvailabilityBloc, AvailabilityState>(
      'DayToggled and TimeChanged update schedule draft',
      build: () => AvailabilityBloc(mockRepo, owner: owner),
      act: (bloc) => bloc
        ..add(const AvailabilityDayToggled(WeekDay.monday))
        ..add(
          const AvailabilityTimeChanged(
            WeekDay.monday,
            fromTime: '08:00 AM',
            toTime: '04:00 PM',
          ),
        ),
      expect: () => [
        isA<AvailabilityState>().having(
          (s) => s.schedule[WeekDay.monday]?.isAvailable,
          'monday available',
          true,
        ),
        isA<AvailabilityState>()
            .having(
              (s) => s.schedule[WeekDay.monday]?.fromTime,
              'fromTime',
              '08:00 AM',
            )
            .having(
              (s) => s.schedule[WeekDay.monday]?.toTime,
              'toTime',
              '04:00 PM',
            ),
      ],
    );

    blocTest<AvailabilityBloc, AvailabilityState>(
      'Saved persists 7 rows via AvailabilityRepository',
      build: () {
        when(() => mockRepo.save(owner, any()))
            .thenAnswer((_) async => const []);
        return AvailabilityBloc(mockRepo, owner: owner);
      },
      act: (bloc) => bloc
        ..add(const AvailabilityDayToggled(WeekDay.monday))
        ..add(const AvailabilitySaved()),
      expect: () => [
        isA<AvailabilityState>().having(
          (s) => s.schedule[WeekDay.monday]?.isAvailable,
          'monday',
          true,
        ),
        isA<AvailabilityState>()
            .having((s) => s.saveStatus.isLoading, 'isLoading', true),
        isA<AvailabilityState>()
            .having((s) => s.saveStatus.isSuccess, 'isSuccess', true),
      ],
      verify: (_) {
        final requests = verify(() => mockRepo.save(owner, captureAny()))
            .captured
            .single as List<AvailabilityRequest>;
        expect(requests.length, 7);
        final mon = requests.firstWhere((r) => r.dayOfWeek == WeekDay.monday);
        expect(mon.isAvailable, true);
      },
    );

    blocTest<AvailabilityBloc, AvailabilityState>(
      'Saved emits failure carrying ApiException on error',
      build: () {
        when(() => mockRepo.save(owner, any()))
            .thenThrow(ApiException('Save failed'));
        return AvailabilityBloc(mockRepo, owner: owner);
      },
      act: (bloc) => bloc.add(const AvailabilitySaved()),
      expect: () => [
        isA<AvailabilityState>()
            .having((s) => s.saveStatus.isLoading, 'isLoading', true),
        isA<AvailabilityState>().having(
          (s) => s.saveStatus,
          'saveStatus',
          isA<ApiFailure<void>>()
              .having((f) => f.message, 'message', 'Save failed')
              .having((f) => f.error, 'error', isA<ApiException>()),
        ),
      ],
    );
  });
}
