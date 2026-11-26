import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/model/bodyguard_profile_request.model.dart';

/// Events dispatched to [GuardProfileBloc].
sealed class GuardProfileEvent extends Equatable {
  const GuardProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Loads active services, existing profile details, and assigned services.
final class GuardProfileStarted extends GuardProfileEvent {
  const GuardProfileStarted();
}

/// Reloads only the active services catalog (e.g. pull-to-refresh).
final class GuardProfileServicesRefreshed extends GuardProfileEvent {
  const GuardProfileServicesRefreshed();
}

/// Records a newly cropped/picked profile photo before upload.
final class GuardProfileAvatarPicked extends GuardProfileEvent {
  const GuardProfileAvatarPicked(this.file);

  final XFile file;

  @override
  List<Object?> get props => [file];
}

/// Updates the local service id selection during profile setup.
final class GuardProfileServicesChanged extends GuardProfileEvent {
  const GuardProfileServicesChanged(this.serviceIds);

  final List<String> serviceIds;

  @override
  List<Object?> get props => [serviceIds];
}

/// Submits the full bodyguard profile form (self-guard or managed guard).
final class GuardProfileSubmitted extends GuardProfileEvent {
  const GuardProfileSubmitted(this.request, {this.resubmitForReview = false});

  final BodyguardProfileRequest request;
  final bool resubmitForReview;

  @override
  List<Object?> get props => [request, resubmitForReview];
}

/// Updates only the bodyguard bio from the profile edit sheet.
final class GuardProfileBioSaved extends GuardProfileEvent {
  const GuardProfileBioSaved(this.bio);

  final String bio;

  @override
  List<Object?> get props => [bio];
}

/// Updates the operational key details from the profile edit sheet.
final class GuardProfileKeyDetailsSaved extends GuardProfileEvent {
  const GuardProfileKeyDetailsSaved({
    required this.experienceYears,
    required this.hourlyRate,
    required this.address,
    this.latitude,
    this.longitude,
    required this.languages,
    required this.certifications,
    required this.qualifications,
  });

  final int experienceYears;
  final num hourlyRate;
  final String address;
  final double? latitude;
  final double? longitude;
  final String languages;
  final String certifications;
  final String qualifications;

  @override
  List<Object?> get props => [
    experienceYears,
    hourlyRate,
    address,
    latitude,
    longitude,
    languages,
    certifications,
    qualifications,
  ];
}

/// Persists updated service assignments from the manage-services edit sheet.
final class GuardProfileServicesSaved extends GuardProfileEvent {
  const GuardProfileServicesSaved(this.serviceIds);

  final List<String> serviceIds;

  @override
  List<Object?> get props => [serviceIds];
}
