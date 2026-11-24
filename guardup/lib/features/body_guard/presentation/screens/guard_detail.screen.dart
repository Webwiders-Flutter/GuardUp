import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:guardup/features/company/company.dart';
import 'package:guardup/features/customer/presentation/screens/booking_screen.dart';
import 'package:guardup/features/body_guard/presentation/screens/customer_booking_details.screen.dart';
import 'package:guardup/shared/widgets/buttons/app_button.dart';

import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/model/body_guard.model.dart';
import '../../data/repositories/bodyguard.repository.dart';
import '../widgets/guard_metrics_row.widget.dart';
import '../widgets/guard_profile_header.widget.dart';
import '../widgets/tabs/company_guard_bookings_tab.widget.dart';
import '../widgets/tabs/company_guard_documents_tab.widget.dart';
import '../widgets/tabs/company_guard_overview_tab.widget.dart';
import '../widgets/tabs/customer_guard_about_tab.widget.dart';
import '../widgets/tabs/customer_guard_experience_tab.widget.dart';
import '../widgets/tabs/customer_guard_reviews_tab.widget.dart';
import 'body_guard_complete_profile_screen.dart';
import 'body_guard_profile_screen.dart';

/// Consolidated, role-adaptive bodyguard detail screen.
///
/// Accepts a mandatory [id] and an optional [bodyguard] model.
/// If [bodyguard] is passed, displays it immediately while fetching full joined
/// details (company, documents, services, availabilities) in the background.
/// If only [id] is passed, fetches the full model via [BodyguardRepository.getDetails].
///
/// Adapts dynamically for Company (Overview, Document, Booking + Edit CTA)
/// and Customer (About, Experience, Reviews + Sticky Book Now CTA).
class GuardDetailScreen extends StatefulWidget {
  static const route = '/guard-detail';

  final String id;
  final BodyGuardModel? bodyguard;
  final bool? isCompanyView;

  const GuardDetailScreen({
    super.key,
    required this.id,
    this.bodyguard,
    this.isCompanyView,
  });

  @override
  State<GuardDetailScreen> createState() => _GuardDetailScreenState();
}

class _GuardDetailScreenState extends State<GuardDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _companyTabs = ['Overview', 'Document', 'Booking'];
  static const List<String> _customerTabs = ['About', 'Experience', 'Reviews'];

  late BodyGuardModel? _guard;
  bool _isLoading = false;
  String? _errorMessage;

  // Booking pickers for Customer view
  final ValueNotifier<DateTime> _startDateNotifier = ValueNotifier(
    DateTime.now().add(const Duration(days: 1)),
  );
  final ValueNotifier<TimeOfDay> _startTimeNotifier = ValueNotifier(
    const TimeOfDay(hour: 10, minute: 0),
  );
  final ValueNotifier<DateTime> _endDateNotifier = ValueNotifier(
    DateTime.now().add(const Duration(days: 1)),
  );
  final ValueNotifier<TimeOfDay> _endTimeNotifier = ValueNotifier(
    const TimeOfDay(hour: 14, minute: 0),
  );

  bool get _isCompany {
    if (widget.isCompanyView != null) return widget.isCompanyView!;
    if (sl.isRegistered<AuthBloc>()) {
      return sl<AuthBloc>().state.isCompany;
    }
    return false;
  }

  List<String> get _activeTabs => _isCompany ? _companyTabs : _customerTabs;

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

  double get _hourlyRate => _guard?.hourlyRate ?? 60.0;
  double get _totalAmount => _hourlyRate * _durationHours;

  @override
  void initState() {
    super.initState();
    _guard = widget.bodyguard;
    _tabController = TabController(length: _activeTabs.length, vsync: this);
    _loadDetails();
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

  Future<void> _loadDetails() async {
    final targetId = widget.id.isNotEmpty ? widget.id : _guard?.id ?? '';
    if (targetId.isEmpty) {
      if (_guard == null) {
        setState(() => _errorMessage = 'Bodyguard not found.');
      }
      return;
    }

    if (_guard == null) {
      setState(() => _isLoading = true);
    }

    try {
      final repository = sl.isRegistered<BodyguardRepository>()
          ? sl<BodyguardRepository>()
          : BodyguardRepository();

      final detailed = await repository.getDetails(targetId);
      if (mounted) {
        setState(() {
          _guard = detailed;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_guard == null) {
            _errorMessage =
                'Could not load bodyguard details. Please try again.';
          }
        });
      }
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? _startDateNotifier.value
        : _endDateNotifier.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
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
    final initialTime = isStart
        ? _startTimeNotifier.value
        : _endTimeNotifier.value;
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
          bodyguard: _guard,
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

  Future<void> _onEditPressed() async {
    final guard = _guard;
    if (guard == null) return;
    if (guard.verificationStatus == UserStatus.active) {
      await context.push(BodyGuardProfileScreen.route, extra: guard);
    } else {
      await context.push(BodyGuardCompleteProfileScreen.route, extra: guard);
    }
    _loadDetails();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _guard == null) {
      return Scaffold(
        backgroundColor: context.colors.transparent,
        appBar: AppAppBar.transparent(
          title: 'Guard Details',
          showBackIcon: true,
          onBackTap: () => context.pop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _guard == null) {
      return Scaffold(
        backgroundColor: context.colors.transparent,
        appBar: AppAppBar.transparent(
          title: 'Guard Details',
          showBackIcon: true,
          onBackTap: () => context.pop(),
        ),
        body: Center(
          child: Padding(
            padding: context.horizontalEdgeInsets,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: context.colors.error,
                ),
                AppSpacing.md.h,
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium,
                ),
                AppSpacing.lg.h,
                AppButton(text: 'Retry', onPressed: _loadDetails),
              ],
            ),
          ),
        ),
      );
    }

    final guardName = _guard?.user.name.isNotEmpty == true
        ? _guard!.user.name
        : 'Vikram Singh';
    final photoPath =
        _guard?.user.profileImageUrl ?? Assets.images.onboardingImage01.path;
    final isVerified = _guard?.isVerified ?? true;
    final company = _guard?.company ?? CompanyModel.fakeData.first;

    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                guardName,
                style: context.textTheme.titleSmall?.bold().colour(
                  context.colors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isVerified) ...[
              AppSpacing.xs.w,
              Assets.svg.verifiedShieldBadge.svg(width: 16, height: 16),
            ],
          ],
        ),
        fontSize: 14,
        showBackIcon: true,
        alignTitle: AlignTitle.right,
        onBackTap: () => context.pop(),
      ),

      // Bottom Bar adapts by View Role
      bottomNavigationBar: _isCompany
          ? AppButton(
              text: 'Edit Guard',
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              onPressed: _onEditPressed,
            )
          : _buildCustomerBottomBar(),

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
                      specialization:
                          _guard?.clearanceLevel ??
                          'Licensed armed, Corporate visits',
                      hourlyRate: _hourlyRate,
                      imagePath: photoPath,
                      isVerified: isVerified,
                    ),

                    AppSpacing.md.h,

                    // 2. Affiliated Security Company Card
                    CompanyCard(
                      company: company,
                      onTap: () {
                        context.push(
                          CompanyDetailsScreen.route,
                          extra: company,
                        );
                      },
                      onBookNow: _isCompany
                          ? null
                          : () {
                              context.push(BookingScreen.route, extra: company);
                            },
                    ),

                    AppSpacing.md.h,

                    // 3. Three Metrics Summary Row
                    GuardMetricsRowWidget(
                      experience: '${_guard?.experienceYears ?? 5}+ yrs',
                      qualifications:
                          _guard?.clearanceLevel ?? 'Certified Spec',
                      status: _guard?.verificationStatus ?? UserStatus.active,
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
            // 4. Dynamic Underline Tab Bar
            AppTabBar.underline(
              controller: _tabController,
              tabNames: _activeTabs,
              isScrollable: false,
              indicatorColor: context.colors.primary,
              dividerColor: context.colors.outlineVariant,
              height: 42,
            ),
            AppSpacing.md.h,

            // 5. Dynamic Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _isCompany
                    ? _buildCompanyTabs()
                    : _buildCustomerTabs(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCompanyTabs() {
    final currentGuard =
        _guard ?? BodyGuardModel.fakeData.first.copyWith(id: widget.id);

    return [
      CompanyGuardOverviewTabWidget(bodyguard: currentGuard),
      CompanyGuardDocumentsTabWidget(bodyguard: currentGuard),
      CompanyGuardBookingsTabWidget(bodyguard: currentGuard),
    ];
  }

  List<Widget> _buildCustomerTabs() {
    final currentGuard =
        _guard ?? BodyGuardModel.fakeData.first.copyWith(id: widget.id);

    return [
      ListenableBuilder(
        listenable: Listenable.merge([
          _startDateNotifier,
          _startTimeNotifier,
          _endDateNotifier,
          _endTimeNotifier,
        ]),
        builder: (context, _) {
          return CustomerGuardAboutTabWidget(
            bio: currentGuard.bio,
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
      CustomerGuardExperienceTabWidget(
        yearsExperience: '${currentGuard.experienceYears}+ Years',
        specializationTitle:
            currentGuard.clearanceLevel ?? 'Licensed armed, Corporate visits',
        services: currentGuard.serviceTypes.isNotEmpty
            ? currentGuard.serviceTypes
                  .map((s) => s.apiValue.replaceAll('_', ' '))
                  .toList()
            : const [
                'VIP Close Protection',
                'Armed Escort',
                'Tactical Driver',
                'Asset Protection',
              ],
      ),
      CustomerGuardReviewsTabWidget(
        averageRating: currentGuard.rating,
        totalReviews: currentGuard.reviewCount > 0
            ? currentGuard.reviewCount
            : 48,
      ),
    ];
  }

  Widget _buildCustomerBottomBar() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _startDateNotifier,
        _startTimeNotifier,
        _endDateNotifier,
        _endTimeNotifier,
      ]),
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
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
                        ?.copyWith(fontSize: 9.5, letterSpacing: 0.8)
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
                          context.colors.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
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
                    vertical: 11,
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
    );
  }
}
