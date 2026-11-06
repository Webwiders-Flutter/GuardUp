import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '/features/booking/booking.dart';
import '/features/notifications/presentation/widgets/notification_icon.widget.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';

/// Company operational dashboard / home screen presenting:
/// - Company header profile in [AppAppBar]
/// - Operative & booking overview cards in [WrapperCard]
/// - Latest bookings section with live search and paginated feed using [AppPagination] and [BookingCard]
/// - My bodyguards roster section with paginated feed using [AppPagination] and [BodyGuardCard]
class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  final _bookingSearchController = TextEditingController();

  late final PaginationController<BookingModel> _bookingsPaginationController;
  late final PaginationController<BodyGuardModel>
  _bodyguardsPaginationController;
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

    _bodyguardsPaginationController = PaginationController<BodyGuardModel>(
      initialState: PaginationState<BodyGuardModel>(
        items: BodyGuardModel.fakeData.take(3).toList(),
        total: 3,
        status: const ApiState.success(null),
      ),
    );
  }

  @override
  void dispose() {
    _bookingSearchController.dispose();
    _bookingsPaginationController.dispose();
    _bodyguardsPaginationController.dispose();
    super.dispose();
  }
  // ── Clickflow Handlers ─────────────────────────────────────────────────────

  void _handleAcceptBooking(BookingModel booking) {}

  void _handleRejectBooking(BookingModel booking) {}

  void _handleChatBooking(BookingModel booking) {
    context.push(AppRoutes.chat);
  }

  void _handleShareLocation(BookingModel booking) {}

  void _handleEditBodyguard(BodyGuardModel bodyguard) {
    context.push(AppRoutes.bodyguardProfile);
  }

  void _handleDeleteBodyguard(BodyGuardModel bodyguard) {
    final updated = List<BodyGuardModel>.from(
      _bodyguardsPaginationController.value.items,
    )..removeWhere((g) => g.id == bodyguard.id);

    _bodyguardsPaginationController.updateState(
      _bodyguardsPaginationController.value.copyWith(
        items: updated,
        total: updated.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        automaticallyImplyLeading: false,
        alignTitle: .left,
        titleWidget: _buildAppBarTitle(context),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: NotificationIconWidget(count: 3),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.xlg.h,

              // ---------------------------------------------------------------
              // 1. Upper Overview Cards (Bodyguard & Bookings) in WrapperCard
              // ---------------------------------------------------------------
              _buildUpperOverviewCards(context),
              AppSpacing.xl.h,

              // ---------------------------------------------------------------
              // 2. Latest Booking Section Header
              // ---------------------------------------------------------------
              Padding(
                padding: context.horizontalEdgeInsets,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LATEST BOOKING',
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
              // 3. Search Bar (referencing Booking Screen)
              // ---------------------------------------------------------------
              Padding(
                padding: context.horizontalEdgeInsets,
                child: AppTextField.search(
                  controller: _bookingSearchController,
                  size: AppInputSize.small,
                  decoration: InputDecoration(
                    hintText: 'Search by name, clearance, or skill...',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.xl.toBorderRadius,
                      borderSide: BorderSide(
                        color: context.colors.outlineVariant,
                      ),
                    ),
                    fillColor: context.colors.onPrimary,
                  ),
                  style: TextStyle(color: context.colors.onSurface),
                ),
              ),
              AppSpacing.md.h,

              // ---------------------------------------------------------------
              // 4. Latest Bookings Feed using AppPagination.list
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
                      'No matching bookings found.',
                      style: context.textTheme.bodySmall?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                itemBuilder: (context, booking, index) {
                  return BookingCard(
                    booking: booking,
                    role: UserRole.company,
                    onAccept: () => _handleAcceptBooking(booking),
                    onReject: () => _handleRejectBooking(booking),
                    onChat: () => _handleChatBooking(booking),
                    onShareLocation: () => _handleShareLocation(booking),
                  );
                },
              ),
              AppSpacing.xl.h,

              // ---------------------------------------------------------------
              // 5. My Bodyguards Section Header
              // ---------------------------------------------------------------
              Padding(
                padding: context.horizontalEdgeInsets,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MY BODYGUARDS',
                      style: context.textTheme.labelMedium
                          ?.bold()
                          .copyWith(letterSpacing: 1.2)
                          .colour(context.colors.onSurfaceVariant),
                    ),
                    AppButton(
                      text: 'View All >',
                      type: ButtonType.text,
                      size: ButtonSize.small,
                      onPressed: () => context.push(AppRoutes.allBodyguards),
                    ),
                  ],
                ),
              ),
              AppSpacing.sm.h,

              // ---------------------------------------------------------------
              // 6. My Bodyguards Feed using AppPagination.list
              // ---------------------------------------------------------------
              AppPagination<BodyGuardModel>.list(
                controller: _bodyguardsPaginationController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: context.horizontalEdgeInsets + AppSpacing.xxl.bPadding,
                separatorBuilder: (context, index) => AppSpacing.md.h,
                emptyBuilder: (context) => Center(
                  child: Padding(
                    padding: AppSpacing.lg.allPadding,
                    child: Text(
                      'No bodyguards found.',
                      style: context.textTheme.bodySmall?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                itemBuilder: (context, guard, index) {
                  return BodyGuardCard(
                    bodyguard: guard,
                    onTap: () => _handleEditBodyguard(guard),
                    onEdit: () => _handleEditBodyguard(guard),
                    onDelete: () => _handleDeleteBodyguard(guard),
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
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            QuickContainer(
              shape: QuickContainerShape.circle,
              w: 48,
              h: 48,
              color: context.colors.surfaceContainerHigh,
              border: Border.all(color: context.colors.primary, width: 1.5),
              alignment: Alignment.center,
              child: Text(
                'SP',
                style: context.textTheme.titleSmall?.bold().colour(
                  context.colors.primary,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: QuickContainer(
                shape: QuickContainerShape.circle,
                color: context.colors.surface,
                p: 1.5,
                child: QuickContainer(
                  shape: QuickContainerShape.circle,
                  color: context.colors.success,
                  w: 8,
                  h: 8,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.md.w,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'SecurePro Security Ltd.',
                      style: context.textTheme.titleMedium
                          ?.medium()
                          .increaseLetterSpacing(1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.xxs.w,
                  Icon(
                    Icons.shield_rounded,
                    size: AppSizes.iconXs,
                    color: context.colors.primary,
                  ),
                ],
              ),
              AppSpacing.xxs.h,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: AppSizes.iconXs,
                    color: context.colors.primary,
                  ),
                  AppSpacing.xs.w,
                  Text('4.93', style: context.textTheme.labelSmall),
                  Text(
                    '  •  ',
                    style: context.textTheme.labelLarge?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '214 reviews',
                    style: context.textTheme.labelSmall?.regular().colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpperOverviewCards(BuildContext context) {
    return Padding(
      padding: context.horizontalEdgeInsets,
      child: Row(
        children: [
          Expanded(
            child: WrapperCard(
              onTap: () => context.push(AppRoutes.allBodyguards),
              padding: AppSpacing.xlg.allPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bodyguard',
                    style: context.textTheme.titleMedium?.semiBold(),
                  ),
                  AppSpacing.xs.h,
                  Text(
                    '12 Active Operatives',
                    style: context.textTheme.labelSmall?.regular().colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.md.w,
          Expanded(
            child: WrapperCard(
              onTap: () => context.go(AppRoutes.bookings),
              padding: AppSpacing.xlg.allPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bookings',
                    style: context.textTheme.titleMedium?.semiBold(),
                  ),
                  AppSpacing.xs.h,
                  Text(
                    'Direct & Elite Security',
                    style: context.textTheme.labelSmall?.regular().colour(
                      context.colors.onSurfaceVariant,
                    ),
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
