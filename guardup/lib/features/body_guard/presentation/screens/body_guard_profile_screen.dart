import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState, OtpType;

import '/core/constants/api/database_tables.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/spacing.extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/model/body_guard.model.dart';
import '../../data/model/service_item.model.dart';
import '../widgets/body_guard_header_card.dart';
import '../widgets/sheets/sheets.dart';
import '../widgets/tabs/bodyguard_about.widget.dart';
import '../widgets/tabs/bodyguard_availability.widget.dart';
import '../widgets/tabs/bodyguard_documents.widget.dart';
import '../widgets/tabs/bodyguard_reviews.widget.dart';

/// Bodyguard operational profile screen featuring the profile header card,
/// underline tabs navigation, and modular tab widgets.
class BodyGuardProfileScreen extends StatefulWidget {
  static const route = '/bodyguard-information';

  final BodyGuardModel? bodyguard;

  const BodyGuardProfileScreen({super.key, this.bodyguard});

  @override
  State<BodyGuardProfileScreen> createState() => _BodyGuardProfileScreenState();
}

class _BodyGuardProfileScreenState extends State<BodyGuardProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ValueNotifier<List<ServiceItemModel>> _servicesNotifier =
      ValueNotifier<List<ServiceItemModel>>([]);

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
    if (sl.isRegistered<AuthBloc>()) {
      final initialServices = sl<AuthBloc>().state.userServices;
      if (initialServices.isNotEmpty) {
        _servicesNotifier.value = initialServices;
      }
    }
    _loadUserServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _servicesNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadUserServices() async {
    final currentUserId = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentUserId
        : null;
    if (currentUserId == null) return;

    try {
      // 1. Fetch user's assigned service IDs from public.user_services
      final userServicesRows = await Supabase.instance.client
          .from(DatabaseTables.userServices)
          .select('service_id')
          .eq('user_id', currentUserId);

      final serviceIds = (userServicesRows as List<dynamic>)
          .map((r) => r['service_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      if (serviceIds.isEmpty) {
        if (mounted) _servicesNotifier.value = [];
        return;
      }

      // 2. Fetch active services (all available columns: id, name, description, etc.)
      final serviceRows = await Supabase.instance.client
          .from(DatabaseTables.services)
          .select()
          .order('display_order', ascending: true);

      final loaded = (serviceRows as List<dynamic>)
          .map((r) => ServiceItemModel.fromJson(r as Map<String, dynamic>))
          .where((s) => serviceIds.contains(s.id))
          .toList();

      if (mounted) {
        _servicesNotifier.value = loaded;
        if (sl.isRegistered<AuthBloc>()) {
          sl<AuthBloc>().add(AuthUpdateUserServices(loaded));
        }
      }
    } catch (e) {
      debugPrint('Error loading user services: $e');
    }
  }

  void _showEditBioSheet(BuildContext context, String currentBio) {
    EditBioSheet.show(context, currentBio: currentBio);
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
  }) {
    EditKeyDetailsSheet.show(
      context,
      experienceYears: experienceYears,
      hourlyRate: hourlyRate,
      address: address,
      latitude: latitude,
      longitude: longitude,
      languages: languages,
      certifications: certifications,
    );
  }

  void _showEditServicesSheet(
    BuildContext context, {
    required List<ServiceItemModel> currentServices,
  }) {
    EditServicesSheet.show(
      context,
      currentServices: currentServices,
      onServicesUpdated: (updated) {
        _servicesNotifier.value = updated;
        _loadUserServices();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      bloc: sl<AuthBloc>(),
      listenWhen: (prev, curr) => prev.userServices != curr.userServices,
      listener: (context, state) {
        if (state.userServices.isNotEmpty) {
          _servicesNotifier.value = state.userServices;
        }
      },
      builder: (context, state) {
        final guard = widget.bodyguard;
        final name =
            guard?.user.name ?? (state.user?.name ?? state.displayName);
        final rating = guard?.rating ?? state.rating;
        final hourlyRate =
            guard?.hourlyRate ??
            (state.hourlyRate > 0 ? state.hourlyRate : 60.0);
        final avatar =
            guard?.user.profileImageUrl ??
            (state.avatarUrl.isNotEmpty
                ? state.avatarUrl
                : Assets.images.dummyAvatar.path);
        final bio = guard?.bio ?? (state.bio.isNotEmpty ? state.bio : null);
        final location = state.address.isNotEmpty
            ? state.address
            : 'Location not set';

        return ValueListenableBuilder<List<ServiceItemModel>>(
          valueListenable: _servicesNotifier,
          builder: (context, userServices, _) {
            final effectiveServices = userServices.isNotEmpty
                ? userServices
                : state.userServices;
            final specialization = effectiveServices.isNotEmpty
                ? effectiveServices.map((s) => s.name).join(', ')
                : (guard?.clearanceLevel ?? state.specializationText);

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
                              experienceYears: state.experienceYears,
                              location: location,
                              languages: state.languages,
                              certifications: state.certifications,
                              services: effectiveServices,
                              onEditBio: () =>
                                  _showEditBioSheet(context, bio ?? ''),
                              onEditKeyDetails: () => _showEditKeyDetailsSheet(
                                context,
                                experienceYears: state.experienceYears,
                                hourlyRate: hourlyRate,
                                address: state.address,
                                latitude: state.latitude,
                                longitude: state.longitude,
                                languages: state.languages,
                                certifications: state.certifications,
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
                            child: const BodyguardAvailabilityWidget(),
                          ),

                          // Tab 3: My Documents
                          SingleChildScrollView(
                            padding:
                                context.horizontalEdgeInsets +
                                AppSpacing.md.yPadding,
                            child: const BodyguardDocumentsWidget(),
                          ),

                          // Tab 4: Reviews
                          Padding(
                            padding:
                                context.horizontalEdgeInsets +
                                AppSpacing.md.yPadding,
                            child: const BodyguardReviewsWidget(reviews: []),
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
  }
}
