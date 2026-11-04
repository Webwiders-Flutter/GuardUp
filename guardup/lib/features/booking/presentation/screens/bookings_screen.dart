import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:guardup/shared/widgets/sections/app_appbar.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/features/auth/auth.dart';
import '/features/rating_and_reviews/rating_and_reviews.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '../../data/model/booking.model.dart';
import '../widgets/booking_card.widget.dart';

/// Screen presenting the operative or customer booking assignments.
///
/// Features live search via [AppTextField.search], status filtering via
/// [AppTabBar.pill], and infinite paginated feeds via [AppPagination].
///
/// Automatically adapts its card layout according to the authenticated [UserRole]:
/// - **Customer Role ([UserRole.customer])**:
///   Displays operative-centric booking cards with ratings, verified badges,
///   live tracking, rate & review CTAs, and rebooking actions.
/// - **Guard / Operative Role ([UserRole.guard])**:
///   Displays client-centric booking cards with accept/reject request actions
///   and telemetry sharing.
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  late final PaginationController<BookingModel> _paginationController;

  static const List<String> _tabNames = [
    'All (18)',
    'Running',
    'Completed',
    'Pending',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabNames.length, vsync: this);

    // Resolve initial role from override, session, or default to customer
    final sessionRole = sl.isRegistered<AuthBloc>()
        ? sl<AuthBloc>().state.sessionRole
        : null;
    final initialRole = sessionRole ?? UserRole.guard;

    final initialItems = initialRole == UserRole.customer
        ? List<BookingModel>.from(BookingModel.fakeCustomerBookings)
        : List<BookingModel>.from(BookingModel.fakeBookings);

    _paginationController = PaginationController<BookingModel>(
      initialState: PaginationState<BookingModel>(
        items: initialItems,
        total: initialItems.length,
        status: const ApiState.success(null),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _paginationController.dispose();
    super.dispose();
  }

  // ── Guard Action Handlers ──────────────────────────────────────────────────
  void _handleAcceptBooking(BookingModel booking) {
    // Clickflow handler: push target route when screen is available
  }

  void _handleRejectBooking(BookingModel booking) {
    // Clickflow handler: push target route when screen is available
  }

  void _handleShareLocation(BookingModel booking) {
    // Clickflow handler: push target route when screen is available
  }

  // ── Customer Action Handlers ───────────────────────────────────────────────
  void _handleRateAndReview(BookingModel booking) {
    RateExperienceWidget.showDialog(
      context: context,
      booking: booking,
      bodyguard: booking.bodyguard,
    );
  }

  void _handleBookAgain(BookingModel booking) {
    // Clickflow handler: push target route when screen is available
  }

  void _handleTrackLocation(BookingModel booking) {
    // Clickflow handler: push target route when screen is available
  }

  void _handleCancelRequest(BookingModel booking) {
    // Clickflow handler: push target route when screen is available
  }

  void _handleOpenChat(BookingModel booking) {
    context.push(AppRoutes.chat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(title: 'Booking', alignTitle: .left),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -----------------------------------------------------------------
            // 2. Search Field using AppTextField.search (matching conversation screen)
            // -----------------------------------------------------------------
            Padding(
              padding: context.horizontalEdgeInsets,
              child: AppTextField.search(
                controller: _searchController,
                size: AppInputSize.small,
                style: TextStyle(color: context.colors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search by name, clearance, or skill...',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.xl.toBorderRadius,
                    borderSide: BorderSide(
                      color: context.colors.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.xl.toBorderRadius,
                    borderSide: BorderSide(
                      color: context.colors.outlineVariant,
                    ),
                  ),
                  fillColor: context.colors.surface,
                ),
              ),
            ),
            AppSpacing.md.h,

            // -----------------------------------------------------------------
            // 3. Status Filter Tabs using AppTabBar.pill
            // -----------------------------------------------------------------
            Padding(
              padding: context.horizontalEdgeInsets,
              child: AppTabBar.pill(
                controller: _tabController,
                tabNames: _tabNames,
                isScrollable: false,
                spacing: AppSpacing.sm,
              ),
            ),
            AppSpacing.md.h,

            // -----------------------------------------------------------------
            // 4. Paginated Bookings Feed using AppPagination.list
            // -----------------------------------------------------------------
            Expanded(
              child: AppPagination<BookingModel>.list(
                controller: _paginationController,
                padding: context.horizontalEdgeInsets + AppSpacing.lg.bPadding,
                separatorBuilder: (context, index) => AppSpacing.md.h,
                emptyBuilder: (context) => Center(
                  child: Padding(
                    padding: AppSpacing.xxl.allPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: AppSizes.icon2Xl,
                          color: context.colors.outline,
                        ),
                        AppSpacing.md.h,
                        Text(
                          'No bookings found',
                          style: context.textTheme.titleSmall?.semiBold(),
                        ),
                        AppSpacing.xs.h,
                        Text(
                          'Try adjusting your search or tab filters.',
                          style: context.textTheme.bodySmall?.colour(
                            context.colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                itemBuilder: (context, booking, index) {
                  return BookingCard(
                    booking: booking,
                    role:
                        (sl.isRegistered<AuthBloc>()
                            ? sl<AuthBloc>().state.sessionRole
                            : null) ??
                        UserRole.customer,
                    // Guard Callbacks
                    onAccept: () => _handleAcceptBooking(booking),
                    onReject: () => _handleRejectBooking(booking),
                    onShareLocation: () => _handleShareLocation(booking),
                    // Customer Callbacks
                    onRateAndReview: () => _handleRateAndReview(booking),
                    onBookAgain: () => _handleBookAgain(booking),
                    onTrackLocation: () => _handleTrackLocation(booking),
                    onCancelRequest: () => _handleCancelRequest(booking),
                    // Shared Callbacks
                    onChat: () => _handleOpenChat(booking),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
