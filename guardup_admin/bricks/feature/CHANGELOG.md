# 0.1.0+2

- Aligned feature scaffolding with the `unit-type` feature architecture:
  - Freezed `sealed class` model with dedicated `Request` model (with `toJson` and `JsonKeys`).
  - `BaseSupabaseRepository` integration.
  - Riverpod `AsyncNotifierProvider` without auto-dispose.
  - Full `AsyncNotifier` controller with pagination cache, reorder, and active toggle.
  - Right-side slide-in `AppSidePanel.show` form with `AppFieldLabel`, `AppTextField`, and `AppRadio`.
  - Admin management screen using `AdminTableBuilder`, `TableColumn`, `AppChip`, and `AppPopup.showDeleteConfirmation`.

# 0.1.0+1

- Initial release of feature brick template for GuardUp Admin.
