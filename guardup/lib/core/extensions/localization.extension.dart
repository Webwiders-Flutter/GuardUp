import 'package:flutter/widgets.dart';

import '/gen/app_localizations.dart';

extension LocalizationExtension on BuildContext {
  /// Shorthand for [localizations]
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
