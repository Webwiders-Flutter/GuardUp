import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/model/user_account_request.model.dart';

/// Events dispatched to [AccountBloc].
sealed class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

/// Updates account-level profile fields and optional avatar image.
final class AccountProfileSaved extends AccountEvent {
  const AccountProfileSaved(this.request, {this.avatar});

  final UserAccountRequest request;
  final XFile? avatar;

  @override
  List<Object?> get props => [request, avatar];
}

/// Re-fetches the latest user profile from `public.users` and refreshes session state.
final class AccountProfileRefreshed extends AccountEvent {
  const AccountProfileRefreshed();
}

/// Changes the signed-in user's password after confirming the old password.
final class AccountPasswordChanged extends AccountEvent {
  const AccountPasswordChanged({
    required this.oldPassword,
    required this.newPassword,
  });

  final String oldPassword;
  final String newPassword;

  @override
  List<Object?> get props => [oldPassword, newPassword];
}

/// Deletes the signed-in user's account and ends the session.
final class AccountDeleteRequested extends AccountEvent {
  const AccountDeleteRequested();
}
