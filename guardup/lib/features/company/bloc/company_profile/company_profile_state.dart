import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '/core/state/api_state.dart';
import '../../data/model/company.model.dart';

/// Immutable state for [CompanyProfileBloc].
final class CompanyProfileState extends Equatable {
  const CompanyProfileState({
    this.loadStatus = const ApiState.initial(),
    this.company,
    this.pickedLogo,
    this.submitStatus = const ApiState.initial(),
    this.resubmittedForReview = false,
  });

  final ApiState<void> loadStatus;
  final CompanyModel? company;
  final XFile? pickedLogo;
  final ApiState<void> submitStatus;
  final bool resubmittedForReview;

  CompanyProfileState copyWith({
    ApiState<void>? loadStatus,
    CompanyModel? company,
    XFile? pickedLogo,
    bool clearPickedLogo = false,
    ApiState<void>? submitStatus,
    bool? resubmittedForReview,
  }) {
    return CompanyProfileState(
      loadStatus: loadStatus ?? this.loadStatus,
      company: company ?? this.company,
      pickedLogo: clearPickedLogo ? null : (pickedLogo ?? this.pickedLogo),
      submitStatus: submitStatus ?? this.submitStatus,
      resubmittedForReview:
          resubmittedForReview ?? this.resubmittedForReview,
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    company,
    pickedLogo,
    submitStatus,
    resubmittedForReview,
  ];
}
