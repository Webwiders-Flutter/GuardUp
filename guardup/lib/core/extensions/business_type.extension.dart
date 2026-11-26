import '/features/company/data/enum/business_type.enum.dart';
import '/gen/app_localizations.dart';
import '/core/utils/json_converters/enum.jsonconverter.dart';

/// Formats a stored `companies.company_type` value for display.
extension BusinessTypeValueX on String {
  /// Localized label of a [BusinessType] API value (e.g. `PVT_LTD` ->
  /// "Private Limited (Pvt Ltd)"). Unknown values are shown as stored.
  String businessTypeLabel(AppLocalizations l10n) =>
      BusinessType.values.fromValue(this)?.label(l10n) ?? this;
}
