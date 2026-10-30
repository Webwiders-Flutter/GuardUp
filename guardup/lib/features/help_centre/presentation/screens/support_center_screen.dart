import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/app_types/image_types.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/error/error_keys.dart';
import 'package:guardup/core/services/injection_container.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';
import 'package:guardup/core/widgets/common/custom_app_bar.dart';
import 'package:guardup/core/widgets/common/custom_loader.dart';
import 'package:guardup/features/auth/presentation/widgets/login_gate_bottom_sheet.dart';
import 'package:guardup/features/help_centre/domain/entities/ticket_entity.dart';
import 'package:guardup/features/help_centre/presentation/widgets/ticket_card_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bloc/support_cubit.dart';
import '../bloc/support_state.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return BlocProvider(
      create: (context) {
        final cubit = sl<SupportCubit>();
        if (userId != null) {
          cubit.getMyTickets();
        }
        return cubit;
      },
      child: const _SupportCenterView(),
    );
  }
}

class _SupportCenterView extends StatelessWidget {
  const _SupportCenterView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackgroundColor,
      appBar: CustomAppBar(
        title: context.l10n.supportCenter,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.howCanWeHelpYou,
              style: const TextStyle(
                color: AppColors.whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            16.height,
            _ActionCard(
              iconPath: AppAssets.ticketsIcon,
              title: context.l10n.createATicket,
              subtitle: context.l10n.submitATicketAndWeWillGetBackToYou,
              onTap: () => _onCreateTicket(context),
            ),
            32.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.yourTickets,
                  style: const TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final userId =
                        Supabase.instance.client.auth.currentUser?.id;
                    if (userId == null) {
                      LoginGateBottomSheet.show(context);
                    } else {
                      context.push(AppRouter.myTickets);
                    }
                  },
                  child: const Icon(
                    Icons.arrow_forward,
                    color: AppColors.headingTextFieldColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            16.height,
            BlocBuilder<SupportCubit, SupportState>(
              builder: (context, state) {
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId == null) {
                  return const _GuestTicketsPromptWidget();
                }
                if (state is SupportLoading) {
                  return const Center(
                    child: SizedBox(height: 400, child: CustomLoader()),
                  );
                } else if (state is SupportError) {
                  if (state.message == ErrorKeys.userNotAuthenticated) {
                    return const _GuestTicketsPromptWidget();
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        context.translateFailure(state.message),
                        style: const TextStyle(color: AppColors.color8D8D8D),
                      ),
                    ),
                  );
                } else if (state is MyTicketsLoaded) {
                  return state.tickets.isEmpty
                      ? const _EmptyTicketsWidget()
                      : _TicketPreviewList(tickets: state.tickets);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCreateTicket(BuildContext context) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      LoginGateBottomSheet.show(context);
      return;
    }
    final cubit = context.read<SupportCubit>();
    final newTicket = await context.push<TicketEntity>(AppRouter.createTicket);
    if (newTicket != null && context.mounted) {
      cubit.insertTicket(newTicket);
    }
  }
}

class _TicketPreviewList extends StatelessWidget {
  const _TicketPreviewList({required this.tickets});

  final List<TicketEntity> tickets;

  @override
  Widget build(BuildContext context) {
    final displayedTickets = tickets.take(4).toList();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayedTickets.length,
      separatorBuilder: (context, index) => 12.height,
      itemBuilder: (context, index) {
        final ticket = displayedTickets[index];
        return GestureDetector(
          onTap: () async {
            final updatedTicket = await context.push<TicketEntity>(
              AppRouter.ticketDetail,
              extra: ticket,
            );
            if (updatedTicket != null && context.mounted) {
              context.read<SupportCubit>().updateTicketLocally(updatedTicket);
            }
          },
          child: TicketCardWidget(
            ticketId: "#${ticket.id.substring(0, 8).toUpperCase()}",
            category: ticket.category,
            date: ticket.createdAt.toString().split(' ')[0],
            status: ticket.status,
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppImage(
                  imageUrl: iconPath,
                  appFileType: AppImageTypes.asset,
                  height: 24,
                  width: 24,
                ),
              ),
            ),
            16.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  4.height,
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.headingTextFieldColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.headingTextFieldColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTicketsWidget extends StatelessWidget {
  const _EmptyTicketsWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 50),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.lightBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.secondary,
              size: 32,
            ),
          ),
          12.height,
          Text(
            context.l10n.noDataFound,
            style: const TextStyle(
              color: AppColors.whiteColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          6.height,
          Text(
            context.l10n.submitATicketAndWeWillGetBackToYou,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.headingTextFieldColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestTicketsPromptWidget extends StatelessWidget {
  const _GuestTicketsPromptWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.lightBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.secondary,
              size: 32,
            ),
          ),
          12.height,
          Text(
            context.l10n.errorUserNotAuthenticated,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.whiteColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          16.height,
          AppButton(
            text: context.l10n.logIn,
            buttonColor: AppColors.secondary,
            textColor: AppColors.blackColor,
            onPressed: () => LoginGateBottomSheet.show(context),
          ),
        ],
      ),
    );
  }
}
