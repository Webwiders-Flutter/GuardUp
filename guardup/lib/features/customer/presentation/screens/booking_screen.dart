import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '/features/company/company.dart';
import '/shared/bloc/pagination/pagination_event.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '/features/customer/presentation/screens/customer_home_screen.dart';
import '/features/payments/presentation/screens/payment_success_screen.dart';

/// Customer booking customization and confirmation screen.
///
/// Features:
/// - Transparent [AppAppBar] with right-aligned "Company Profile" title
/// - Executive [CompanyCard] summary
/// - 2x2 Date & Time selectors using [WrapperCard]
/// - Live search bar with luxury tune/filter squircle prefix icon
/// - Bodyguard operative roster cards with selection checkboxes using [BodyGuardCard]
/// - Payment summary card with tier badge, operative rates, discounts, and total
/// - Sticky bottom action button for reservation progression
class BookingScreen extends StatelessWidget {
  static const route = '/customer-booking';

  final CompanyModel? company;
  final BodyGuardModel? initialBodyguard;

  const BookingScreen({super.key, this.company, this.initialBodyguard});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BodyguardsBloc>(
        param1: BodyguardFilters(
          companyId: company?.id,
          statuses: const [UserStatus.active],
        ),
      )..add(const PaginationLoadRequested()),
      child: _BookingView(
        company: company,
        initialBodyguard: initialBodyguard,
      ),
    );
  }
}

class _BookingView extends StatefulWidget {
  final CompanyModel? company;
  final BodyGuardModel? initialBodyguard;

  const _BookingView({this.company, this.initialBodyguard});

  @override
  State<_BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<_BookingView> {
  final _searchController = TextEditingController();

  final ValueNotifier<DateTime> _startDateNotifier = ValueNotifier(
    DateTime(2025, 4, 26),
  );
  final ValueNotifier<TimeOfDay> _startTimeNotifier = ValueNotifier(
    const TimeOfDay(hour: 10, minute: 0),
  );
  final ValueNotifier<DateTime> _endDateNotifier = ValueNotifier(
    DateTime(2025, 4, 26),
  );
  final ValueNotifier<TimeOfDay> _endTimeNotifier = ValueNotifier(
    const TimeOfDay(hour: 14, minute: 0),
  );
  late final ValueNotifier<Set<String>> _selectedGuardIdsNotifier;
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');

  Timer? _searchDebounce;
  late final PaginationController<BodyGuardModel> _paginationController;

  @override
  void initState() {
    super.initState();
    _selectedGuardIdsNotifier = ValueNotifier<Set<String>>({
      if (widget.initialBodyguard != null)
        widget.initialBodyguard!.id,
    });

    final bloc = context.read<BodyguardsBloc>();
    _paginationController = PaginationController<BodyGuardModel>(
      initialState: bloc.state.pagination,
      onRefresh: () async => bloc.add(const PaginationLoadRequested()),
      onLoadMore: () async => bloc.add(const PaginationNextPageRequested()),
    );

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final term = _searchController.text.trim();
    _searchQueryNotifier.value = term.toLowerCase();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppDurations.slow, () {
      if (!mounted) return;
      context.read<BodyguardsBloc>().add(PaginationSearchChanged(term));
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _paginationController.dispose();
    _searchController.dispose();
    _startDateNotifier.dispose();
    _startTimeNotifier.dispose();
    _endDateNotifier.dispose();
    _endTimeNotifier.dispose();
    _selectedGuardIdsNotifier.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  // ── Date & Time Pickers ────────────────────────────────────────────────────

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDateNotifier.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      _startDateNotifier.value = picked;
      if (_endDateNotifier.value.isBefore(picked)) {
        _endDateNotifier.value = picked;
      }
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTimeNotifier.value,
    );
    if (picked != null) {
      _startTimeNotifier.value = picked;
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDateNotifier.value,
      firstDate: _startDateNotifier.value,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      _endDateNotifier.value = picked;
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTimeNotifier.value,
    );
    if (picked != null) {
      _endTimeNotifier.value = picked;
    }
  }

  // ── Calculation Helpers ────────────────────────────────────────────────────

  int get _calculatedHours {
    final start = DateTime(
      _startDateNotifier.value.year,
      _startDateNotifier.value.month,
      _startDateNotifier.value.day,
      _startTimeNotifier.value.hour,
      _startTimeNotifier.value.minute,
    );
    final end = DateTime(
      _endDateNotifier.value.year,
      _endDateNotifier.value.month,
      _endDateNotifier.value.day,
      _endTimeNotifier.value.hour,
      _endTimeNotifier.value.minute,
    );
    final diff = end.difference(start).inHours;
    return diff > 0 ? diff : 4;
  }

  void _handleNext() {
    context.push(
      PaymentSuccessScreen.route,
      extra: {
        'onTap': () {
          context.go(CustomerHomeScreen.route);
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BodyguardsBloc, BodyguardsState>(
      listenWhen: (previous, current) =>
          previous.pagination != current.pagination,
      listener: (context, state) =>
          _paginationController.updateState(state.pagination),
      child: Scaffold(
      appBar: const AppAppBar.transparent(
        title: 'Company Profile',
        showBackIcon: true,
        alignTitle: AlignTitle.right,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding:
              context.horizontalEdgeInsets +
              const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
          child: AppButton(
            text: 'Next',

            type: ButtonType.primary,
            trailing: Icon(
              Icons.arrow_forward_rounded,
              size: AppSizes.iconSm,
              color: context.colors.onPrimary,
            ),
            onPressed: _handleNext,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: context.horizontalEdgeInsets + AppSpacing.md.yPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------------------
              // 1. Company Profile Header Card
              // ---------------------------------------------------------------
              if (widget.company != null) ...[
                CompanyCard(company: widget.company!, onBookNow: () {}),
                AppSpacing.xl.h,
              ],

              // ---------------------------------------------------------------
              // 2. Date & Time Selection Section
              // ---------------------------------------------------------------
              Text(
                'DATE & TIME',
                style: context.textTheme.labelMedium
                    ?.copyWith(letterSpacing: 1.2)
                    .colour(context.colors.onSurfaceVariant),
              ),
              AppSpacing.sm.h,
              ListenableBuilder(
                listenable: Listenable.merge([
                  _startDateNotifier,
                  _startTimeNotifier,
                  _endDateNotifier,
                  _endTimeNotifier,
                ]),
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDateTimeRow(
                        firstLabel: 'START DATE',
                        firstValue: DateFormat('MMM dd, yyyy')
                            .format(_startDateNotifier.value),
                        firstIcon: Icons.calendar_today_outlined,
                        onFirstTap: _pickStartDate,
                        secondLabel: 'START TIME',
                        secondValue: _startTimeNotifier.value.format(context),
                        secondIcon: Icons.access_time_rounded,
                        onSecondTap: _pickStartTime,
                      ),
                      AppSpacing.sm.h,
                      _buildDateTimeRow(
                        firstLabel: 'END DATE',
                        firstValue: DateFormat('MMM dd, yyyy')
                            .format(_endDateNotifier.value),
                        firstIcon: Icons.calendar_today_outlined,
                        onFirstTap: _pickEndDate,
                        secondLabel: 'END TIME',
                        secondValue: _endTimeNotifier.value.format(context),
                        secondIcon: Icons.access_time_rounded,
                        onSecondTap: _pickEndTime,
                      ),
                    ],
                  );
                },
              ),
              AppSpacing.lg.h,

              // ---------------------------------------------------------------
              // 3. Search Bar with Custom Filter Icon
              // ---------------------------------------------------------------
              AppTextField.search(
                controller: _searchController,
                size: AppInputSize.small,
                decoration: InputDecoration(
                  hintText: 'Search bodyguards near you...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.colors.onSurfaceVariant,
                    size: AppSizes.iconSm + 2,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(
                      right: AppSpacing.xs,
                      top: 2,
                      bottom: 2,
                    ),
                    child: QuickContainer(
                      w: 36,
                      h: 36,
                      radius: AppRadius.md,
                      color: context.colors.primary.withValues(alpha: 0.12),
                      border: Border.all(
                        color: context.colors.primary.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.tune_rounded,
                        color: context.colors.primary,
                        size: AppSizes.iconSm,
                      ),
                    ),
                  ),
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
              AppSpacing.lg.h,

              // ---------------------------------------------------------------
              // 4. Selectable Bodyguards Operative List & 5. Payment Summary
              // ---------------------------------------------------------------
              AppPagination<BodyGuardModel>.list(
                controller: _paginationController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                enablePullToRefresh: false,
                separatorBuilder: (context, index) => AppSpacing.md.h,
                itemBuilder: (context, guard, index) {
                  return ListenableBuilder(
                    listenable: _selectedGuardIdsNotifier,
                    builder: (context, _) {
                      final isSelected =
                          _selectedGuardIdsNotifier.value.contains(guard.id);
                      return BodyGuardCard(
                        bodyguard: guard,
                        isSelected: isSelected,
                        onSelectedChanged: (selected) {
                          final updated = Set<String>.from(
                            _selectedGuardIdsNotifier.value,
                          );
                          if (selected == true) {
                            updated.add(guard.id);
                          } else {
                            updated.remove(guard.id);
                          }
                          _selectedGuardIdsNotifier.value = updated;
                        },
                        onTap: () {
                          final updated = Set<String>.from(
                            _selectedGuardIdsNotifier.value,
                          );
                          if (updated.contains(guard.id)) {
                            updated.remove(guard.id);
                          } else {
                            updated.add(guard.id);
                          }
                          _selectedGuardIdsNotifier.value = updated;
                        },
                      );
                    },
                  );
                },
                emptyBuilder: (context) => Padding(
                  padding: AppSpacing.lg.yPadding,
                  child: Center(
                    child: Text(
                      'No active bodyguards found.',
                      style: context.textTheme.bodyMedium?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.md.h,

              ListenableBuilder(
                listenable: Listenable.merge([
                  _selectedGuardIdsNotifier,
                  _paginationController,
                  _startDateNotifier,
                  _startTimeNotifier,
                  _endDateNotifier,
                  _endTimeNotifier,
                ]),
                builder: (context, _) {
                  final selectedIds = _selectedGuardIdsNotifier.value;
                  final loadedGuards = _paginationController.value.items;
                  final allKnownGuards = [
                    if (widget.initialBodyguard != null)
                      widget.initialBodyguard!,
                    ...loadedGuards,
                  ];
                  final selectedGuardsList = allKnownGuards
                      .where((g) => selectedIds.contains(g.id))
                      .toList();
                  final double primaryRate = selectedGuardsList.isNotEmpty
                      ? selectedGuardsList.first.hourlyRate
                      : (widget.initialBodyguard?.hourlyRate ?? 60.0);
                  final int hours = _calculatedHours;
                  final double operativeCost = primaryRate * hours;
                  const double discountAmount = 15.0;
                  final double totalAmount =
                      (operativeCost - discountAmount) > 0
                          ? (operativeCost - discountAmount)
                          : operativeCost;

                  return _buildPaymentSummaryCard(
                    context: context,
                    primaryRate: primaryRate,
                    hours: hours,
                    operativeCost: operativeCost,
                    discountAmount: discountAmount,
                    totalAmount: totalAmount,
                  );
                },
              ),
              AppSpacing.xl.h,
            ],
          ),
        ),
      ),
    ),
    );
  }

  // ===========================================================================
  // SUBCOMPONENTS
  // ===========================================================================

  Widget _buildDateTimeRow({
    required String firstLabel,
    required String firstValue,
    required IconData firstIcon,
    required VoidCallback onFirstTap,
    required String secondLabel,
    required String secondValue,
    required IconData secondIcon,
    required VoidCallback onSecondTap,
  }) {
    return Row(
      children: [
        _buildDateTimeCard(
          label: firstLabel,
          value: firstValue,
          icon: firstIcon,
          onTap: onFirstTap,
        ),
        AppSpacing.md.w,
        _buildDateTimeCard(
          label: secondLabel,
          value: secondValue,
          icon: secondIcon,
          onTap: onSecondTap,
        ),
      ],
    );
  }

  Widget _buildDateTimeCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: WrapperCard(
        onTap: onTap,
        borderColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelSmall?.regular().colour(
                    context.colors.onSurfaceVariant,
                  ),
                ),
                AppSpacing.sm.h,
                Text(
                  value,
                  style: context.textTheme.bodySmall?.semiBold().increaseSize(
                    1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Icon(icon, size: AppSizes.iconSm, color: context.colors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard({
    required BuildContext context,
    required double primaryRate,
    required int hours,
    required double operativeCost,
    required double discountAmount,
    required double totalAmount,
  }) {
    return WrapperCard(
      padding: AppSpacing.lg.allPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: PAYMENT SUMMARY + EXECUTIVE TIER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PAYMENT SUMMARY',
                style: context.textTheme.labelMedium
                    ?.copyWith(letterSpacing: 1.2)
                    .colour(context.colors.onSurfaceVariant),
              ),

              QuickContainer(
                px: AppSpacing.sm,
                py: 3,
                radius: AppRadius.xs,
                color: context.colors.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.4),
                  width: 1.0,
                ),
                child: Text(
                  'EXECUTIVE TIER',
                  style: context.textTheme.labelSmall?.colour(
                    context.colors.primary,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.smd.h,
          Divider(color: context.colors.outline, thickness: 0.4),
          AppSpacing.smd.h,

          // Line 1: Operative Rate ($60.00 x 4 hrs) -> $240.00
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Operative Rate (${primaryRate.toUsd} x $hours hrs)',
                style: context.textTheme.bodyMedium?.colour(
                  context.colors.onSurfaceVariant,
                ),
              ),
              Text(
                operativeCost.toUsd,
                style: context.textTheme.bodyMedium?.bold(),
              ),
            ],
          ),
          AppSpacing.md.h,

          // Line 2: 20% Discount [Gold Sentinel] -> -$15.00
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuickContainer(
                    px: AppSpacing.xs + 2,
                    py: 2,
                    radius: AppRadius.xs,
                    color: context.colors.success.withValues(alpha: 0.15),
                    child: Text(
                      '20% Discount',
                      style: context.textTheme.labelSmall?.colour(
                        context.colors.success,
                      ),
                    ),
                  ),
                  AppSpacing.xs.w,
                  QuickContainer(
                    px: AppSpacing.xs + 2,
                    py: 2,
                    radius: AppRadius.xs,
                    color: context.colors.success.withValues(alpha: 0.08),
                    border: Border.all(
                      color: context.colors.success.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                    child: Text(
                      'Gold Sentinel',
                      style: context.textTheme.labelSmall?.colour(
                        context.colors.success,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '-${discountAmount.toUsd}',
                style: context.textTheme.bodyMedium?.bold().colour(
                  context.colors.success,
                ),
              ),
            ],
          ),
          AppSpacing.smd.h,
          Divider(color: context.colors.outline, thickness: 0.4),
          AppSpacing.smd.h,

          // Line 3: TOTAL AMOUNT -> $225.00
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('TOTAL AMOUNT', style: context.textTheme.labelLarge),
                  AppSpacing.xxs.h,
                  Text(
                    'Includes all taxes & insurance',
                    style: context.textTheme.labelSmall?.regular().colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                totalAmount.toUsd,
                style: context.textTheme.headlineSmall?.bold().colour(
                  context.colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
