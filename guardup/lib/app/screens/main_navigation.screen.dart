// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '/core/constants/app_radius.dart';
// import '/core/extensions/context.extension.dart';
// import '/core/extensions/localization.extension.dart';
// import '/core/extensions/spacing.extension.dart';
// import '/core/extensions/textstyle_extension.dart';
// import '/features/auth/data/models/user_model.dart';
// import '/features/auth/di/auth.provider.dart';
// import '/shared/widgets/feedbacks/widgets/app_popup.dart';

// import '/core/logger/app_logger.dart';
// import '/gen/assets.gen.dart';

// class _NavItemData {
//   final String label;
//   final SvgGenImage svg;
//   final int branchIndex;

//   const _NavItemData({
//     required this.label,
//     required this.svg,
//     required this.branchIndex,
//   });
// }

// class MainNavigationScreen extends ConsumerStatefulWidget {
//   final StatefulNavigationShell navigationShell;

//   const MainNavigationScreen({super.key, required this.navigationShell});

//   @override
//   ConsumerState<MainNavigationScreen> createState() =>
//       _MainNavigationScreenState();
// }

// class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
//     with WidgetsBindingObserver {
//   List<_NavItemData> _getNavItems(BuildContext context, UserModel? user) {
//     final isBuyerSeller = user?.isBuyerSeller ?? false;
//     final isTransporter = user?.isTransporter ?? false;
//     final l10n = context.l10n;

//     return [
//       _NavItemData(label: l10n.navHome, svg: Assets.svg.home, branchIndex: 0),
//       if (isBuyerSeller)
//         _NavItemData(
//           label: l10n.navOrders,
//           svg: Assets.svg.order01,
//           branchIndex: 1,
//         )
//       else if (isTransporter)
//         _NavItemData(
//           label: l10n.navEnquiry,
//           svg: Assets.svg.enquiry,
//           branchIndex: 1,
//         ),
//       _NavItemData(label: l10n.navTrips, svg: Assets.svg.trips, branchIndex: 2),
//       if (isTransporter || isBuyerSeller)
//         _NavItemData(
//           label: l10n.navPayments,
//           svg: Assets.svg.payments,
//           branchIndex: 3,
//         )
//       else
//         _NavItemData(
//           label: l10n.navDocuments,
//           svg: Assets.svg.documents,
//           branchIndex: 3,
//         ),
//       _NavItemData(label: l10n.navMore, svg: Assets.svg.more, branchIndex: 4),
//     ];
//   }

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     switch (state) {
//       case AppLifecycleState.resumed:
//         AppLogger.i('AppLifecycleState.resumed');
//         break;
//       case AppLifecycleState.inactive:
//         AppLogger.i('AppLifecycleState.inactive');
//         break;
//       case AppLifecycleState.paused:
//         AppLogger.i('AppLifecycleState.paused');
//         break;
//       case AppLifecycleState.detached:
//         AppLogger.i('AppLifecycleState.detached');
//         break;
//       case AppLifecycleState.hidden:
//         AppLogger.i('AppLifecycleState.hidden');
//         break;
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   void _onTap(int branchIndex) {
//     widget.navigationShell.goBranch(
//       branchIndex,
//       initialLocation: branchIndex == widget.navigationShell.currentIndex,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentIndex = widget.navigationShell.currentIndex;
//     final user = ref.watch(authControllerProvider).value;
//     final navItems = _getNavItems(context, user);

//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, result) async {
//         if (didPop) return;
//         if (currentIndex != 0) {
//           _onTap(0);
//           return;
//         }
//         final popupResult = await AppPopup.showExitConfirmation(context);
//         if (popupResult?.action == PopupAction.confirm) {
//           SystemNavigator.pop();
//         }
//       },
//       child: Scaffold(
//         body: widget.navigationShell,
//         bottomNavigationBar: Container(
//           color: context.colors.primary,
//           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//           child: SafeArea(
//             top: false,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: List.generate(navItems.length, (index) {
//                 final item = navItems[index];
//                 final isSelected = item.branchIndex == currentIndex;

//                 return Expanded(
//                   child: GestureDetector(
//                     onTap: () => _onTap(item.branchIndex),
//                     behavior: HitTestBehavior.opaque,
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 200),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 6,
//                       ),
//                       decoration: BoxDecoration(
//                         color: isSelected
//                             ? context.colors.secondary
//                             : context.colors.transparent,
//                         borderRadius: AppRadius.mdRadius,
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Badge(
//                             isLabelVisible: false,
//                             label: Text(
//                               '5',
//                               style: TextStyle(
//                                 color: context.colors.onPrimary,
//                                 fontSize: 10,
//                               ),
//                             ),
//                             child: item.svg.svg(
//                               width: 22,
//                               height: 22,
//                               colorFilter: ColorFilter.mode(
//                                 context.colors.onPrimary,
//                                 BlendMode.srcIn,
//                               ),
//                             ),
//                           ),
//                           4.h,
//                           Text(
//                             item.label,
//                             style: context.textTheme.labelSmall
//                                 ?.medium()
//                                 .colour(context.colors.onPrimary)
//                                 .size(11),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               }),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
