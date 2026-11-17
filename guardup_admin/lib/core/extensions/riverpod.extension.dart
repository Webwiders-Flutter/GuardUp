import '/core/error/api_exception.dart';
import '../../shared/widgets/feedbacks/widgets/app_snackbar.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

extension AsyncValueHandler<T> on AsyncValue<T> {
  /// Handles asynchronous operation result.
  ///
  /// - Displays an error snackbar with the [ApiException] message or [fallbackErrorMessage] if an error occurred.
  /// - Displays a success snackbar if [showSuccess] is true and [successMessage] is provided.
  /// - Returns `true` on success, `false` on error.
  bool handleResult({
    String? successMessage,
    String fallbackErrorMessage = 'Something went wrong',
    bool showSuccess = true,
  }) {
    if (hasError) {
      final error = this.error;

      if (error is ApiException) {
        AppSnackbar.error(error.message);
      } else {
        AppSnackbar.error(fallbackErrorMessage);
      }

      return false;
    }

    if (showSuccess && successMessage != null && successMessage.isNotEmpty) {
      AppSnackbar.success(successMessage);
    }
    return true;
  }

  /// Displays an error snackbar for listener callbacks (e.g. `ref.listen`).
  ///
  /// Only triggers when [hasError] is true and [isLoading] is false.
  void showErrorSnackbar({
    String fallbackErrorMessage = 'Something went wrong',
  }) {
    if (hasError && !isLoading) {
      final error = this.error;
      if (error is ApiException) {
        AppSnackbar.error(error.message);
      } else {
        AppSnackbar.error(fallbackErrorMessage);
      }
    }
  }

  /// Returns user-friendly error message extracted from the error object.
  String get errorMessage {
    final err = error;
    if (err is ApiException) {
      return err.message;
    }
    return err?.toString() ?? 'Something went wrong';
  }

  /// Whether the operation completed successfully with a value and is not loading.
  bool get isSuccess => !hasError && !isLoading && hasValue;

  /// Executes [callback] only if the operation succeeded with a non-null value.
  void onSuccess(void Function(T data) callback) {
    if (isSuccess && value != null) {
      callback(value as T);
    }
  }
}
