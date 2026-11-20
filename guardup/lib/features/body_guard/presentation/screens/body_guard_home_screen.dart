import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/features/auth/auth.dart';
import '/features/booking/booking.dart';
import '/features/payments/payments.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '/features/chat/presentation/screens/chat_screen.dart';

/// Operative dashboard / home screen presenting:
/// - Header profile in [AppAppBar] with online status badge and notifications
/// - Metric overview cards (Earnings, Bookings, Rating) using [WrapperCard]
/// - Latest bookings feed powered by [AppPagination] and [BookingCard] (guard perspective)
/// - Transaction history feed powered by [AppPagination] and [TransactionCard.card]
class BodyGuardHomeScreen extends StatefulWidget {
  /// Shared `/home` route: one shell tab whose builder in `app_router.dart`
  /// shows the customer, company or bodyguard home based on the session role.
  static const route = '/home';

  const BodyGuardHomeScreen({super.key});

  @override
  State<BodyGuardHomeScreen> createState() => _BodyGuardHomeScreenState();
}

class _BodyGuardHomeScreenState extends State<BodyGuardHomeScreen> {
  late final PaginationController<BookingModel> _bookingsPaginationController;
  late final PaginationController<TransactionModel>
  _transactionsPaginationController;

  @override
  void initState() {
    super.initState();

    _bookingsPaginationController = PaginationController<BookingModel>(
      initialState: PaginationState<BookingModel>(
        items: BookingModel.fakeData.take(3).toList(),
        total: 3,
        status: const ApiState.success(null),
      ),
    );

    _transactionsPaginationController = PaginationController<TransactionModel>(
      initialState: PaginationState<TransactionModel>(
        items: TransactionModel.fakeData.take(5).toList(),
        total: 3,
        status: const ApiState.success(null),
      ),
    );
  }

  @override
  void dispose() {
    _bookingsPaginationController.dispose();
    _transactionsPaginationController.dispose();
    super.dispose();
  }

  // ── Guard Clickflow Handlers ───────────────────────────────────────────────

  void _handleAcceptBooking(BookingModel booking) {}

  void _handleRejectBooking(BookingModel booking) {}

  void _handleChatBooking(BookingModel booking) {
    context.push(ChatScreen.route);
  }

  void _handleShareLocation(BookingModel booking) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        automaticallyImplyLeading: false,
        alignTitle: .left,
        titleWidget: _buildAppBarTitle(context),
        showNotificationIcon: true,
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 2),
          child: QuickContainer(color: context.colors.outlineVariant, h: 0.5),
        ),
        actions: [_buildOnlineStatusBadge(context)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.lg.h,

              // ---------------------------------------------------------------
              // 1. Overview Metric Cards (Earnings, Bookings, Rating)
              // ---------------------------------------------------------------
              _buildMetricCards(context),
              AppSpacing.xl.h,

              // ---------------------------------------------------------------
              // 2. Latest Bookings Section Header
              // ---------------------------------------------------------------
              Padding(
                padding: context.horizontalEdgeInsets,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LATEST BOOKINGS',
                      style: context.textTheme.labelMedium
                          ?.bold()
                          .copyWith(letterSpacing: 1.2)
                          .colour(context.colors.onSurfaceVariant),
                    ),
                    AppButton(
                      text: 'View All >',
                      type: ButtonType.text,
                      size: ButtonSize.small,
                      onPressed: () => context.jumpToNavTab(1),
                    ),
                  ],
                ),
              ),
              AppSpacing.xs.h,

              // ---------------------------------------------------------------
              // 3. Latest Bookings Feed using AppPagination.list
              // ---------------------------------------------------------------
              AppPagination<BookingModel>.list(
                controller: _bookingsPaginationController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: context.horizontalEdgeInsets,
                separatorBuilder: (context, index) => AppSpacing.md.h,
                emptyBuilder: (context) => Center(
                  child: Padding(
                    padding: AppSpacing.lg.allPadding,
                    child: Text(
                      'No bookings available.',
                      style: context.textTheme.bodySmall?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                itemBuilder: (context, booking, index) {
                  return BookingCard(
                    booking: booking,
                    role: UserRole.guard,
                    onAccept: () => _handleAcceptBooking(booking),
                    onReject: () => _handleRejectBooking(booking),
                    onChat: () => _handleChatBooking(booking),
                    onShareLocation: () => _handleShareLocation(booking),
                  );
                },
              ),
              AppSpacing.xl.h,

              // ---------------------------------------------------------------
              // 4. Transaction History Section Header
              // ---------------------------------------------------------------
              Padding(
                padding: context.horizontalEdgeInsets,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TRANSACTION HISTORY',
                      style: context.textTheme.labelMedium
                          ?.bold()
                          .copyWith(letterSpacing: 1.2)
                          .colour(context.colors.onSurfaceVariant),
                    ),
                    AppButton(
                      text: 'View All >',
                      type: ButtonType.text,
                      size: ButtonSize.small,
                      onPressed: () => context.push(MyWalletScreen.route),
                    ),
                  ],
                ),
              ),
              AppSpacing.xs.h,

              // ---------------------------------------------------------------
              // 5. Transaction History Feed using AppPagination.list
              // ---------------------------------------------------------------
              AppPagination<TransactionModel>.list(
                controller: _transactionsPaginationController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: context.horizontalEdgeInsets + AppSpacing.xxl.bPadding,
                separatorBuilder: (context, index) => AppSpacing.md.h,
                emptyBuilder: (context) => Center(
                  child: Padding(
                    padding: AppSpacing.lg.allPadding,
                    child: Text(
                      'No recent transactions.',
                      style: context.textTheme.bodySmall?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                itemBuilder: (context, transaction, index) {
                  return TransactionCard.card(
                    transaction: transaction,
                    onTap: () => context.push(MyWalletScreen.route),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SUBCOMPONENTS
  // ===========================================================================

  Widget _buildAppBarTitle(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      bloc: sl<AuthBloc>(),
      builder: (context, state) {
        final guardName = state.user?.name ?? state.displayName;
        final avatar = state.avatarUrl;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => context.go(ProfileScreen.route),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.primary, width: 1.5),
                ),
                child: AppImage.auto(
                  source: avatar.isNotEmpty
                      ? avatar
                      : Assets.images.profilePicture2.path,
                  width: 36,
                  height: 36,
                  shape: BoxShape.circle,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            AppSpacing.sm.w,
            Flexible(
              child: Text(
                guardName.isNotEmpty ? 'Hello, $guardName' : 'Dashboard',
                style: context.textTheme.titleLarge?.bold(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOnlineStatusBadge(BuildContext context) {
    return QuickContainer(
      radius: AppRadius.full,
      color: context.colors.surface,
      border: Border.all(
        color: context.colors.success.withValues(alpha: 0.4),
        width: 1.0,
      ),
      px: AppSpacing.sm,
      py: 6.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuickContainer(
            shape: QuickContainerShape.circle,
            color: context.colors.success,
            w: 6,
            h: 6,
          ),
          AppSpacing.xs.w,
          Text(
            'ONLINE',
            style: context.textTheme.labelSmall
                ?.bold()
                .copyWith(fontSize: 10, letterSpacing: 0.8)
                .colour(context.colors.success),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(BuildContext context) {
    return Padding(
      padding: context.horizontalEdgeInsets,
      child: Row(
        children: [
          // Earnings Card ($2,480)
          Expanded(
            child: WrapperCard(
              onTap: () => context.push(MyWalletScreen.route),
              padding: AppSpacing.lg.allPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Earnings',
                    style: context.textTheme.labelSmall?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.xs.h,
                  Text(
                    2480.0.toUsd,
                    style: context.textTheme.titleMedium?.bold().colour(
                      context.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.sm.w,

          // Bookings Card (12)
          Expanded(
            child: WrapperCard(
              onTap: () => context.go(BookingsScreen.route),
              padding: AppSpacing.lg.allPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bookings',
                    style: context.textTheme.labelSmall?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.xs.h,
                  Text('12', style: context.textTheme.titleMedium?.bold()),
                ],
              ),
            ),
          ),
          AppSpacing.sm.w,

          // Rating Card (4.8 ★)
          Expanded(
            child: WrapperCard(
              padding: AppSpacing.lg.allPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rating',
                    style: context.textTheme.labelSmall?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.xs.h,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('4.8', style: context.textTheme.titleMedium?.bold()),
                      AppSpacing.xxs.w,
                      Icon(
                        Icons.star_rounded,
                        size: AppSizes.iconSm,
                        color: context.colors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
