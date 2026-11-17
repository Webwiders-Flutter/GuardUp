# clean-admin.md

> Give this file to any AI agent or developer to safely strip all admin panel code from this project.

---

## What "admin code" means in this project

The admin panel is a **web-only** component layered on top of the main Flutter app.
It lives entirely in the following paths — everything outside them is **safe and must NOT be touched**.

---

## Files & Folders to Delete

### 1. Admin Shell Screen
```
lib/app/screens/admin_shell.dart
```

### 2. Admin Layout Widgets
```
lib/shared/widgets/admin_layout/
├── dashboard_layout.dart
├── models.dart
└── sidebar.dart
```

### 3. Admin Table Widgets
```
lib/shared/widgets/table/
├── admin_table_builder.dart
├── custom_table_text.dart
├── table_common_views.dart
├── table_constants.dart
├── table_desktop_view.dart
├── table_filter_bar.dart
├── table_footer.dart
├── table_mobile_view.dart
├── table_reorderable_view.dart
└── table_top_bar.dart
```

---

## Step-by-step Instructions for the Agent

1. **Delete the files listed above** using the shell commands below.
2. **Search for any imports** of the deleted files across the codebase and remove them.
3. **Search for any usage** of `AdminShell`, `AdminTableBuilder`, `CustomDashboardLayout`, `CustomDashboardSidebar` in route files and remove those references.
4. **Do NOT delete** anything in:
   - `lib/app/routes/`
   - `lib/app/theme/`
   - `lib/core/`
   - `lib/features/`
   - `lib/shared/widgets/` (except the `admin_layout/` and `table/` sub-folders listed above)
   - `lib/gen/`
   - `lib/l10n/`
   - `lib/bootstrap/`
   - `lib/main*.dart`

---

## Shell Commands

Run these from the **project root** (`admin_supplr_transport_hub/`):

```bash
# 1. Remove admin shell
rm -f lib/app/screens/admin_shell.dart

# 2. Remove admin layout widgets
rm -rf lib/shared/widgets/admin_layout/

# 3. Remove admin table widgets
rm -rf lib/shared/widgets/table/

# 4. Verify no admin residue (should print nothing)
find lib/ -name "admin_shell.dart" -o -name "admin_table_builder.dart" -o -path "*/admin_layout/*" -o -path "*/widgets/table/*"
```

---

## Post-deletion Checks

After deleting, the agent should:

1. Run `flutter analyze` and fix any broken imports or missing references.
2. Search for these identifiers and remove any dangling references:
   - `AdminShell`
   - `AdminTableBuilder`
   - `CustomDashboardLayout`
   - `CustomDashboardSidebar`
   - `CustomDashboardMenuItem`
   - `DashboardPage`
   - `TableFilterChip`
   - `GhostButton`
   - `GhostIconButton`
   - `AppBarActions`
3. Remove unused dependencies from `pubspec.yaml` if they were **only** used by admin code:
   - `two_dimensional_scrollables` — check if used elsewhere before removing.

---

## Notes

- The `lib/app/routes/app_routes.dart` file may still contain route constants — those belong to the main app and should **not** be removed.
- The `lib/app/screens/` folder itself can be left in place (it may contain `main_navigation.screen.dart`).
- After cleanup, run `flutter build web --no-tree-shake-icons` to verify the web build is clean.
