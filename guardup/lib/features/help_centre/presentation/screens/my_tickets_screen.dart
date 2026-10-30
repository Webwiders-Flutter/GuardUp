import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/error/error_keys.dart';
import 'package:guardup/core/services/injection_container.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/common/custom_app_bar.dart';
import 'package:guardup/core/widgets/common/custom_loader.dart';
import 'package:guardup/features/auth/presentation/widgets/login_gate_bottom_sheet.dart';
import 'package:guardup/features/help_centre/domain/entities/ticket_entity.dart';
import 'package:guardup/features/help_centre/presentation/widgets/ticket_card_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bloc/support_cubit.dart';
import '../bloc/support_state.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

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
      child: const _MyTicketsView(),
    );
  }
}

class _MyTicketsView extends StatefulWidget {
  const _MyTicketsView();

  @override
  State<_MyTicketsView> createState() => _MyTicketsViewState();
}

class _MyTicketsViewState extends State<_MyTicketsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SupportCubit>().loadMoreMyTickets();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() => context.read<SupportCubit>().getMyTickets();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackgroundColor,
      appBar: CustomAppBar(title: context.l10n.myTickets, showBackButton: true),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                AppAssets.backgroundImage,
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
              ),
            ),
          ),
          BlocBuilder<SupportCubit, SupportState>(
            builder: (context, state) {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId == null) {
                return _buildGuestState(context);
              }
              if (state is SupportLoading) {
                return const Center(child: CustomLoader());
              } else if (state is SupportError) {
                if (state.message == ErrorKeys.userNotAuthenticated) {
                  return _buildGuestState(context);
                }
                return Center(
                  child: AppText(
                    context.translateFailure(state.message),
                    color: Colors.red,
                  ),
                );
              } else if (state is MyTicketsLoaded) {
                return state.tickets.isEmpty
                    ? _buildEmptyState(context)
                    : _buildTicketList(context, state);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
                      color: AppColors.secondary,
                      size: 40,
                    ),
                  ),
                  16.height,
                  Text(
                    context.l10n.noDataFound,
                    style: const TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  8.height,
                  Text(
                    context.l10n.submitATicketAndWeWillGetBackToYou,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.headingTextFieldColor,
                      fontSize: 13,
                    ),
                  ),
                  20.height,
                  GestureDetector(
                    onTap: () => _onCreateTicket(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 18),
                          8.width,
                          Text(
                            context.l10n.createATicket,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  60.height,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList(BuildContext context, MyTicketsLoaded state) {
    final tickets = state.tickets;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(), // <-- the fix
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length + (state.hasReachedMax ? 0 : 1),
        separatorBuilder: (context, index) => 12.height,
        itemBuilder: (context, index) {
          if (index >= tickets.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CustomLoader(),
              ),
            );
          }
          final ticket = tickets[index];
          return _buildTicketItem(context, ticket);
        },
      ),
    );
  }

  Widget _buildTicketItem(BuildContext context, TicketEntity ticket) {
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

  Widget _buildGuestState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.secondary,
                    size: 40,
                  ),
                ),
                16.height,
                Text(
                  context.l10n.errorUserNotAuthenticated,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                20.height,
                GestureDetector(
                  onTap: () => LoginGateBottomSheet.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.l10n.logIn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                60.height,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
