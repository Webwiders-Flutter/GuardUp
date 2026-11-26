/// Who a bodyguard profile belongs to (`public.bodyguards`).
///
/// Not a database enum: derived from the owner columns
/// (`bodyguards_owner_check`: `user_id` or `company_id` is set).
/// Used by `BodyguardFilters.ownership`.
enum BodyguardOwnership {
  /// Self-registered GUARD account working on its own:
  /// `company_id IS NULL` (so `user_id` is set). "Solo" in the customer app.
  solo,

  /// Managed by a company, no login: `user_id IS NULL`.
  companyManaged;

  bool get isSolo => this == BodyguardOwnership.solo;
  bool get isCompanyManaged => this == BodyguardOwnership.companyManaged;
}
