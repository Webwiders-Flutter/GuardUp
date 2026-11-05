// import 'package:flutter/material.dart';
// import 'package:quick_container/quick_container.dart';

// import '/core/constants/app_radius.dart';
// import '/core/constants/app_spacing.dart';
// import '/core/extensions/context.extension.dart';
// import '/core/extensions/spacing.extension.dart';
// import '/core/extensions/textstyle_extension.dart';

// /// Company affiliation card displaying agency name, initials, active guard stats, and booking action.
// class GuardCompanyAffiliationCard extends StatelessWidget {
//   final String companyName;
//   final String initials;
//   final int activeGuards;
//   final double rating;
//   final String bookingsCount;
//   final String experienceYears;
//   final VoidCallback? onBookNow;
//   final VoidCallback? onTap;

//   const GuardCompanyAffiliationCard({
//     super.key,
//     this.companyName = 'SecurePro Security Ltd.',
//     this.initials = 'SP',
//     this.activeGuards = 12,
//     this.rating = 4.9,
//     this.bookingsCount = '340+ Bookings',
//     this.experienceYears = '15+ Yrs Exp',
//     this.onBookNow,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       behavior: HitTestBehavior.opaque,
//       child: QuickContainer(
//         w: double.infinity,
//         p: AppSpacing.sm,
//         borderRadius: BorderRadius.circular(AppRadius.lg),
//         color: context.colors.surfaceContainer,
//         border: Border.all(
//           color: context.colors.outlineVariant.withValues(alpha: 0.5),
//           width: 1,
//         ),
//         child: Row(
//           children: [
//             // Initials Avatar
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: context.colors.surfaceDim,
//                 border: Border.all(
//                   color: context.colors.gold.withValues(alpha: 0.6),
//                   width: 1.2,
//                 ),
//               ),
//               child: Center(
//                 child: Text(
//                   initials,
//                   style: context.textTheme.titleSmall?.bold().colour(
//                     context.colors.gold,
//                   ),
//                 ),
//               ),
//             ),
//             AppSpacing.sm.w,

//             // Company Details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         width: 6,
//                         height: 6,
//                         decoration: BoxDecoration(
//                           color: context.colors.success,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                       AppSpacing.xxs.w,
//                       Text(
//                         '$activeGuards Guards Active',
//                         style: context.textTheme.labelSmall
//                             ?.copyWith(fontSize: 10)
//                             .colour(context.colors.success),
//                       ),
//                     ],
//                   ),
//                   AppSpacing.xxs.h,
//                   Text(
//                     companyName,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: context.textTheme.bodyMedium?.bold().colour(
//                       context.colors.onSurface,
//                     ),
//                   ),
//                   AppSpacing.xxs.h,
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.star_rounded,
//                         size: 14,
//                         color: context.colors.gold,
//                       ),
//                       AppSpacing.xxs.w,
//                       Text(
//                         rating.toStringAsFixed(1),
//                         style: context.textTheme.labelSmall
//                             ?.copyWith(
//                               fontSize: 10.5,
//                               fontWeight: FontWeight.w600,
//                             )
//                             .colour(context.colors.onSurface),
//                       ),
//                       AppSpacing.xs.w,
//                       Text(
//                         '•',
//                         style: TextStyle(
//                           color: context.colors.onSurfaceVariant,
//                           fontSize: 9,
//                         ),
//                       ),
//                       AppSpacing.xs.w,
//                       Text(
//                         bookingsCount,
//                         style: context.textTheme.labelSmall
//                             ?.copyWith(fontSize: 10)
//                             .colour(context.colors.onSurfaceVariant),
//                       ),
//                       AppSpacing.xs.w,
//                       Text(
//                         '•',
//                         style: TextStyle(
//                           color: context.colors.onSurfaceVariant,
//                           fontSize: 9,
//                         ),
//                       ),
//                       AppSpacing.xs.w,
//                       Text(
//                         experienceYears,
//                         style: context.textTheme.labelSmall
//                             ?.copyWith(fontSize: 10)
//                             .colour(context.colors.onSurfaceVariant),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             AppSpacing.xs.w,

//             // Book Now Button
//             GestureDetector(
//               onTap: onBookNow,
//               behavior: HitTestBehavior.opaque,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: AppSpacing.sm,
//                   vertical: 5,
//                 ),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(AppRadius.full),
//                   border: Border.all(
//                     color: context.colors.gold.withValues(alpha: 0.8),
//                     width: 1,
//                   ),
//                   color: context.colors.gold.withValues(alpha: 0.1),
//                 ),
//                 child: Text(
//                   'Book now',
//                   style: context.textTheme.labelSmall
//                       ?.copyWith(fontWeight: FontWeight.w600, fontSize: 10.5)
//                       .colour(context.colors.gold),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
