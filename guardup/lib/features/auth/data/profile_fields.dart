import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';

/// Where each profile column is stored since the role profiles were split out
/// of `users` (see documentation/user_profiles.md).
///
/// Screens still send one flat map (e.g. `{name, hourly_rate, address}`);
/// [split] decides which part goes to `users` and which to the role table.
abstract final class ProfileFields {
  /// Columns stored in `bodyguards` for a GUARD account.
  static const Set<String> bodyguardColumns = {
    JsonKeys.hourlyRate,
    JsonKeys.bio,
    JsonKeys.experienceYears,
    JsonKeys.languages,
    JsonKeys.certifications,
  };

  /// Columns stored in `companies` for a COMPANY account.
  static const Set<String> companyColumns = {
    JsonKeys.companyName,
    JsonKeys.businessEmail,
    JsonKeys.companyType,
    JsonKeys.companyPhoneCode,
    JsonKeys.companyPhoneNumber,
    JsonKeys.experienceYears,
  };

  /// Whether [data] has any column that lives outside `users`.
  static bool hasRoleColumns(Map<String, dynamic> data) => data.keys.any(
    (key) => bodyguardColumns.contains(key) || companyColumns.contains(key),
  );

  /// Splits [data] for an account with [role] (`users.role` API value).
  ///
  /// - `account`: columns for `users`.
  /// - `profileTable` / `profile`: the role table and its columns, or `null`
  ///   / empty when the role has no profile table.
  /// - `ignored`: role columns that do not belong to this role (e.g. a
  ///   customer sending `hourly_rate`); they are not written anywhere.
  static ({
    Map<String, dynamic> account,
    String? profileTable,
    Map<String, dynamic> profile,
    List<String> ignored,
  })
  split(Map<String, dynamic> data, String? role) {
    final (table, columns) = switch (role) {
      'GUARD' => (DatabaseTables.bodyguards, bodyguardColumns),
      'COMPANY' => (DatabaseTables.companies, companyColumns),
      _ => (null, const <String>{}),
    };

    final account = <String, dynamic>{};
    final profile = <String, dynamic>{};
    final ignored = <String>[];

    for (final entry in data.entries) {
      final isRoleColumn =
          bodyguardColumns.contains(entry.key) ||
          companyColumns.contains(entry.key);
      if (!isRoleColumn) {
        account[entry.key] = entry.value;
      } else if (columns.contains(entry.key)) {
        profile[entry.key] = entry.value;
      } else {
        ignored.add(entry.key);
      }
    }

    return (
      account: account,
      profileTable: profile.isEmpty ? null : table,
      profile: profile,
      ignored: ignored,
    );
  }
}
