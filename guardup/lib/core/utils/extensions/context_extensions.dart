import 'package:flutter/material.dart';
import 'package:guardup/l10n/generated/app_localizations.dart';

extension ContextExtensions on BuildContext {
  // Localization shortcut
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';

  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // Media Query shortcuts
  double get screenHeight => MediaQuery.sizeOf(this).height;
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get aspectRatio => MediaQuery.sizeOf(this).aspectRatio;
  Orientation get orientation => MediaQuery.orientationOf(this);

  // Insets and Padding
  double get topPadding => MediaQuery.paddingOf(this).top;
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;

  // Responsive Breakpoints (Example)
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  // Device Pixel Ratio
  double get pixelRatio => MediaQuery.devicePixelRatioOf(this);

  // Navigation shortcuts
  void popPage<T>([T? result]) => Navigator.of(this).pop(result);
}

extension FailureLocalization on BuildContext {
  String translateFailure(dynamic failure) {
    // Determine the message key
    String key;
    if (failure is String) {
      key = failure;
    } else {
      try {
        key = failure.message;
      } catch (e) {
        return 'An error occurred';
      }
    }

    String? reason;
    if (key.contains('\n')) {
      final parts = key.split('\n');
      key = parts[0];
      reason = parts.sublist(1).join('\n');
    }

    String translated;
    switch (key) {
      case 'errorServer':
        translated = l10n.errorServer;
        break;
      case 'errorUserNotAuthenticated':
        translated = l10n.errorUserNotAuthenticated;
        break;
      case 'errorFailedToLoadData':
        translated = l10n.errorFailedToLoadData;
        break;
      case 'errorFailedToUpdate':
        translated = l10n.errorFailedToUpdate;
        break;
      case 'errorFailedToDelete':
        translated = l10n.errorFailedToDelete;
        break;
      case 'errorFailedToUpload':
        translated = l10n.errorFailedToUpload;
        break;
      case 'errorConnectionTimedOut':
        translated = l10n.errorConnectionTimedOut;
        break;
      case 'errorResourceNotFound':
        translated = l10n.errorResourceNotFound;
        break;
      case 'errorInvalidFileType':
        translated = l10n.errorInvalidFileType;
        break;
      case 'errorRequestCancelled':
        translated = l10n.errorRequestCancelled;
        break;
      case 'errorAlreadyReported':
        translated = l10n.errorAlreadyReported;
        break;
      default:
        // Fallback for non-localized failures
        translated = key;
    }

    if (reason != null && reason.isNotEmpty) {
      return '$translated\n$reason';
    }
    return translated;
  }
}
