import 'package:flutter/widgets.dart';

import '/core/error/api_exception.dart';
import '/core/extensions/localization.extension.dart';

/// Turns an error carried by an `ApiState.failure` into user-facing text.
///
/// `asyncHandler` builds its generic messages (network, timeout, unknown) in
/// English because it has no `BuildContext`; this extension localises them at
/// the point of display. Specific server/auth messages are shown as-is.
extension ApiErrorTextX on BuildContext {
  String apiErrorText(Object? error, {String? fallback}) {
    if (error is ApiException) {
      return switch (error.type) {
        ApiErrorType.network => l10n.noInternetConnection,
        ApiErrorType.timeout => l10n.requestTimeout,
        ApiErrorType.unknown => l10n.somethingWentWrong,
        _ => error.message,
      };
    }
    return fallback ?? l10n.somethingWentWrong;
  }
}
