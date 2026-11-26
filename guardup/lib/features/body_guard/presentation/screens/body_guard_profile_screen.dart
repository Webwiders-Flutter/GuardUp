import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/features/auth/auth.dart';

import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/spacing.extension.dart';
import '/gen/assets.gen.dart';
import '/features/services/services.dart';
import '/shared/models/record_owner.model.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../bloc/bodyguard_details/bodyguard_details_bloc.dart';
import '../../bloc/guard_profile/guard_profile_bloc.dart';
import '../../data/model/body_guard.model.dart';
import '../widgets/body_guard_header_card.dart';
import '../widgets/sheets/sheets.dart';
import '../widgets/tabs/bodyguard_about.widget.dart';
import '../widgets/tabs/bodyguard_availability.widget.dart';
import '../widgets/tabs/bodyguard_documents.widget.dart';
import '../widgets/tabs/bodyguard_reviews.widget.dart';

/// Bodyguard operational profile screen featuring the profile header card,
/// underline tabs navigation, and modular tab widgets.
class BodyGuardProfileScreen extends StatelessWidget {
  static const route = '/bodyguard-information';

  final BodyGuardModel? bodyguard;

  const BodyGuardProfileScreen({super.key, this.bodyguard});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final targetId = bodyguard?.id ?? authState.user?.bodyguard?.id ?? '';
    final RecordOwner owner = bodyguard != null
        ? ManagedBodyguardOwner(bodyguard!.id)
        : AccountOwner(authState.user?.id ?? '');

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<BodyguardDetailsBloc>(param1: targetId, param2: bodyguard)
                ..add(const BodyguardDetailsStarted()),
        ),
        BlocProvider(
          create: (_) =>
              sl<GuardProfileBloc>(param1: owner, param2: bodyguard)
                ..add(const GuardProfileStarted()),
        ),
      ],
      child: _BodyGuardProfileView(bodyguard: bodyguard),
    );
  }
}

class _BodyGuardProfileView extends StatefulWidget {
  final BodyGuardModel? bodyguard;

  const _BodyGuardProfileView({this.bodyguard});

  @override
  State<_BodyGuardProfileView> createState() => _BodyGuardProfileViewState();
}

class _BodyGuardProfileViewState extends State<_BodyGuardProfileView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _tabNames = [
    'About',
    'My Availability',
    'My Documents',
    'Reviews',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabNames.length, vsync: this);
  }

  void _reloadBodyguard() {
    context.read<BodyguardDetailsBloc>().add(const BodyguardDetailsRefreshed());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditBioSheet(BuildContext context, String currentBio) {
    EditBioSheet.show(
      context,
      bloc: context.read<GuardProfileBloc>(),
      currentBio: currentBio,
      onBioUpdated: (_) => _reloadBodyguard(),
    );
  }

  void _showEditKeyDetailsSheet(
    BuildContext context, {
    required int experienceYears,
    required num hourlyRate,
    required String address,
    required double? latitude,
    required double? longitude,
    required String languages,
    required String certifications,
    required String qualifications,
  }) {
    EditKeyDetailsSheet.show(
      context,
      bloc: context.read<GuardProfileBloc>(),
      experienceYears: experienceYears,
      hourlyRate: hourlyRate,
      address: address,
      latitude: latitude,
      longitude: longitude,
      languages: languages,
      certifications: certifications,
      qualifications: qualifications,
      onKeyDetailsUpdated: ({
        experienceYears,
        hourlyRate,
        languages,
        certifications,
        qualifications,
        address,
        latitude,
        longitude,
      }) => _reloadBodyguard(),
    );
  }

  void _showEditServicesSheet(
    BuildContext context, {
    required List<ServiceModel> currentServices,
  }) {
    EditServicesSheet.show(
      context,
      bloc: context.read<GuardProfileBloc>(),
      currentServices: currentServices,
      onServicesUpdated: (_) => _reloadBodyguard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BodyguardDetailsBloc, BodyguardDetailsState>(
      builder: (context, detailsState) {
        return BlocBuilder<GuardProfileBloc, GuardProfileState>(
          builder: (context, profileState) {
            return BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final guard =
                    detailsState.guard ??
                    profileState.profile ??
                    widget.bodyguard ??
                    authState.user?.bodyguard;
                final user = authState.user;
                final isCompanyGuard = widget.bodyguard != null;
                final name = (guard?.name.isNotEmpty == true)
                    ? guard!.name
                    : (user?.name.isNotEmpty == true
                          ? user!.name
                          : 'Bodyguard');
                final rating = guard?.rating ?? 5.0;
                final hourlyRate = guard?.hourlyRate ?? 60.0;
                final avatar = (guard?.profileImageUrl?.isNotEmpty == true)
                    ? guard!.profileImageUrl!
                    : ((user?.profileImageUrl?.isNotEmpty == true)
                          ? user!.profileImageUrl!
                          : Assets.images.dummyAvatar.path);
                final bio = (guard?.bio.isNotEmpty == true) ? guard!.bio : null;
                final location = (guard?.address?.isNotEmpty == true)
                    ? guard!.address!
                    : 'Location not set';
                final experienceYears = guard?.experienceYears ?? 0;
                final languages = guard?.languages ?? '';
                final certifications = guard?.certifications ?? '';
                final qualifications = guard?.qualifications ?? '';

                final profileServices = profileState.selectedServices;
                final effectiveServices = isCompanyGuard
                    ? profileServices
                    : (profileServices.isNotEmpty
                          ? profileServices
                          : authState.userServices);
                final specialization = effectiveServices.isNotEmpty
                    ? effectiveServices.map((s) => s.name).join(', ')
                    : (guard?.bio.isNotEmpty == true
                          ? guard!.bio
                          : 'Executive & VIP Protection');

                return Scaffold(
                  appBar: const AppAppBar.transparent(
                    title: 'My Profile',
                    showBackIcon: true,
                    fontSize: 14,
                    alignTitle: AlignTitle.right,
                  ),
                  body: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Profile Header Card
                        Padding(
                          padding: context.horizontalEdgeInsets,
                          child: BodyGuardHeaderCard(
                            name: name.isNotEmpty ? name : 'Bodyguard',
                            specialization: specialization,
                            rating: rating,
                            location: location,
                            hourlyRate: hourlyRate,
                            avatarAssetPath: avatar,
                            isVerified: true,
                          ),
                        ),
                        AppSpacing.md.h,

                        // Underline Navigation Tab Bar
                        AppTabBar.underline(
                          controller: _tabController,
                          tabNames: _tabNames,
                          isScrollable: true,
                          padding: context.horizontalEdgeInsets,
                        ),

                        // Tab Views
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Tab 1: About
                              SingleChildScrollView(
                                padding:
                                    context.horizontalEdgeInsets +
                                    AppSpacing.md.yPadding,
                                child: BodyguardAboutWidget(
                                  bodyguard: guard,
                                  bio: bio,
                                  hourlyRate: hourlyRate,
                                  experienceYears: experienceYears,
                                  location: location,
                                  languages: languages,
                                  certifications: certifications,
                                  qualifications: qualifications,
                                  services: effectiveServices,
                                  onEditBio: () =>
                                      _showEditBioSheet(context, bio ?? ''),
                                  onEditKeyDetails: () =>
                                      _showEditKeyDetailsSheet(
                                        context,
                                        experienceYears: experienceYears,
                                        hourlyRate: hourlyRate,
                                        address: location == 'Location not set'
                                            ? ''
                                            : location,
                                        latitude: guard?.latitude,
                                        longitude: guard?.longitude,
                                        languages: languages,
                                        certifications: certifications,
                                        qualifications: qualifications,
                                      ),
                                  onEditServices: () => _showEditServicesSheet(
                                    context,
                                    currentServices: effectiveServices,
                                  ),
                                ),
                              ),

                              // Tab 2: My Availability
                              SingleChildScrollView(
                                padding:
                                    context.horizontalEdgeInsets +
                                    AppSpacing.md.yPadding,
                                child: BodyguardAvailabilityWidget(
                                  bodyguard: isCompanyGuard ? guard : null,
                                ),
                              ),

                              // Tab 3: My Documents
                              SingleChildScrollView(
                                padding:
                                    context.horizontalEdgeInsets +
                                    AppSpacing.md.yPadding,
                                child: BodyguardDocumentsWidget(
                                  bodyguard: isCompanyGuard ? guard : null,
                                ),
                              ),

                              // Tab 4: Reviews
                              Padding(
                                padding:
                                    context.horizontalEdgeInsets +
                                    AppSpacing.md.yPadding,
                                child: const BodyguardReviewsWidget(
                                  reviews: [],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
