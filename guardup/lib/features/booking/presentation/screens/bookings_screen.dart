import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/extensions/localization.extension.dart';
import 'package:guardup/core/extensions/number.extension.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '../../data/enum/booking_status.enum.dart';
import '../../data/model/booking.model.dart';
import '../widgets/booking_card.widget.dart';

/// Screen presenting the operative's security assignments and customer booking requests.
///
/// Implements live keyword search via [AppTextField.search], status filtering via
/// [AppTabBar.pill], and dynamic booking cards reflecting the operative lifecycle.
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;
  late final ValueNotifier<String> _searchQueryNotifier;
  late final ValueNotifier<int> _activeTabIndexNotifier;
  late final ValueNotifier<List<BookingModel>> _bookingsNotifier;

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
    _searchController = TextEditingController();
    _searchQueryNotifier = ValueNotifier<String>('');
    _activeTabIndexNotifier = ValueNotifier<int>(0);
    _bookingsNotifier = ValueNotifier<List<BookingModel>>(
      List.from(BookingModel.fakeBookings),
    );

    _tabController.addListener(_handleTabControllerChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabControllerChange);
    _tabController.dispose();
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    _activeTabIndexNotifier.dispose();
    _bookingsNotifier.dispose();
    super.dispose();
  }

  void _handleTabControllerChange() {
    if (_tabController.indexIsChanging) {
      _activeTabIndexNotifier.value = _tabController.index;
    } else if (_activeTabIndexNotifier.value != _tabController.index) {
      _activeTabIndexNotifier.value = _tabController.index;
    }
  }

  void _handleAcceptBooking(BookingModel booking) {
    final updatedList = _bookingsNotifier.value.map((b) {
      if (b.id == booking.id) {
        return b.copyWith(status: BookingStatus.onGoing);
      }
      return b;
    }).toList();

    _bookingsNotifier.value = updatedList;
    AppSnackbar.success('Booking accepted and marked as Running', context: context);
  }

  void _handleRejectBooking(BookingModel booking) {
    final updatedList = _bookingsNotifier.value.map((b) {
      if (b.id == booking.id) {
        return b.copyWith(status: BookingStatus.cancelled);
      }
      return b;
    }).toList();

    _bookingsNotifier.value = updatedList;
    AppSnackbar.info('Booking request declined', context: context);
  }

  void _handleOpenChat(BookingModel booking) {
    context.push(AppRoutes.chat);
  }

  void _handleShareLocation(BookingModel booking) {
    AppSnackbar.info(
      'Live GPS telemetry shared with ${booking.customer.name}',
      context: context,
    );
  }

  List<BookingModel> _filterBookings({
    required List<BookingModel> allBookings,
    required int tabIndex,
    required String query,
  }) {
    // 1. Filter by Tab Index:
    // Tab 0: All
    // Tab 1: Running (onGoing)
    // Tab 2: Completed
    // Tab 3: Pending
    List<BookingModel> tabFiltered;
    switch (tabIndex) {
      case 1:
        tabFiltered = allBookings
            .where((b) => b.status == BookingStatus.onGoing)
            .toList();
        break;
      case 2:
        tabFiltered = allBookings
            .where((b) => b.status == BookingStatus.completed)
            .toList();
        break;
      case 3:
        tabFiltered = allBookings
            .where((b) => b.status == BookingStatus.pending)
            .toList();
        break;
      case 0:
      default:
        tabFiltered = allBookings;
        break;
    }

    // 2. Filter by search query
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return tabFiltered;
    }

    return tabFiltered.where((b) {
      final matchesCustomerName =
          b.customer.name.toLowerCase().contains(trimmedQuery);
      final matchesBookingNumber =
          b.bookingNumber.toLowerCase().contains(trimmedQuery);
      final matchesAddress =
          (b.pickupAddress ?? '').toLowerCase().contains(trimmedQuery);
      final matchesServiceTitle =
          b.serviceType?.label(context.l10n).toLowerCase().contains(trimmedQuery) ?? true;
      final matchesInstructions =
          (b.specialInstructions ?? '').toLowerCase().contains(trimmedQuery);

      return matchesCustomerName ||
          matchesBookingNumber ||
          matchesAddress ||
          matchesServiceTitle ||
          matchesInstructions;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.md.h,

            // -----------------------------------------------------------------
            // 1. Header: "Booking" Title
            // -----------------------------------------------------------------
            Padding(
              padding: context.horizontalEdgeInsets,
              child: Text(
                'Booking',
                style: context.textTheme.headlineSmall?.bold(),
              ),
            ),
            AppSpacing.md.h,

            // -----------------------------------------------------------------
            // 2. Search Field using AppTextField.search (matching conversation screen)
            // -----------------------------------------------------------------
            Padding(
              padding: context.horizontalEdgeInsets,
              child: AppTextField.search(
                controller: _searchController,
                size: AppInputSize.small,
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
                onChanged: (val) => _searchQueryNotifier.value = val,
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
                height: 40.0,
                spacing: AppSpacing.sm,
                radius: AppRadius.md,
                onTap: (index) => _activeTabIndexNotifier.value = index,
              ),
            ),
            AppSpacing.md.h,

            // -----------------------------------------------------------------
            // 4. Reactive Bookings List
            // -----------------------------------------------------------------
            Expanded(
              child: ValueListenableBuilder<List<BookingModel>>(
                valueListenable: _bookingsNotifier,
                builder: (context, allBookings, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: _activeTabIndexNotifier,
                    builder: (context, activeTabIndex, _) {
                      return ValueListenableBuilder<String>(
                        valueListenable: _searchQueryNotifier,
                        builder: (context, searchQuery, _) {
                          final filteredList = _filterBookings(
                            allBookings: allBookings,
                            tabIndex: activeTabIndex,
                            query: searchQuery,
                          );

                          if (filteredList.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: AppSpacing.xxl.allPadding,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 40,
                                      color: context.colors.outline,
                                    ),
                                    AppSpacing.md.h,
                                    Text(
                                      'No bookings found',
                                      style: context.textTheme.titleSmall
                                          ?.semiBold(),
                                    ),
                                    AppSpacing.xs.h,
                                    Text(
                                      'Try adjusting your search or tab filters.',
                                      style: context.textTheme.bodySmall
                                          ?.colour(
                                            context.colors.onSurfaceVariant,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: context.horizontalEdgeInsets +
                                AppSpacing.lg.bPadding,
                            itemCount: filteredList.length,
                            separatorBuilder: (context, index) =>
                                AppSpacing.md.h,
                            itemBuilder: (context, index) {
                              final booking = filteredList[index];
                              return BookingCard(
                                booking: booking,
                                onAccept: () => _handleAcceptBooking(booking),
                                onReject: () => _handleRejectBooking(booking),
                                onChat: () => _handleOpenChat(booking),
                                onShareLocation: () =>
                                    _handleShareLocation(booking),
                              );
                            },
                          );
                        },
                      );
                    },
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

