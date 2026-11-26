import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/constants/app_constants.dart';
import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/notifications/bloc/notifications/notifications_bloc.dart';
import 'package:guardup/features/notifications/bloc/notifications/notifications_event.dart';
import 'package:guardup/features/notifications/bloc/notifications/notifications_state.dart';
import 'package:guardup/features/notifications/bloc/unread_count/unread_notification_count_cubit.dart';
import 'package:guardup/features/notifications/data/enums/notification_type.enum.dart';
import 'package:guardup/features/notifications/data/models/notification.model.dart';
import 'package:guardup/features/notifications/data/models/notification_filters.model.dart';
import 'package:guardup/features/notifications/data/repositories/notification_repository.dart';
import 'package:guardup/shared/widgets/pagination/pagination.state.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class FakeNotificationFilters extends Fake implements NotificationFilters {}

NotificationModel _makeNotification({
  required String id,
  bool isRead = false,
}) {
  return NotificationModel(
    id: id,
    userId: 'user-1',
    type: NotificationType.system,
    title: 'Title $id',
    body: 'Body $id',
    isRead: isRead,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeNotificationFilters());
  });

  group('UnreadNotificationCountCubit', () {
    late MockNotificationRepository mockRepo;

    setUp(() {
      mockRepo = MockNotificationRepository();
    });

    test('loadCount emits unread count from repository', () async {
      when(() => mockRepo.getUnreadCount('user-1')).thenAnswer((_) async => 5);
      final cubit = UnreadNotificationCountCubit(repository: mockRepo);

      await cubit.loadCount('user-1');
      expect(cubit.state, 5);

      cubit.decrement(decreaseBy: 3);
      expect(cubit.state, 2);

      cubit.decrement(decreaseBy: 10);
      expect(cubit.state, 0);

      cubit.increment(increaseBy: 4);
      expect(cubit.state, 4);

      cubit.clearAll();
      expect(cubit.state, 0);

      await cubit.close();
    });
  });

  group('NotificationsBloc', () {
    late MockNotificationRepository mockRepo;
    late UnreadNotificationCountCubit unreadCubit;

    setUp(() {
      mockRepo = MockNotificationRepository();
      unreadCubit = UnreadNotificationCountCubit(repository: mockRepo);
    });

    tearDown(() async {
      await unreadCubit.close();
    });

    blocTest<NotificationsBloc, NotificationsState>(
      'emits empty success when userId is empty without calling repository',
      build: () => NotificationsBloc(
        repository: mockRepo,
        getUserId: () => '',
        unreadCountCubit: unreadCubit,
      ),
      act: (bloc) => bloc.add(const NotificationsFetchRequested()),
      expect: () => [
        const NotificationsState(
          activeCategory: NotificationCategory.all,
          paginationState: PaginationState<NotificationModel>(
            items: [],
            total: 0,
            page: 1,
            pageSize: AppConstants.paginationLimit,
            status: ApiState.success(null),
          ),
        ),
      ],
      verify: (_) {
        verifyNever(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
          ),
        );
      },
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'fetch emits loading then success with items',
      build: () {
        final item = _makeNotification(id: 'n1');
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
          ),
        ).thenAnswer((_) async => (data: [item], total: 1));
        return NotificationsBloc(
          repository: mockRepo,
          getUserId: () => 'user-1',
          unreadCountCubit: unreadCubit,
        );
      },
      act: (bloc) => bloc.add(const NotificationsFetchRequested()),
      expect: () => [
        const NotificationsState(
          activeCategory: NotificationCategory.all,
          paginationState: PaginationState<NotificationModel>(
            status: ApiState.loading(),
          ),
        ),
        NotificationsState(
          activeCategory: NotificationCategory.all,
          paginationState: PaginationState<NotificationModel>(
            items: [_makeNotification(id: 'n1')],
            total: 1,
            page: 1,
            pageSize: AppConstants.paginationLimit,
            status: const ApiState.success(null),
          ),
        ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'fetch emits failure carrying ApiException on error',
      build: () {
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
          ),
        ).thenThrow(ApiException('Server down', type: ApiErrorType.server));
        return NotificationsBloc(
          repository: mockRepo,
          getUserId: () => 'user-1',
        );
      },
      act: (bloc) => bloc.add(const NotificationsFetchRequested()),
      expect: () => [
        const NotificationsState(
          activeCategory: NotificationCategory.all,
          paginationState: PaginationState<NotificationModel>(
            status: ApiState.loading(),
          ),
        ),
        isA<NotificationsState>().having(
          (s) => s.paginationState.status,
          'status',
          isA<ApiFailure<void>>()
              .having((f) => f.message, 'message', 'Server down')
              .having((f) => f.error, 'error', isA<ApiException>()),
        ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'restartable fetch cancels stale in-flight request',
      build: () {
        var callCount = 0;
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return (data: [_makeNotification(id: 'stale')], total: 1);
          }
          return (data: [_makeNotification(id: 'fresh')], total: 1);
        });
        return NotificationsBloc(
          repository: mockRepo,
          getUserId: () => 'user-1',
        );
      },
      act: (bloc) async {
        bloc.add(const NotificationsFetchRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const NotificationsFetchRequested(refresh: true));
        await Future<void>.delayed(const Duration(milliseconds: 80));
      },
      expect: () => [
        const NotificationsState(
          paginationState: PaginationState<NotificationModel>(
            status: ApiState.loading(),
          ),
        ),
        NotificationsState(
          paginationState: PaginationState<NotificationModel>(
            items: [_makeNotification(id: 'fresh')],
            total: 1,
            page: 1,
            pageSize: AppConstants.paginationLimit,
            status: const ApiState.success(null),
          ),
        ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'deleteMany decrements unread count once by unreadDeletedCount and rolls back on failure',
      build: () {
        unreadCubit.increment(increaseBy: 3);
        when(() => mockRepo.deleteMany(any()))
            .thenThrow(ApiException('Delete failed'));
        return NotificationsBloc(
          repository: mockRepo,
          getUserId: () => 'user-1',
          unreadCountCubit: unreadCubit,
        );
      },
      seed: () => NotificationsState(
        paginationState: PaginationState<NotificationModel>(
          items: [
            _makeNotification(id: 'n1', isRead: false),
            _makeNotification(id: 'n2', isRead: true),
            _makeNotification(id: 'n3', isRead: false),
          ],
          total: 3,
          page: 1,
          status: const ApiState.success(null),
        ),
      ),
      act: (bloc) =>
          bloc.add(const NotificationsDeleteManyRequested(['n1', 'n2', 'n3'])),
      expect: () => [
        const NotificationsState(
          paginationState: PaginationState<NotificationModel>(
            items: [],
            total: 0,
            page: 1,
            status: ApiState.success(null),
          ),
          actionStatus: ApiState.loading(),
        ),
        isA<NotificationsState>()
            .having((s) => s.paginationState.items.length, 'items length', 3)
            .having(
              (s) => s.actionStatus,
              'actionStatus',
              isA<ApiFailure<void>>()
                  .having((f) => f.message, 'message', 'Delete failed')
                  .having((f) => f.error, 'error', isA<ApiException>()),
            ),
      ],
      verify: (_) {
        // Rolled back 2 unread deletions -> back to 3
        expect(unreadCubit.state, 3);
      },
    );
  });
}
