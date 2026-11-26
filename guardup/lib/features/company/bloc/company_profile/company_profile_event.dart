import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/model/company_profile_request.model.dart';

/// Events dispatched to [CompanyProfileBloc].
sealed class CompanyProfileEvent extends Equatable {
  const CompanyProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the signed-in company's saved profile from `public.companies`.
final class CompanyProfileStarted extends CompanyProfileEvent {
  const CompanyProfileStarted();
}

/// Records a newly cropped/picked company logo image before upload.
final class CompanyProfileLogoPicked extends CompanyProfileEvent {
  const CompanyProfileLogoPicked(this.file);

  final XFile file;

  @override
  List<Object?> get props => [file];
}

/// Persists company profile details (and optional logo upload) for onboarding or editing.
final class CompanyProfileSubmitted extends CompanyProfileEvent {
  const CompanyProfileSubmitted(
    this.request, {
    this.resubmitForReview = false,
    this.refreshAccount = false,
  });

  final CompanyProfileRequest request;
  final bool resubmitForReview;
  final bool refreshAccount;

  @override
  List<Object?> get props => [request, resubmitForReview, refreshAccount];
}
