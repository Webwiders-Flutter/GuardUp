import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/app/routes/app_routes.dart';
import 'package:guardup/features/company/company.dart';

import '../guard_detail.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/body_guard/data/model/body_guard.model.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/sections/app_appbar.dart';

/// Customer View: Comprehensive operative profile screen with bio, booking duration
/// calculator, credentials, client reviews, and sticky booking action bar.
class GuardDetailScreen extends StatefulWidget {
  final BodyGuardModel? bodyguard;

  const GuardDetailScreen({super.key, this.bodyguard});

  @override
  State<GuardDetailScreen> createState() => _GuardDetailScreenState();
}

class _GuardDetailScreenState extends State<GuardDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _tabs = ['Overview', 'Document', 'Booking'];

  final ValueNotifier<DateTime> _startDateNotifier = ValueNotifier(DateTime(2025, 4, 26));
  final ValueNotifier<TimeOfDay> _startTimeNotifier = ValueNotifier(const TimeOfDay(hour: 10, minute: 0));
  final ValueNotifier<DateTime> _endDateNotifier = ValueNotifier(DateTime(2025, 4, 26));
  final ValueNotifier<TimeOfDay> _endTimeNotifier = ValueNotifier(const TimeOfDay(hour: 14, minute: 0));

  int get _durationHours {
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

  double get _hourlyRate => widget.bodyguard?.hourlyRate ?? 60.0;
  double get _totalAmount => _hourlyRate * _durationHours;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _startDateNotifier.dispose();
    _startTimeNotifier.dispose();
    _endDateNotifier.dispose();
    _endTimeNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDateNotifier.value : _endDateNotifier.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.colors.primary,
              onPrimary: context.colors.onPrimary,
              surface: context.colors.surfaceContainer,
              onSurface: context.colors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStart) {
        _startDateNotifier.value = picked;
        if (_endDateNotifier.value.isBefore(picked)) {
          _endDateNotifier.value = picked;
        }
      } else {
        _endDateNotifier.value = picked;
      }
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initialTime = isStart ? _startTimeNotifier.value : _endTimeNotifier.value;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.colors.primary,
              onPrimary: context.colors.onPrimary,
              surface: context.colors.surfaceContainer,
              onSurface: context.colors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStart) {
        _startTimeNotifier.value = picked;
      } else {
        _endTimeNotifier.value = picked;
      }
    }
  }

  void _onBookNowPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerBookingDetailsScreen(
          bodyguard: widget.bodyguard,
          startDate: _startDateNotifier.value,
          startTime: _startTimeNotifier.value,
          endDate: _endDateNotifier.value,
          endTime: _endTimeNotifier.value,
          durationHours: _durationHours,
          hourlyRate: _hourlyRate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guardName = widget.bodyguard?.user.name ?? 'Vikram Singh';
    final photoPath =
        widget.bodyguard?.user.profileImageUrl ??
        Assets.images.onboardingImage01.path;

    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              guardName,
              style: context.textTheme.titleSmall?.bold().colour(
                context.colors.onSurface,
              ),
            ),
            AppSpacing.xs.w,
            Assets.svg.verifiedShieldBadge.svg(width: 16, height: 16),
          ],
        ),
        showBackIcon: true,
        alignTitle: AlignTitle.right,
        onBackTap: () => context.pop(),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: Listenable.merge([
          _startDateNotifier,
          _startTimeNotifier,
          _endDateNotifier,
          _endTimeNotifier,
        ]),
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 25),
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border(
                top: BorderSide(
                  color: context.colors.outlineVariant.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GRAND TOTAL',
                      style: context.textTheme.labelSmall
                          ?.copyWith(
                            fontSize: 9.5,
                            letterSpacing: 0.8,
                          )
                          .colour(context.colors.onSurfaceVariant),
                    ),
                    AppSpacing.xxs.h,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$${_totalAmount.toStringAsFixed(2)}',
                          style: context.textTheme.titleLarge?.bold().colour(
                            context.colors.primary,
                          ),
                        ),
                        AppSpacing.xxs.w,
                        Text(
                          ' / $_durationHours hrs',
                          style: context.textTheme.bodySmall?.colour(
                            context.colors.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Book Now CTA Button
                GestureDetector(
                  onTap: _onBookNowPressed,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: context.colors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Book Now',
                          style: context.textTheme.labelMedium?.colour(
                            context.colors.onPrimary,
                          ),
                        ),
                        AppSpacing.xs.w,
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: context.colors.onPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                padding: context.horizontalEdgeInsets,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.sm.h,

                    // 1. Operative Hero Profile Card
                    GuardProfileHeaderWidget(
                      name: guardName,
                      specialization: 'Licensed armed, Corporate visits',
                      hourlyRate: _hourlyRate,
                      imagePath: photoPath,
                      isVerified: true,
                    ),
                    AppSpacing.xlg.h,
                    CompanyCard(
                      company: CompanyModel.fakeData.first,
                      onTap: () {
                        context.push(
                          AppRoutes.companyDetails,
                          extra: CompanyModel.fakeData.first,
                        );
                      },
                      onBookNow: () {
                        context.push(
                          AppRoutes.customerBooking,
                          extra: CompanyModel.fakeData.first,
                        );
                      },
                    ),

                    AppSpacing.xlg.h,

                    // 3. Three Metrics Summary Row
                    const GuardMetricsRowWidget(
                      experience: '5+ yrs',
                      qualifications: 'Certified Spec',
                      status: 'Available',
                      isAvailable: true,
                    ),
                    AppSpacing.md.h,
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4. Underline Tab Navigation
            AppTabBar.underline(
              controller: _tabController,
              tabNames: _tabs,
              indicatorColor: context.colors.primary,
              dividerColor: context.colors.outlineVariant,
              height: 40,
            ),
            AppSpacing.lg.h,

            // 5. Dynamic Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      _startDateNotifier,
                      _startTimeNotifier,
                      _endDateNotifier,
                      _endTimeNotifier,
                    ]),
                    builder: (context, _) {
                      return GuardAboutBookingCard(
                        bio:
                            'Former military officer with 6+ years of security experience. Skilled in close protection, executive security, and risk assessment. Specialized in high-profile VIP transport and perimeter security.',
                        hourlyRate: _hourlyRate,
                        startDate: _startDateNotifier.value,
                        startTime: _startTimeNotifier.value,
                        endDate: _endDateNotifier.value,
                        endTime: _endTimeNotifier.value,
                        onPickStartDate: () => _pickDate(isStart: true),
                        onPickStartTime: () => _pickTime(isStart: true),
                        onPickEndDate: () => _pickDate(isStart: false),
                        onPickEndTime: () => _pickTime(isStart: false),
                      );
                    },
                  ),
                  Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
