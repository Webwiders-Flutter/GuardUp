import 'package:flutter/material.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/data/model/body_guard.model.dart';
import '/features/booking/booking.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.state.dart';

/// Company View "Booking" Tab: Displays the operative's bookings feed powered by [AppPagination].
class CompanyGuardBookingsTabWidget extends StatelessWidget {
  final BodyGuardModel bodyguard;

  const CompanyGuardBookingsTabWidget({super.key, required this.bodyguard});

  @override
  Widget build(BuildContext context) {
    // Generate bookings using standard mock data mapped to the current operative
    final bookings = BookingModel.fakeData
        .map((booking) => booking.copyWith(bodyguard: bodyguard))
        .toList();

    return AppPagination<BookingModel>.list(
      state: PaginationState<BookingModel>(
        items: bookings,
        total: bookings.length,
        status: const ApiState.success(null),
      ),
      padding: context.horizontalEdgeInsets + const EdgeInsets.only(bottom: 24),
      separatorBuilder: (context, index) => AppSpacing.md.h,
      emptyBuilder: (context) => Center(
        child: Padding(
          padding: AppSpacing.xxl.allPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: AppSizes.icon2Xl,
                color: context.colors.outline,
              ),
              AppSpacing.md.h,
              Text(
                'No bookings found',
                style: context.textTheme.titleSmall?.semiBold(),
              ),
              AppSpacing.xs.h,
              Text(
                'There are no active or past bookings for this bodyguard.',
                style: context.textTheme.bodySmall?.colour(
                  context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      itemBuilder: (context, booking, index) {
        return BookingCard(
          booking: booking,
          role: UserRole.company,
          noAction: true,
        );
      },
    );
  }
}
