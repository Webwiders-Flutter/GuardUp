import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/app_logs.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/app_textfield/app_textfield.dart';
import 'package:guardup/core/widgets/common/custom_app_bar.dart';
import 'package:guardup/core/widgets/common/custom_loader.dart';
import 'package:guardup/features/locations/domain/entities/location_state_entity.dart';
import 'package:guardup/features/locations/presentation/bloc/state_bloc/state_bloc.dart';

class SelectStateScreen extends StatefulWidget {
  final int countryId;
  const SelectStateScreen({super.key, required this.countryId});

  @override
  State<SelectStateScreen> createState() => _SelectStateScreenState();
}

class _SelectStateScreenState extends State<SelectStateScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<StateBloc>().add(FetchStates(countryId: widget.countryId));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    bool isBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;
    if (isBottom) {
      final currentState = context.read<StateBloc>().state;
      if (currentState is StateLoaded && !currentState.hasReachedMax) {
        context.read<StateBloc>().add(
          LoadMoreStates(
            countryId: widget.countryId,
            searchQuery: searchController.text.trim().isEmpty
                ? null
                : searchController.text.trim(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<StateBloc>().add(
        FetchStates(
          countryId: widget.countryId,
          isRefresh: true,
          searchQuery: text.trim().isEmpty ? null : text.trim(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.color081026,
      appBar: CustomAppBar(
        title: context.l10n.selectState,
        titleColor: AppColors.whiteColor,
        backgroundColor: AppColors.color081026,
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            AppTextField(
              controller: searchController,
              hintText: context.l10n.searchState,
              onChanged: _onSearchChanged,
              borderColor: Colors.transparent,
              headingText: "",
              keyboardType: TextInputType.text,
              borderType: AppTextFieldBorderType.outline,
              prefix: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Image.asset(AppAssets.searchIcon, height: 10, width: 10),
              ),
            ),
            10.height,
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<StateBloc>().add(
                    FetchStates(
                      countryId: widget.countryId,
                      isRefresh: true,
                      searchQuery: searchController.text.trim().isEmpty
                          ? null
                          : searchController.text.trim(),
                    ),
                  );
                },
                color: AppColors.primary,
                backgroundColor: AppColors.color132030,
                child: BlocBuilder<StateBloc, StateState>(
                  builder: (context, state) {
                    if (state is StateInitial || state is StateLoading) {
                      return const Center(child: CustomLoader());
                    }

                    if (state is StateError) {
                      return ListView(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 50.0),
                              child: AppText(
                                state.message,
                                color: AppColors.whiteColor,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    if (state is StateLoaded) {
                      AppLogs.info("Loaded ${state.states.length} states.");
                      if (state.states.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 50.0),
                                child: Text(
                                  context.l10n.noStatesFound,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.color8D8D8D,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 20),
                        separatorBuilder: (_, _) => const SizedBox(height: 15),
                        itemCount:
                            state.states.length + (state.hasReachedMax ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (index == state.states.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CustomLoader(),
                            );
                          }
                          final LocationStateEntity locationState =
                              state.states[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context, locationState);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: AppColors.color132030,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: AppText(
                                      locationState.nameEn,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                      color: AppColors.headingTextFieldColor,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.whiteColor,
                                    size: 15,
                                  ),
                                ],
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
            ),
          ],
        ),
      ),
    );
  }
}
