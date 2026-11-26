import '/core/extensions/localization.extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '/features/booking/booking.dart';
import '/shared/bloc/pagination/pagination_event.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '/features/chat/presentation/screens/chat_screen.dart';
import '/core/extensions/company.extension.dart';

/// Company operational dashboard / home screen presenting:
/// - Company header profile in [AppAppBar]
/// - Operative & booking overview cards in [WrapperCard]
/// - Latest bookings section with live search and paginated feed using [AppPagination] and [BookingCard]
/// - My bodyguards roster section with paginated feed using [AppPagination] and [BodyGuardCard]
class CompanyHomeScreen extends StatelessWidget {
  /// Shared `/home` route: one shell tab whose builder in `app_router.dart`
  /// shows the customer, company or bodyguard home based on the session role.
  static const route = '/home';

  const CompanyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.id ?? '';
    return BlocProvider(
      create: (_) =>
          sl<CompanyBodyguardsBloc>(param1: userId)
            ..add(const PaginationLoadRequested()),
      child: const _CompanyHomeView(),
    );
  }
}

class _CompanyHomeView extends StatefulWidget {
  const _CompanyHomeView();

  @override
  State<_CompanyHomeView> createState() => _CompanyHomeViewState();
}

class _CompanyHomeViewState extends State<_CompanyHomeView> {
  final _bookingSearchController = TextEditingController();

  late final PaginationController<BookingModel> _bookingsPaginationController;
  late final PaginationController<BodyGuardModel>
  _bodyguardsPaginationController;
  String? _pendingDeletedName;

  @override
  void initState() {
    super.initState();

    _bookingsPaginationController = PaginationController<BookingModel>(
      initialState: PaginationState<BookingModel>(
        items: bookingFixtures.take(3).toList(),
        total: 3,
        status: const ApiState.success(null),
      ),
    );

    final bloc = context.read<CompanyBodyguardsBloc>();
    _bodyguardsPaginationController = PaginationController<BodyGuardModel>(
      initialState: _rosterPreview(bloc.state.pagination),
      onRefresh: () async => bloc.add(const PaginationLoadRequested()),
    );
  }

  /// Number of bodyguards previewed on the home screen ("View All" for more).
  static const _rosterPreviewCount = 3;

  PaginationState<BodyGuardModel> _rosterPreview(
    PaginationState<BodyGuardModel> state,
  ) {
    return state.copyWith(
      items: state.items.take(_rosterPreviewCount).toList(),
      explicitIsLastPage: true,
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
    context.push(ChatScreen.route);
  }

  void _handleShareLocation(BookingModel booking) {}

  Future<void> _handleEditBodyguard(BodyGuardModel bodyguard) async {
    if (bodyguard.verificationStatus == UserStatus.active) {
      await context.push(BodyGuardProfileScreen.route, extra: bodyguard);
    } else {
      await context.push(
        BodyGuardCompleteProfileScreen.route,
        extra: bodyguard,
      );
    }
    if (mounted) {
      context.read<CompanyBodyguardsBloc>().add(
        const PaginationLoadRequested(),
      );
    }
  }

  Future<void> _handleViewAllBodyguards() async {
    await context.push(CompanyBodyguardsScreen.route);
    // Bodyguards may have been added, edited or removed there.
    if (mounted) {
      context.read<CompanyBodyguardsBloc>().add(
        const PaginationLoadRequested(),
      );
    }
  }

  Future<void> _handleDeleteBodyguard(BodyGuardModel bodyguard) async {
    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: bodyguard.name,
    );
    if (result?.action != PopupAction.confirm || !mounted) return;
    _pendingDeletedName = bodyguard.name;
    context.read<CompanyBodyguardsBloc>().add(
      CompanyBodyguardDeleted(bodyguard),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CompanyBodyguardsBloc, CompanyBodyguardsState>(
          listenWhen: (previous, current) =>
              previous.pagination != current.pagination,
          listener: (context, state) => _bodyguardsPaginationController
              .updateState(_rosterPreview(state.pagination)),
        ),
        BlocListener<CompanyBodyguardsBloc, CompanyBodyguardsState>(
          listenWhen: (previous, current) =>
              previous.actionStatus != current.actionStatus,
          listener: (context, state) {
            if (state.actionStatus.isSuccess) {
              final name = _pendingDeletedName;
              _pendingDeletedName = null;
              if (name != null) {
                AppSnackbar.success('$name removed.');
              }
              // Pull the next bodyguard into the preview.
              context.read<CompanyBodyguardsBloc>().add(
                const PaginationLoadRequested(),
              );
            } else if (state.actionStatus.isFailure) {
              _pendingDeletedName = null;
              AppSnackbar.error(
                context.apiErrorText(
                  state.actionStatus.errorOrNull,
                  fallback: state.actionStatus.errorMessageOrNull,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppAppBar.transparent(
          automaticallyImplyLeading: false,
          alignTitle: .left,
          titleWidget: _buildAppBarTitle(context),
          showNotificationIcon: true,
          showBackIcon: false,
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
                        onPressed: _handleViewAllBodyguards,
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
                  padding:
                      context.horizontalEdgeInsets + AppSpacing.xxl.bPadding,
                  separatorBuilder: (context, index) => AppSpacing.md.h,
                  initialLoaderBuilder: (context) =>
                      const BodyGuardListSkeleton(
                        itemCount: _rosterPreviewCount,
                      ),
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
                      onTap: () {
                        context.push(GuardDetailScreen.route, extra: guard);
                      },
                      onEdit: () => _handleEditBodyguard(guard),
                      onDelete: () => _handleDeleteBodyguard(guard),
                    );
                  },
                ),
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

  Widget _buildAppBarTitle(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      bloc: sl<AuthBloc>(),
      builder: (context, state) {
        final user = state.user;
        final company = user?.company;
        final companyName =
            company?.displayName ?? user?.name ?? 'Security Company';
        final logoUrl = user?.profileImageUrl ?? '';
        final initials = companyName.isNotEmpty
            ? companyName.getInitials()
            : 'CO';
        final rating = (company?.rating ?? 0.0).toStringAsFixed(1);
        final companyType = company?.companyType != null
            ? company!.companyType!.label(context.l10n)
            : 'Agency';

        return GestureDetector(
          onTap: () => context.go(ProfileScreen.route),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  QuickContainer(
                    shape: QuickContainerShape.circle,
                    w: 48,
                    h: 48,
                    color: context.colors.surfaceContainerHigh,
                    border: Border.all(
                      color: context.colors.primary,
                      width: 1.5,
                    ),
                    alignment: Alignment.center,
                    clipBehavior: Clip.antiAlias,
                    child: logoUrl.isNotEmpty
                        ? AppImage.auto(
                            source: logoUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : Text(
                            initials,
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
                            companyName,
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
                        Text(rating, style: context.textTheme.labelSmall),
                        Text(
                          '  •  ',
                          style: context.textTheme.labelLarge?.colour(
                            context.colors.onSurfaceVariant,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            companyType,
                            style: context.textTheme.labelSmall
                                ?.regular()
                                .colour(context.colors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpperOverviewCards(BuildContext context) {
    return Padding(
      padding: context.horizontalEdgeInsets,
      child: Row(
        children: [
          Expanded(
            child: WrapperCard(
              onTap: _handleViewAllBodyguards,
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
              onTap: () => context.go(BookingsScreen.route),
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
