import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/widgets/common/custom_app_bar.dart';
import 'package:guardup/features/profile/presentation/screens/profile_screen.dart';

import 'bloc/dashboard_cubit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardCubit dashboardCubit;

  @override
  void initState() {
    super.initState();
    dashboardCubit = DashboardCubit();
    _checkPendingSharedVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPendingSharedVideo();
  }

  void _checkPendingSharedVideo() {
    // print(
    //   ">>> [SharingIntent] DashboardScreen _checkPendingSharedVideo: pendingSharedVideoPath=$pendingSharedVideoPath",
    // );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // if (pendingSharedVideoPath != null && mounted) {
      //   final path = pendingSharedVideoPath!;
      //   print(
      //     ">>> [SharingIntent] DashboardScreen consuming pendingSharedVideoPath=$path and pushing UploadVideoScreen...",
      //   );
      //   pendingSharedVideoPath = null;
      //   context.push(AppRouter.uploadVideo, extra: {'sharedVideoPath': path});
      // }
    });
  }

  @override
  void dispose() {
    dashboardCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: dashboardCubit, child: DashboardView());
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  static const List<Widget> _pages = [
    // HomeScreen(),
    // SelectCountryScreen(route: "universities"),
    // TravelScreen(),
    // VideoHubScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final currentIndex = state.currentIndex;
        final isFullScreen = state.isFullScreen;
        final isCurrent = route?.isCurrent ?? false;

        return BackButtonListener(
          onBackButtonPressed: () async {
            if (!isCurrent) {
              return false; // Let the top route handle the back button
            }
            await handleBackPress(context, currentIndex);
            return true;
          },
          child: Scaffold(
            appBar: (currentIndex == 3 || isFullScreen)
                ? null
                : CustomAppBar(
                    backgroundColor: AppColors.mainBackgroundColor,
                    showBackButton: false,
                    // leadingWidth: 120,
                    // leading: Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 02),
                    //   child: Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       const NotificationActionWidget(),

                    //       // const LanguageSelectorWidget(),
                    //     ],
                    //   ),
                    // ),
                    centerTitle: true,
                    // titleWidget: const BrandLogoTitleWidget(),

                    actions: [
                      // UserProfileBadgeWidget(
                      //   onAvatarTap: () {
                      //     context.read<DashboardCubit>().changeTab(4);
                      //   },
                      // ),
                    ],
                  ),
            backgroundColor: AppColors.mainBackgroundColor,
            body: IndexedStack(index: currentIndex, children: _pages),
            bottomNavigationBar: (currentIndex == 3 && isFullScreen)
                ? null
                : Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: Container(
                      padding: EdgeInsets.only(top: 06),
                      decoration: const BoxDecoration(
                        color: AppColors.mainBackgroundColor,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.whiteColor,
                            width: 0.2,
                          ),
                        ),
                      ),
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          viewPadding: Platform.isIOS
                              ? MediaQuery.of(context).viewPadding.copyWith(
                                  bottom: 10.0, // Set your desired custom bottom spacing
                                )
                              : null,
                        ),
                        child: BottomNavigationBar(
                          currentIndex: currentIndex,

                          type: BottomNavigationBarType.fixed,
                          backgroundColor: AppColors.mainBackgroundColor,
                          selectedFontSize: 10,
                          unselectedFontSize: 10,
                          selectedItemColor: AppColors.secondary,
                          unselectedItemColor: Colors.grey,

                          onTap: (value) {
                            context.read<DashboardCubit>().changeTab(value);
                          },

                          // items: [
                          //   BottomNavigationBarItem(
                          //     icon: Image.asset(
                          //       AppAssets.unfillHomeIcon,
                          //       height: 22,
                          //       width: 22,
                          //     ),
                          //     activeIcon: Image.asset(
                          //       AppAssets.fillHomeIcon,
                          //       height: 25,
                          //       width: 25,
                          //     ),
                          //     label: context.l10n.navHome,
                          //   ),
                          //   BottomNavigationBarItem(
                          //     icon: Image.asset(
                          //       AppAssets.unfillUniversitiesIcon,
                          //       height: 25,
                          //       width: 25,
                          //     ),
                          //     activeIcon: Image.asset(
                          //       AppAssets.fillUniversitiesIcon,
                          //       height: 25,
                          //       width: 25,
                          //     ),
                          //     label: context.l10n.navUniversities,
                          //   ),
                          //   BottomNavigationBarItem(
                          //     icon: Image.asset(
                          //       AppAssets.unfillAirplaneIcon,
                          //       height: 25,
                          //       width: 25,
                          //     ),
                          //     activeIcon: Image.asset(
                          //       AppAssets.fillAirplaneIcon,
                          //       height: 25,
                          //       width: 25,
                          //     ),
                          //     label: context.l10n.navTravel,
                          //   ),
                          //   BottomNavigationBarItem(
                          //     // icon: Icon(vco),
                          //     icon: Image.asset(
                          //       AppAssets.reelOutline,
                          //       height: 26,
                          //       width: 26,
                          //       color: Color(0xFF7B7B7B),
                          //     ),
                          //     activeIcon: Image.asset(
                          //       AppAssets.reel,
                          //       height: 28,
                          //       width: 28,
                          //       color: AppColors.secondary,
                          //     ),
                          //     label: context.l10n.navVideoHub,
                          //   ),
                          //   BottomNavigationBarItem(
                          //     icon: Image.asset(
                          //       AppAssets.unfillProfileIcon,
                          //       height: 24,
                          //       width: 24,
                          //     ),
                          //     activeIcon: Image.asset(
                          //       AppAssets.fillProfileIcon,
                          //       height: 26,
                          //       width: 26,
                          //     ),
                          //     label: context.l10n.navProfile,
                          //   ),
                          // ],
                          items: [
                            CommonBottomNavItem.item(
                              icon: AppAssets.unfillHomeIcon,
                              activeIcon: AppAssets.fillHomeIcon,
                              iconSize: 22,
                              activeIconSize: 24,
                              label: context.l10n.navHome,
                            ),

                            CommonBottomNavItem.item(
                              icon: AppAssets.unfillUniversitiesIcon,
                              activeIcon: AppAssets.fillUniversitiesIcon,
                              iconSize: 25,
                              activeIconSize: 24,
                              label: context.l10n.navUniversities,
                            ),

                            CommonBottomNavItem.item(
                              icon: AppAssets.unfillAirplaneIcon,
                              activeIcon: AppAssets.fillAirplaneIcon,
                              iconSize: 24,
                              activeIconSize: 24,
                              label: context.l10n.navTravel,
                            ),

                            CommonBottomNavItem.item(
                              icon: AppAssets.reelOutline,
                              activeIcon: AppAssets.reel,
                              iconSize: 26,
                              activeIconSize: 28,
                              iconColor: const Color(0xFF7B7B7B),
                              activeIconColor: AppColors.secondary,
                              label: context.l10n.navVideoHub,
                            ),

                            CommonBottomNavItem.item(
                              icon: AppAssets.unfillProfileIcon,
                              activeIcon: AppAssets.fillProfileIcon,
                              iconSize: 24,
                              activeIconSize: 26,
                              label: context.l10n.navProfile,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  static bool _isExitDialogShowing = false;
  Future<bool> _showExitDialog(BuildContext context) async {
    if (_isExitDialogShowing) return false;

    _isExitDialogShowing = true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                context.l10n.exitApplication,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.3,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                context.l10n.areYouSureYouWantToExitTheApplication,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      style: OutlinedButton.styleFrom(
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.l10n.cancel,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF111827),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.l10n.exit,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    _isExitDialogShowing = false;

    return result ?? false;
  }

  Future<void> handleBackPress(BuildContext context, int currentIndex) async {
    final dashboardCubit = context.read<DashboardCubit>();
    final isFullScreen = dashboardCubit.state.isFullScreen;

    if (currentIndex == 3 && isFullScreen) {
      dashboardCubit.setFullScreen(false);
      return;
    }

    // If not on Home tab, go to Home tab
    if (currentIndex != 0) {
      dashboardCubit.changeTab(0);
      return;
    }
    final shouldExit = await _showExitDialog(context);

    if (shouldExit) {
      SystemNavigator.pop();
    }
  }
}

class CommonBottomNavItem {
  static BottomNavigationBarItem item({
    required String icon,
    required String activeIcon,
    required String label,
    double iconSize = 24,
    double activeIconSize = 26,
    Color? iconColor,
    Color? activeIconColor,
  }) {
    return BottomNavigationBarItem(
      icon: SizedBox(
        height: 30,
        // width: 30,
        child: Center(
          child: Image.asset(
            icon,
            height: iconSize,
            width: iconSize,
            color: iconColor,
            fit: BoxFit.contain,
          ),
        ),
      ),
      activeIcon: SizedBox(
        height: 30,
        width: 30,
        child: Center(
          child: Image.asset(
            activeIcon,
            height: activeIconSize,
            width: activeIconSize,
            color: activeIconColor,
            fit: BoxFit.contain,
          ),
        ),
      ),
      label: label,
    );
  }
}
