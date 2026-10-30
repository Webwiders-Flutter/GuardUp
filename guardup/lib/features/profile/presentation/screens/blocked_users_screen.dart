import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/services/injection_container.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/common/custom_app_bar.dart';
import 'package:guardup/core/widgets/common/custom_loader.dart';
import 'package:guardup/features/profile/presentation/bloc/blocked_users/blocked_users_cubit.dart';
import 'package:guardup/features/profile/presentation/bloc/blocked_users/blocked_users_state.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<BlockedUsersCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BlockedUsersCubit>()..fetchBlockedUsers(),
      child: Scaffold(
        backgroundColor: AppColors.mainBackgroundColor,
        appBar: CustomAppBar(
          title: context.l10n.blockedUsers,
          showBackButton: true,
        ),
        body: BlocBuilder<BlockedUsersCubit, BlockedUsersState>(
          builder: (context, state) {
            if (state is BlockedUsersLoading) {
              return const Center(child: CustomLoader());
            } else if (state is BlockedUsersError) {
              return Center(child: AppText(state.message, color: Colors.red));
            } else if (state is BlockedUsersLoaded) {
              final users = state.users;
              if (users.isEmpty) {
                return Center(
                  child: AppText(
                    context.l10n.noDataFound,
                    color: Colors.white54,
                  ),
                );
              }
              return ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: users.length + (state.hasReachedMax ? 0 : 1),
                separatorBuilder: (context, index) =>
                    const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  if (index >= users.length) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CustomLoader()),
                    );
                  }
                  final user = users[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: AppImage(
                        imageUrl: user.profileImage ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: Colors.grey,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ),
                    title: AppText(
                      user.name ?? '',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    trailing: TextButton(
                      onPressed: () {
                        context.read<BlockedUsersCubit>().unblockUser(user.id);
                      },
                      child: AppText(
                        context.l10n.unblock,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
