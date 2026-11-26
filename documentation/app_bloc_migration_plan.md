# GuardUp Mobile App — Architecture Migration Plan (Admin-grade, Bloc-first)

**Target codebase:** `guardup/` (Flutter mobile app, `flutter_bloc` + `get_it`)
**Reference codebase:** `guardup_admin/` (Flutter admin panel, Riverpod)
**Supersedes:** `documentation/app_architecture_refactoring_plan.md` (its model/AuthState work is already merged; everything still open is folded in here).
**Written:** 2026-11-25

---

## 0. Read this first (rules for the implementing agent)

You are migrating a working production app. **Nothing the user sees or the database stores may change unless this document says so.** The goal is structure, not features.

1. **Work in the phase order of §8.** Each step ends with a gate (§8.0). Do not start a step while the previous gate fails.
2. **One step = one commit.** Commit message format: `refactor(app): <phase.step> <summary>`. Never mix two steps in one commit.
3. **Add first, switch call sites, delete last.** Never delete or rename a public symbol before every call site has moved. Use `@Deprecated('Use X')` as a bridge so `flutter analyze` lists every remaining call site.
4. **Do not change UI.** Widget trees, paddings, colours, texts and animations stay identical. You only move *where data and logic come from*.
5. **Do not change the database.** The only backend change allowed is the one SQL backfill in §7.3, and it ships with its doc update.
6. **Preserve the parity checklists in §9 exactly.** If a behaviour looks like a bug but is not listed in §7 as "fix", keep it and add a `// PARITY:` comment explaining it.
7. **Do not invent fields, tables, columns, RPCs or enum values.** The database schema (`supabase/migrations/`) is the source of truth. If something you need does not exist, stop and leave a `// TODO(migration): <question>` instead of guessing.
8. **When the admin and this document disagree with your instinct, follow the admin pattern** (`guardup_admin/lib/...`), translated to Bloc as described in §4.
9. After every step run: `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test`. Baseline today: **`flutter analyze` → No issues found.** Keep it that way.

---

## 1. Executive summary

The admin panel is consistent because every feature is built from the same five pieces:

| Piece | Admin file (reference) |
|---|---|
| One generic base repository; each table repo only sets table, select, search, sort | `core/repositories/base.repository.dart`, `features/services/data/repositories/services.repository.dart` |
| One error funnel turning every exception into `ApiException` with a user-safe message | `core/utils/callback/async_callback.handler.dart`, `core/error/error_code_parser.dart` |
| Typed models (freezed), typed **filters** models and typed **request** models; no raw string keys | `features/services/data/models/{service,service_filters,service_request}.model.dart` |
| One controller per use case; screens only read state and call methods | `features/*/presentation/controllers/*.controller.dart` |
| Per-feature DI file | `features/*/di/*.providers.dart` |

The app has good shared UI (`shared/widgets/`), a good `ApiState` and `PaginationState`, and one clean module (`features/notifications/`). Everything else mixes data access, business rules and UI inside screens.

**The plan:** keep `flutter_bloc` + `get_it`, port the admin's core pieces, then migrate feature by feature so that:

- Widgets never talk to Supabase, repositories or `sl<>()` (except to create a Bloc).
- Every async user workflow is a **Bloc** with explicit events. **Cubit** is allowed only for the small cases in §4.2.
- Every table has exactly one repository extending `BaseSupabaseRepository`.
- Every payload is a request model; every filter set is a filters model; every key is a `JsonKeys` constant.
- Models mirror the database 1:1, like the admin's models.

---

## 2. Findings

### 2.1 What the admin does right (copy these)

1. **`BaseSupabaseRepository<T>`** — CRUD, pagination with exact count, search, sort. Feature repos are ~15 lines (`services.repository.dart`). Search input is sanitised and quoted (`buildSearchFilter`).
2. **`asyncHandler`** — maps `AuthException`, `PostgrestException`, `StorageException`, `FunctionException`, `SocketException`, `TimeoutException`, `FormatException`, `ArgumentError` to `ApiException(message, type)`. Controllers never build error strings.
3. **Typed request models** (`ServiceRequest.toJson()` trims, nulls empty strings, uses `JsonKeys`).
4. **Typed filters models** with a sentinel `copyWith` so a filter can be cleared to `null` (`service_filters.model.dart`).
5. **Safe parsing helpers** — `SafeEnumConverter` / `SafeEnumParser` (case-insensitive, never throws), `EmbeddedParser.parseObject/parseList` for PostgREST embeds.
6. **Enums own their behaviour** — `apiValue`, `label([l10n])`, `color(context)`, `icon`, `isX` getters (`users/data/enums/user_status.enum.dart`).
7. **Models are 1:1 with tables** — `UserModel`, `BodyguardModel`, `CompanyModel` with embedded relations, no display getters (formatting lives in `core/extensions`).
8. **Repositories own the select strings and FK hints** (`users.repository.dart` `_detailsSelect`, `_normalizeProfiles`).
9. **Optimistic local updates with rollback** in controllers (`_updateLocalRecords`, `_getLocalRecords`).
10. **No fake data, no mock fallbacks, no dead fallbacks.**

### 2.2 What the app already does right (keep these)

- `core/state/api_state.dart` — sealed `ApiState<T>` with `initial/loading/success/failure`, `previousData`. Better suited to Bloc than the admin's freezed version. **Keep.**
- `shared/widgets/pagination/` — `PaginationState` (with `status` + `loadMoreStatus`), `PaginationController`, `AppPagination`. **Keep.**
- `features/notifications/` — Bloc with events/states, filters model, repository on the base class, optimistic updates. **Use as the in-app reference**, after the fixes in §6.9.
- `shared/widgets/*`, `core/extensions/*`, `rules.md` (UI rules). **Keep.**
- `core/repositories/base.repository.dart` exists (copied from admin) — needs the fixes in §5.4.

### 2.3 What is wrong in the app (evidence)

| # | Problem | Evidence |
|---|---|---|
| P1 | **Business logic and Supabase calls inside widgets** | `Supabase.instance.client` used directly in 6 screens/widgets: `body_guard_complete_profile_screen.dart` (5), `body_guard_profile_screen.dart`, `bodyguard_availability.widget.dart` (4), `edit_bio_sheet.dart`, `edit_key_details_sheet.dart`, `edit_services_sheet.dart` (3), `membership_plans_screen.dart`, `my_bank_details_screen.dart` (6), `withdraw_money_sheet.dart` |
| P2 | **Service locator inside widgets** | `sl<...>` appears in 48 presentation files (33× in `body_guard_complete_profile_screen.dart`, 18× in `company_complete_profile_screen.dart`, 16× in `body_guard_upload_documents_screen.dart`) |
| P3 | **Supabase inside blocs** | `auth_bloc.dart` (`_fetchUserServices`, `_fetchUserDocuments`), `services_cubit.dart`, `contact_us_bloc.dart`, `legal_content_bloc.dart` |
| P4 | **Raw string keys** | `.eq('user_id', …)`, `{'bio': …}`, `row['day_of_week']` in ~16 files; `features/payments/data/model/plan.model.dart` uses redundant `@JsonKey(name: 'price_per_month')` (build.yaml already does `field_rename: snake`) |
| P5 | **Cubits duplicating the same pagination code** | `bodyguards_cubit.dart`, `company_bodyguards_cubit.dart`, `companies_cubit.dart` each re-implement refresh / loadMore / `_requestId` / `_message` |
| P6 | **God AuthBloc** | `auth_bloc.dart` (805 lines): session, login, signup, OTP, reset, delete, role-data loading, raw Supabase queries, string-sniffing of error messages (`errStr.contains('confirm')`), sentinel error `'EMAIL_NOT_CONFIRMED'`, mock fallbacks when repositories are `null`, fake `UserModel(id: '', name: '')` emitted as "success" |
| P7 | **Fake / mock / phantom data in production paths** | `fakeData` in 45 files. Phantom getters on `BodyGuardModel`: `reviewCount => 0`, `isVerified`, `totalCompletedMissions => 0`, `currency => 'USD'`, `serviceTypes => const []`, `verificationStatus`, `userDocuments`, `operationalStatus`, and a fabricated `user` sub-model |
| P8 | **Domain layer that adds nothing** | `features/*/domain/repositories/*.dart` abstract classes with a single implementation; `legal_content_repository.dart` is declared but never implemented/used |
| P9 | **Inconsistent models** | `ServiceItemModel`, `UserDocumentModel`, `DocumentTypeModel` hand-written (not freezed); `ServiceItemModel.code` / `DocumentTypeModel.code` read a column that was **dropped** (`20261117000002_alter_services_remove_code…sql`, `…000005…`); `BankAccount.fromSupabase` duplicates `fromJson` |
| P10 | **Enum boilerplate + unsafe defaults** | 23 enums each hand-write `fromApiValue` / `tryFromApiValue`. **`UserStatus.fromApiValue(null)` returns `active`** (unsafe: unknown status = full access) |
| P11 | **Enum/DB mismatch** | `WeekDay` uses `@JsonValue('MONDAY')`, but the DB stores lowercase (`'monday'`, see repository writes `day.name.toLowerCase()` and admin `week_day.enum.dart`) |
| P12 | **Dead fallbacks** | `set_user_services` RPC fallback to delete+insert (RPC exists since `20261117000004`), availability fallback to `users.metadata['availability']` and double-write of that metadata, `_fetchAvailabilities` fallback in `BodyguardRepository.getDetails` |
| P13 | **DI does work** | `injection_container.dart` subscribes to `AuthBloc.stream` and kicks off `loadServices()`; `LanguageCubit`/`ConnectivityCubit` are `registerFactory` but used as app-wide singletons; `LanguageCubit` calls `sl<UserDeviceCubit>()` internally |
| P14 | **Router accepts untyped `Map` extras** | `app_router.dart` `_parseBodyGuard`, `_parseCompany`, `extra['email']`, `extra['onTap'] as VoidCallback?` |
| P15 | **Errors shown raw / not localised** | `ApiState.failure(e.toString())`, `'Failed to update availability: $e'`; 58 `AppSnackbar.x('literal')` calls |
| P16 | **Search filter not escaped** | app `BaseSupabaseRepository.getPaginated` builds `'$field.ilike.%$q%'` unquoted — a comma or `)` in the search box breaks the PostgREST `or()` |
| P17 | **Hidden `Supabase.instance.client` defaults** | repositories take `[SupabaseClient? client]` and fall back to the global; untestable |
| P18 | **Unused dependencies** | never imported: `dartz`, `flutter_background_service`, `wakelock_plus`, `responsive_sizer`, `upgrader`, `readmore`, `share_plus`, `flutter_dotted` |
| P19 | **No tests** | only `test/features/auth/data/profile_fields_test.dart` |
| P20 | **Uncommitted WIP** | 20 modified files + untracked `lib/features/body_guard/bloc/bodyguards/` at the time of writing |

---

## 3. Target architecture

### 3.1 Layers and dependency direction

```
 Widget (Screen / View / Widget)
   │  context.read/watch/select, BlocBuilder/Listener/Selector
   ▼
 Bloc (workflows)  /  Cubit (small app-wide values, §4.2)
   │  calls repositories inside asyncHandler(); never touches Supabase
   ▼
 Repository (one per table; extends BaseSupabaseRepository<T>)
   │  owns select strings, filters, RPC names, JsonKeys
   ▼
 SupabaseClient (injected through get_it; never Supabase.instance in features)
```

Allowed imports:

| Layer | May import | Must not import |
|---|---|---|
| `data/models`, `data/enums` | `core/constants`, `core/utils/json_converters`, other models | blocs, widgets, `sl` |
| `data/repositories` | models, `core/*`, `supabase_flutter` | blocs, widgets, `sl`, `Supabase.instance` |
| `bloc/` | repositories, models, `core/*`, other **injected** blocs/cubits (constructor) | widgets, `sl`, `Supabase`, `BuildContext` |
| `presentation/` | blocs, models, enums, extensions, shared widgets | repositories, `Supabase`, `sl` (except in a `BlocProvider.create`) |

### 3.2 Folder layout (per feature)

```
lib/features/<feature>/
  <feature>.dart                    # barrel (models, enums, blocs, screens, widgets)
  di/<feature>.di.dart              # registerXDependencies(GetIt sl)
  data/
    enums/<name>.enum.dart          # plural folder name: enums (not enum)
    models/<name>.model.dart        # plural: models (not model)
    models/<name>_filters.model.dart
    models/<name>_request.model.dart
    repositories/<name>.repository.dart
    fixtures/<name>.fixtures.dart   # ONLY skeleton placeholders / prototype data (see §5.9)
  bloc/<use_case>/
    <use_case>_bloc.dart
    <use_case>_event.dart
    <use_case>_state.dart
  presentation/
    screens/
    widgets/
```

Folder renames (`data/enum` → `data/enums`, `data/model` → `data/models`) and file renames are **Phase 9 only** (mechanical, separate commits) so they never mix with logic changes.

### 3.3 Feature map after migration

| Feature | Repositories | Blocs / Cubits |
|---|---|---|
| `auth` | `AuthRepository` (GoTrue), `UserRepository` (`users`) | `AuthBloc` (session, app-wide), `AuthFormBloc` (login/signup/OTP/reset, screen-scoped), `AccountBloc` (edit profile, change password, delete account) |
| `services` *(new, moved from body_guard)* | `ServicesRepository` (`services`, `set_user_services`, `set_bodyguard_services`) | `ServicesCatalogCubit` (app-wide cached list) |
| `documents` *(new, replaces `core/services/document_submission`)* | `DocumentTypesRepository` (`document_types`), `UserDocumentsRepository` (`user_documents` + storage) | `DocumentsBloc` |
| `body_guard` | `BodyguardRepository` (`bodyguards`), `AvailabilityRepository` (`user_availabilities`) | `BodyguardsBloc` (customer list), `CompanyBodyguardsBloc` (company roster), `BodyguardDetailsBloc`, `GuardProfileBloc` (complete/edit profile, both self guard and company-managed), `AvailabilityBloc` |
| `company` | `CompanyRepository` (`companies`) | `CompaniesBloc` (list), `CompanyProfileBloc` (complete/edit) |
| `payments` | `BankAccountRepository` (`user_bank_accounts`), `MembershipPlanRepository` (`membership_plans`) | `BankAccountsBloc`, `MembershipPlansBloc`, `RegistrationFeeBloc` |
| `legal` | `LegalContentRepository`, `ContactUsRepository` | `LegalContentBloc`, `ContactUsBloc` |
| `notifications` | `NotificationRepository`, `UserDeviceRepository` | `NotificationsBloc`, `UnreadNotificationCountCubit`, `UserDeviceCubit` |
| `settings` *(moved from `core/config/admin_settings`)* | `AdminSettingsRepository` | `AdminSettingsCubit`, `AppGateCubit` (move to `app/gate`, unchanged location is fine) |
| `booking`, `chat`, `rating_and_reviews`, wallet part of `payments` | **none — no tables exist yet** | none; see §5.9 |
| `customer` | none (composes other features) | uses `BodyguardsBloc`, `CompaniesBloc`, `ServicesCatalogCubit` |

---

## 4. Standards (the rules every migrated file must follow)

### 4.1 Bloc conventions

- **Events:** `sealed class XEvent extends Equatable`, one `final class` per intent, past-tense or `Requested` naming: `GuardProfileStarted`, `GuardProfileSubmitted`, `GuardProfileAvatarPicked`. Private internal events start with `_`.
- **States:** one immutable `final class XState extends Equatable` with `copyWith`. Use `ApiState<T>` fields for async parts (`loadStatus`, `submitStatus`). Do **not** create a new state class per status.
- **Clearing nullable fields in `copyWith`:** use the sentinel pattern from `guardup_admin/lib/features/services/data/models/service_filters.model.dart` (`Object? x = _sentinel`). No `bool clearX` flags (the current cubits use them — remove).
- **Concurrency** (add `bloc_concurrency`):
  - loads / refreshes / searches → `transformer: restartable()`
  - "load next page", "submit", "save", "delete" → `transformer: droppable()`
  - toggles that must all apply in order → `sequential()`
- **Streams:** subscribe with `await emit.forEach(...)` / `emit.onEach(...)` inside a handler registered with `restartable()`. **No manual `StreamSubscription` fields** in blocs (except `UnreadNotificationCountCubit`'s push listener, which is fine as is).
- **Errors:** wrap every repository call:
  ```dart
  try {
    final data = await asyncHandler(() => _repository.getDetails(id));
    emit(state.copyWith(loadStatus: ApiState.success(data)));
  } on ApiException catch (e) {
    emit(state.copyWith(loadStatus: ApiState.failure(e.message, error: e)));
  }
  ```
  `asyncHandler` rethrows everything as `ApiException`, so `on ApiException` is complete. Never `catch (e)` + `e.toString()`. Never an empty `catch (_) {}` (exception: documented best-effort cleanup like deleting an orphan file, which must log with `AppLogger.w`).
- **One-shot side effects** (snackbar, navigation, closing a sheet): model them as an `ApiState<…>` status field that goes `initial → loading → success|failure` on every attempt, and react with `BlocListener(listenWhen: (p, c) => p.submitStatus != c.submitStatus)`. Because each attempt starts from `loading`, repeated identical failures still fire.
- **Cross-bloc communication:** inject the other bloc/cubit through the constructor (as `NotificationsBloc` does with `UnreadNotificationCountCubit`), or react in the widget tree with `BlocListener`. Never `sl<OtherBloc>()` inside a bloc.
- **No `isClosed` checks needed** when using `emit` inside handlers (bloc ignores emits after close); remove `_requestId` once `restartable()` + the generation guard in §5.6 are in place.

### 4.2 Bloc vs Cubit — decision rule

Use **Bloc** for anything with user intents, multiple async steps, forms, pagination, optimistic updates, or realtime streams.

Use **Cubit** only when *all* are true: a single value or tiny state, ≤ 2 trivial methods, no form, no pagination. The allow-list (any other Cubit is a review failure):

| Cubit | Why it may stay a Cubit |
|---|---|
| `LanguageCubit` | one value, persisted |
| `ConnectivityCubit` | one value from a stream |
| `UnreadNotificationCountCubit` | one `int` |
| `UserDeviceCubit` | fire-and-forget device sync |
| `AdminSettingsCubit` | one settings value + realtime |
| `AppGateCubit` | derived from settings |
| `ServicesCatalogCubit` | cached read-only list (`ApiState<List<ServiceModel>>`) |

Everything else currently a Cubit (`BodyguardsCubit`, `CompanyBodyguardsCubit`, `CompaniesCubit`, `ServicesCubit` in its current form) becomes a Bloc or is renamed/reshaped as above.

### 4.3 Dependency injection (`get_it`)

- `lib/core/di/injection_container.dart` only: registers `SupabaseClient` (`sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client)`), `GoTrueClient`, `LocalStorage`, `FileStorageService`, then calls each feature's `registerXDependencies(sl)` in dependency order.
- Each feature has `features/<f>/di/<f>.di.dart` (mirror of admin's `di/*.providers.dart`).
- **Repositories & services:** `registerLazySingleton`, constructor-injected (`BodyguardRepository(sl<SupabaseClient>())`). Remove every `[SupabaseClient? client]` optional default.
- **App-wide blocs/cubits** (`AuthBloc`, `LanguageCubit`, `ConnectivityCubit`, `UnreadNotificationCountCubit`, `UserDeviceCubit`, `AdminSettingsCubit`, `AppGateCubit`, `ServicesCatalogCubit`): `registerLazySingleton`, provided once in `app/app.dart` with `BlocProvider.value`. (Today `LanguageCubit` and `ConnectivityCubit` are `registerFactory` — change to lazy singletons.)
- **Screen blocs:** `registerFactory`, created in the screen with `BlocProvider(create: (_) => sl<XBloc>()..add(const XStarted()))`. Factories that need runtime args use `registerFactoryParam` (e.g. `sl<GuardProfileBloc>(param1: owner)`).
- **DI must not run logic.** Move the `sl<AuthBloc>().stream.listen(...)` block and `sl<ServicesCubit>().loadServices()` out of `initDependencies()`:
  - session side effects → `app/session/session_listener.dart`, a `BlocListener<AuthBloc, AuthState>` placed in `App.builder`, `listenWhen: (p, c) => p.user?.id != c.user?.id || p.sessionStatus != c.sessionStatus`, calling `UnreadNotificationCountCubit.loadCount/clearAll` and `UserDeviceCubit.syncCurrentDevice/clearCurrentDevice`.
  - FCM token refresh listener → `UserDeviceCubit` constructor receives `String? Function() currentUserId` (inject `() => sl<AuthRepository>().currentUserId` from DI — a closure in DI is fine, a subscription is not).
  - services preload → `ServicesCatalogCubit` is created with `..load()` in `App`'s `BlocProvider`.

### 4.4 Widgets

- Screen file shape:
  ```dart
  class GuardProfileScreen extends StatelessWidget {
    static const route = '/bodyguard-profile';
    const GuardProfileScreen({super.key, this.args});
    final GuardProfileArgs? args;

    @override
    Widget build(BuildContext context) => BlocProvider(
      create: (_) => sl<GuardProfileBloc>(param1: args?.owner)..add(const GuardProfileStarted()),
      child: const _GuardProfileView(),
    );
  }

  class _GuardProfileView extends StatefulWidget { ... } // only for TextEditingControllers / FormKey
  ```
- `StatefulWidget` only to own controllers (`TextEditingController`, `FormKey`, `ScrollController`, `PaginationController`, `SelectionController`). Data loaded from the server **never** lives in a `ValueNotifier`/`setState`; it lives in the bloc state.
- `ValueNotifier` stays allowed for pure UI state (pressed, expanded, local selection), per `rules.md` §1.
- Read state with `context.select` / `BlocSelector` for small parts, `BlocBuilder(buildWhen:)` for sections; side effects only in `BlocListener`.
- Pre-filling text controllers from loaded data: do it once in a `BlocListener` with `listenWhen: (p, c) => p.loadStatus.isLoading && c.loadStatus.isSuccess`.
- `AuthBloc` is read via `context.read<AuthBloc>()` / `context.select((AuthBloc b) => b.state.user?.name)`. Never `sl<AuthBloc>()` in a widget.

### 4.5 Models and enums

- All models `@freezed` + `json_serializable`; `build.yaml` already sets `field_rename: snake`, so **no `@JsonKey(name:)` unless the name differs** (e.g. aliases like `user_services`).
- Mirror the admin model of the same table field-for-field (§6 lists each). No display getters; formatting goes into `core/extensions` (see memory rule: no model getters).
- Embedded relations parse with `EmbeddedParser` (port, §5.3) via `@JsonKey(fromJson: ...)`.
- Enums follow `guardup_admin/lib/features/users/data/enums/user_status.enum.dart`:
  `@JsonValue('X') value('X')`, `final String apiValue`, `String label([AppLocalizations? l10n])`, optional `color(BuildContext)`, `icon`, and `isX` getters.
- Parse enums with `SafeEnumConverter` / `values.fromValue(...)` (port, §5.3). Delete the per-enum `fromApiValue`/`tryFromApiValue` methods **after** call sites move. **Every call site must state its default explicitly**; the default for `UserStatus` is `incomplete`, never `active` (P10).
- Persist `apiValue`, never labels.

### 4.6 Repositories

- `final class XRepository extends BaseSupabaseRepository<XModel>`, constructor takes `SupabaseClient` (required).
- Select strings are `static const` in the repository. Every embed with more than one FK path uses an FK hint (`companies!companies_user_id_fkey`), as in admin `users.repository.dart`.
- Filters arrive as an `XFilters` object; payloads arrive as an `XRequest` object (`toJson()` uses `JsonKeys`).
- Repositories never read `currentUser` from a global. If the signed-in user id is needed, the bloc passes it (it gets it from `AuthRepository`, injected).
- Repositories do not catch-and-swallow. They throw; the bloc's `asyncHandler` turns it into `ApiException`.

### 4.7 Errors and localisation

- Port `asyncHandler` (§5.1). Its generic messages (network, timeout, unknown, invalid format) use `AppLocalizationsEn()`; the UI localises them with a context extension:
  ```dart
  // core/extensions/api_error.extension.dart
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
  ```
  Check the three l10n keys exist in `app_en.arb` / `app_ar.arb`; add them if missing.
- Every user-facing literal moved during a step goes to `app_en.arb` **and** `app_ar.arb` (Phase 7 sweeps the rest).

### 4.8 Routing

- Route arguments are typed. Replace `Map` extras with small immutable arg classes (`rules.md` §8 warning: use a `const` class, not a record, when callers pass subsets):
  `GuardProfileArgs`, `GuardDetailsArgs { String bodyguardId; BodyGuardModel? preview; }`, `CompanyDetailsArgs`, `EmailVerificationArgs { String email; UserRole? role; OtpType otpType; }`, `PaymentSuccessArgs`.
- Detail screens accept an **id** plus an optional preloaded model; the bloc loads by id when the model is missing (deep links and process death then work).
- `extra['onTap'] as VoidCallback?` must go: return a result with `context.pop(result)` or navigate by route.
- `AuthRefreshListenable` stays; the redirect logic is extracted into a pure function (Phase 0) so it can be tested.

---

## 5. Core building blocks to add (Phase 1)

All additive. No call sites change in Phase 1 except where stated.

### 5.1 `core/utils/callback/async_callback.handler.dart`
Copy from `guardup_admin/lib/core/utils/callback/async_callback.handler.dart`. Diff the app's `core/error/error_code_parser.dart` with the admin's (they differ) and take the admin version plus any app-only codes. Add `stream_callback.handler.dart` only if a repository needs it.

### 5.2 `core/extensions/api_error.extension.dart`
As in §4.7.

### 5.3 `core/utils/json_converters/`
Copy all six files from admin (`boolean`, `datetime`, `double`, `embedded`, `enum`, `int` + barrel). Use `double`/`int` converters for `NUMERIC` columns (Supabase can return `hourly_rate` as `int` or `String`).

### 5.4 `core/repositories/base.repository.dart` fixes
1. Port admin's `buildSearchFilter` (sanitise `"`, quote the pattern: `'$field.ilike."%$q%"'`) and use it in `getPaginated` (fixes P16).
2. Keep the app's `selectColumnsOverride` parameter (used by bodyguards availability join).
3. Keep the base `getDetails` using `selectColumns` (today it uses `select()`; change to `select(selectColumns)` and `.maybeSingle()` — check every subclass that overrides `getDetails` still behaves the same).

### 5.5 `shared/models/record_owner.model.dart`
Removes the `user_id` vs `bodyguard_id` branching duplicated in availability, documents, services and profile code (schema: child rows have exactly one of `user_id` / `bodyguard_id`).
```dart
sealed class RecordOwner extends Equatable {
  const RecordOwner(this.id);
  final String id;
  String get column;
  @override
  List<Object?> get props => [runtimeType, id];
}

/// A login account (GUARD or COMPANY user) — rows keyed by `user_id`.
final class AccountOwner extends RecordOwner {
  const AccountOwner(super.id);
  @override
  String get column => JsonKeys.userId;
}

/// A company-managed bodyguard (no login) — rows keyed by `bodyguard_id`.
final class ManagedBodyguardOwner extends RecordOwner {
  const ManagedBodyguardOwner(super.id);
  @override
  String get column => JsonKeys.bodyguardId;
}
```

### 5.6 Shared pagination Bloc — `shared/bloc/pagination/`
Removes P5. **Read the notes before writing it — generic events are a crash trap.**

> **Trap:** `on<SomeEvent<F>>` does not match `add(SomeEvent())` (runtime type `SomeEvent<dynamic>`), and bloc throws *"add(…) was called without a registered event handler"*. Therefore **base events are not generic**. Filters live in state; feature blocs change them through their own typed event.

```dart
// pagination_event.dart
abstract class PaginationEvent extends Equatable { // NOT sealed: features extend it
  const PaginationEvent();
  @override
  List<Object?> get props => const [];
}

/// (Re)loads page 1 with the current filters and search.
final class PaginationLoadRequested extends PaginationEvent {
  const PaginationLoadRequested();
}

final class PaginationSearchChanged extends PaginationEvent {
  const PaginationSearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

final class PaginationNextPageRequested extends PaginationEvent {
  const PaginationNextPageRequested();
}
```

```dart
// paginated_state.dart
class PaginatedState<T, F> extends Equatable {
  const PaginatedState({
    required this.filters,
    required this.pagination,
    this.search = '',
    this.actionStatus = const ApiState.initial(),
  });

  /// Non-const on purpose: a const default cannot carry T and would infer
  /// PaginationState<Never>.
  factory PaginatedState.initial(F filters, {int pageSize = AppConstants.paginationLimit}) =>
      PaginatedState<T, F>(filters: filters, pagination: PaginationState<T>(pageSize: pageSize));

  final F filters;
  final String search;
  final PaginationState<T> pagination;

  /// One-shot actions on items (delete, toggle). See §4.1 side effects.
  final ApiState<void> actionStatus;

  PaginatedState<T, F> copyWith({F? filters, String? search, PaginationState<T>? pagination, ApiState<void>? actionStatus}) => ...;

  @override
  List<Object?> get props => [filters, search, pagination, actionStatus];
}
```

```dart
// paginated_bloc.dart
abstract class PaginatedBloc<T, F> extends Bloc<PaginationEvent, PaginatedState<T, F>> {
  PaginatedBloc({required F initialFilters, int pageSize = AppConstants.paginationLimit})
    : super(PaginatedState<T, F>.initial(initialFilters, pageSize: pageSize)) {
    on<PaginationLoadRequested>((_, emit) => _load(emit), transformer: restartable());
    on<PaginationSearchChanged>(_onSearchChanged, transformer: restartable());
    on<PaginationNextPageRequested>(_onNextPage, transformer: droppable());
  }

  /// Bumped on every page-1 load; stale responses (from any handler) are dropped.
  int _generation = 0;

  @protected
  Future<({List<T> data, int total})> fetchPage({
    required int page, required int pageSize, required F filters, required String search,
  });

  /// For subclasses: call from a typed "filters changed" handler.
  @protected
  Future<void> applyFilters(F filters, Emitter<PaginatedState<T, F>> emit) {
    emit(state.copyWith(filters: filters));
    return _load(emit);
  }

  Future<void> _onSearchChanged(PaginationSearchChanged e, Emitter<PaginatedState<T, F>> emit) {
    emit(state.copyWith(search: e.query.trim()));
    return _load(emit);
  }

  Future<void> _load(Emitter<PaginatedState<T, F>> emit) async {
    final generation = ++_generation;
    final pageSize = state.pagination.pageSize;
    emit(state.copyWith(pagination: state.pagination.copyWith(
      status: const ApiState.loading(), loadMoreStatus: const ApiState.initial())));
    try {
      final result = await asyncHandler(() => fetchPage(
        page: 1, pageSize: pageSize, filters: state.filters, search: state.search));
      if (generation != _generation) return;
      emit(state.copyWith(pagination: PaginationState<T>(
        items: result.data, total: result.total, page: 1, pageSize: pageSize,
        status: const ApiState.success(null))));
    } on ApiException catch (e) {
      if (generation != _generation) return;
      emit(state.copyWith(pagination: state.pagination.copyWith(
        status: ApiState.failure(e.message, error: e))));
    }
  }

  Future<void> _onNextPage(PaginationNextPageRequested e, Emitter<PaginatedState<T, F>> emit) async {
    final current = state.pagination;
    if (current.isLoading || current.isLoadingMore || current.isLastPage) return;
    final generation = _generation;
    final nextPage = current.page + 1;
    emit(state.copyWith(pagination: current.copyWith(loadMoreStatus: const ApiState.loading())));
    try {
      final result = await asyncHandler(() => fetchPage(
        page: nextPage, pageSize: current.pageSize, filters: state.filters, search: state.search));
      if (generation != _generation) return;
      emit(state.copyWith(pagination: state.pagination.copyWith(
        items: [...state.pagination.items, ...result.data],
        total: result.total, page: nextPage, loadMoreStatus: const ApiState.success(null))));
    } on ApiException catch (e) {
      if (generation != _generation) return;
      emit(state.copyWith(pagination: state.pagination.copyWith(
        loadMoreStatus: ApiState.failure(e.message, error: e))));
    }
  }

  /// Helpers for optimistic item updates (mirror admin _updateLocalRecords).
  @protected
  PaginationState<T> replaceWhere(bool Function(T) test, T Function(T) update) => ...;
  @protected
  PaginationState<T> removeWhere(bool Function(T) test) => ...; // also decrements total, min 0
}
```

Wiring to `AppPagination`: pass `state.pagination` and a `PaginationController` whose `onLoadMore` adds `PaginationNextPageRequested` and `onRefresh` adds `PaginationLoadRequested` (the same way `notifications_screen.dart` does it today). Search fields keep their existing `Timer` debounce in the widget and add `PaginationSearchChanged`.

### 5.7 Packages
- Add: `bloc_concurrency`, dev: `bloc_test`, `mocktail`.
- Remove (Phase 9, one at a time, build Android **and** iOS after each): `dartz`, `flutter_background_service`, `wakelock_plus`, `responsive_sizer`, `upgrader`, `readmore`, `share_plus`, `flutter_dotted`. Before removing, grep `android/` and `ios/` for native config left by the package (e.g. a background-service `<service>` entry in `AndroidManifest.xml`) and remove it in the same commit.

### 5.8 Lints (`analysis_options.yaml`)
Add and fix all resulting warnings in the same step: `cancel_subscriptions`, `close_sinks`, `unawaited_futures`, `avoid_empty_else`, `prefer_final_fields`, `avoid_print`, `use_build_context_synchronously` (already in flutter_lints; keep at 0).

### 5.9 Fake data policy
- `fakeData` used **only as Skeletonizer placeholders** (`BodyGuardListSkeleton`, `LegalContentModel.staticContent` while loading) → move to `features/<f>/data/fixtures/<f>.fixtures.dart`, rename to `xPlaceholders`, and only reference them from loading states.
- Prototype features with **no database table** (`booking`, `chat`, `rating_and_reviews`, wallet/transactions in `payments`): do **not** build repositories or blocs. Move their `fakeData` to `data/fixtures/`, keep screens working, and add one line at the top of each feature barrel: `// PROTOTYPE: UI only. No backend table yet; data comes from data/fixtures.`
- Remove every *mock fallback* (`if (authRepo == null) { …mock… }`, "Development mock fallback", `UserModel(id: 'mock')`).
- Remove phantom getters (P7); where a screen shows them (e.g. review count, missions), show the placeholder fixture value via the prototype feature or hide nothing — **ask** with `// TODO(migration):` if removing would change visible UI.

---

## 6. Feature specifications

For each feature: what to build, what it replaces, what to delete. Line numbers are as of commit `9306021` + WIP.

### 6.1 `services` (new feature) — do first, it is small and everything uses it
- **Model:** `features/services/data/models/service.model.dart` → `ServiceModel` (freezed) mirroring admin `ServiceModel` fields: `id, name, description, iconName, iconUrl, isActive, displayOrder, createdAt, updatedAt`. **No `code`** (column dropped). Replaces `body_guard/data/model/service_item.model.dart` (`ServiceItemModel`).
- **Icon mapping:** `ServiceItemModel.icon` / `guardService` move to an extension `ServiceModelX.icon` in `core/extensions/service.extension.dart`, matching on `iconName` first, then name (keep the current mapping table from `GuardService`).
- **Embedded parsing:** one shared top-level helper `List<ServiceModel>? servicesFromUserServices(dynamic json)` (rows of `user_services(id, service:services(...))`), used by `UserModel` and `BodyGuardModel` (replaces the three copies of `_servicesFromJson`).
- **Repository:** `ServicesRepository extends BaseSupabaseRepository<ServiceModel>` (table `services`, sort `display_order`), plus:
  - `Future<List<ServiceModel>> getActive()`
  - `Future<List<String>> getAssignedIds(RecordOwner owner)` (select `service_id` from `user_services` where `owner.column = owner.id`)
  - `Future<void> assign(RecordOwner owner, List<String> serviceIds)` → RPC `set_user_services` (`p_user_id`, `p_service_ids`) for `AccountOwner`, `set_bodyguard_services` (`p_bodyguard_id`, `p_service_ids`) for `ManagedBodyguardOwner`. **No delete+insert fallback** (P12).
- **Cubit:** `ServicesCatalogCubit extends Cubit<ApiState<List<ServiceModel>>>` with `load({bool force = false})`. Replaces `ServicesCubit` (which returns lists from methods and holds `_isLoading` outside state). Callers that did `await sl<ServicesCubit>().loadServices()` instead read `context.read<ServicesCatalogCubit>().state.dataOrNull` or wait via `BlocBuilder`.
- **Delete after migration:** `body_guard/bloc/services/services_cubit.dart`, `service_item.model.dart`, `guard_service.enum.dart` (if only used for icons → move mapping into the extension).

### 6.2 `documents` (new feature)
Replaces `core/services/document_submission/document_submission_service.dart` (a "service" that is really two repositories + upload logic + `sl` calls).
- **Models:** `DocumentTypeModel` (freezed; fields as admin `document_type.model.dart`: `id, name, description, targetRole, isRequired, isActive, displayOrder` — **no `code`**), `UserDocumentModel` (freezed; as admin `user_document.model.dart`, plus `bodyguardId`, with embedded `documentType`). `DocumentStatus` enum → admin pattern.
- **Repositories:**
  - `DocumentTypesRepository` (`document_types`): `getActiveFor(UserRole role)` — filter `target_role = role.apiValue` (GUARD/COMPANY), `is_active = true`, order `display_order`.
  - `UserDocumentsRepository` (`user_documents`): `getFor(RecordOwner owner)`, `upload({required String storageUserId, required RecordOwner owner, required DocumentTypeModel type, required XFile file})` → uploads to `StorageBuckets.documents` at **exactly the current path format** (`<userId>/<docTypeId lowercased>_<millis>.<ext>`, or `<companyUserId>/bodyguards/<bodyguardId>/...` for managed bodyguards — storage policies depend on the first folder), then upsert on (`owner.column`, `document_type_id`).
- **Bloc:** `DocumentsBloc` (factory param: `RecordOwner owner`, `UserRole role`).
  - Events: `DocumentsStarted`, `DocumentPicked(typeId, XFile)`, `DocumentRemoved(typeId)`, `DocumentsSubmitted`.
  - State: `loadStatus: ApiState<void>`, `types: List<DocumentTypeModel>`, `uploaded: Map<String, UserDocumentModel>` (by type id), `picked: Map<String, XFile>`, `submitStatus: ApiState<void>`; derived `canSubmit` (every required type has uploaded-and-not-rejected or picked).
  - `DocumentsSubmitted` for an **account** owner: upload picked files, then submit the application exactly as `submitApplicationForReview` does today (read that method and keep the same status transition and the company-logo sync). For a **managed bodyguard**: upload, then `BodyguardRepository.submitForReview(id)`.
  - After success, add `AuthProfileRefreshRequested` to the injected `AuthBloc` (account owner only).
- **Screens:** `body_guard_upload_documents_screen.dart`, `company_upload_documents_screen.dart`, `company_documents_screen.dart`, `bodyguard_documents.widget.dart`, `company_guard_documents_tab.widget.dart` use this bloc. The two upload screens are ~90 % identical; keep both files (UI unchanged) but both consume `DocumentsBloc`.
- **Delete after migration:** `core/services/document_submission/`, `guard_doc_type.enum.dart`, `company_doc_type.enum.dart` (only if no screen uses them after the move; they map the dropped `code` column).

### 6.3 `body_guard`
- **Model `BodyGuardModel`** — align with admin `BodyguardModel`:
  - Keep: `id, userId, companyId, name, profileImageUrl, hourlyRate, rating, experienceYears, bio, languages, certifications, qualifications, serviceArea?, address, latitude, longitude, isActive, status, rejectionReason, createdAt, updatedAt, company, services, documents, availabilities`.
  - Verify each column exists in migrations (`qualifications` added in `20261125000027`; check `service_area` — admin model does not have it; keep it only if the column exists).
  - Rename `userAvailabilities` → `availabilities` **together with** the select alias in `BodyguardRepository` (`availabilities:user_availabilities!user_availabilities_bodyguard_id_fkey(...)`).
  - Remove the fabricated `user` sub-model and the custom `fromJson` that fills it. Callers of `bodyguard.user.name` / `.profileImageUrl` use `bodyguard.name` / `bodyguard.profileImageUrl` (self-registered guards have them copied from the account per `documentation/user_profiles.md`).
  - Remove phantom getters (`reviewCount`, `isVerified`, `totalCompletedMissions`, `currency`, `serviceTypes`, `verificationStatus`, `userDocuments`, `operationalStatus`). Display helpers (`displayName`, `displayAvatar`, `location`, `availabilityStatus`) move to `core/extensions/bodyguard.extension.dart`. Do it with `@Deprecated` first, fix call sites, then delete.
  - `fakeData` / `defaultUserAvailabilities` → `data/fixtures/bodyguard.fixtures.dart` (placeholders only).
- **Model `UserAvailabilityModel`** → admin fields (`id, userId, bodyguardId, dayOfWeek, isAvailable, fromTime, toTime, createdAt, updatedAt`). `fromTime`/`toTime` stay **strings in the existing `'09:00 AM'` format** (admin and DB rows use it).
- **Enum `WeekDay`** → `@JsonValue('monday') monday('monday')` … (lowercase, P11) with `SafeEnumConverter` so legacy uppercase also parses. Keep `shortLabel`/`weekdayNumber` as getters/extension; `label([l10n])`. `WeekDay.fromDateTime` stays.
- **Enum `BodyGuardStatus`** — check usages; if only used by prototype UI, move to fixtures/prototype; it is not a DB enum.
- **Filters:** `BodyguardFilters { List<UserStatus>? statuses; BodyguardOwnership? ownership; String? companyId; BodyguardAvailabilityStatus? availability; double? minHourlyRate, maxHourlyRate, minRating; List<String>? serviceIds; }` (sentinel `copyWith`; `customerDefault` = ACTIVE solo guards). Services/availability go through the `listing_services` / `listing_availabilities` computed relationships so solo guards are covered. No gender (column dropped). Details: `documentation/user_profiles.md` → Listings and filters.
- **Request:** `BodyguardProfileRequest { name, hourlyRate, bio, experienceYears?, languages?, certifications?, qualifications?, address?, latitude?, longitude?, profileImageUrl? }.toJson()` (trim, empty → null, `JsonKeys`). Used for both self guard (`bodyguards` row by `user_id`) and managed bodyguard (by `id`).
- **`BodyguardRepository`** (keep the WIP version's structure):
  - `getPaginated(..., BodyguardFilters filters)` — keep the UUID guard and the `!inner` availability join exactly.
  - `getDetails(id)` — remove the `_fetchAvailabilities` fallback (P12) after confirming the embed returns rows (it does since `availabilities` FK exists).
  - `getMyCompanyId(String companyUserId)` — takes the id; no `client.auth.currentUser` inside.
  - `saveManaged({String? id, required String companyId, required BodyguardProfileRequest request})`.
  - `upsertForAccount(String userId, BodyguardProfileRequest request)` — upsert on `user_id` (today done by `UserRepository.updateProfileFields` + `ProfileFields.split`).
  - `submitForReview(id)`, `delete(id)` unchanged.
  - `initDefaultAvailability` moves to `AvailabilityRepository.seedDefaults(owner)`; use `WeekDay` + `JsonKeys`, same defaults (Mon–Fri available, `09:00 AM`–`05:00 PM`).
- **`AvailabilityRepository`** (`user_availabilities`): `getFor(RecordOwner)`, `save(RecordOwner, List<AvailabilityRequest>)` → upsert `onConflict: '${owner.column},${JsonKeys.dayOfWeek}'` (unique constraints exist for both: `unique_user_day_availability`, `unique_bodyguard_day_availability`), `seedDefaults(RecordOwner)`.
- **Blocs:**
  - `BodyguardsBloc extends PaginatedBloc<BodyGuardModel, BodyguardFilters>` — customer browse/search. Extra event `BodyguardsFiltersChanged(BodyguardFilters)` → `applyFilters`. Replaces `BodyguardsCubit` (the untracked WIP file).
  - `CompanyBodyguardsBloc extends PaginatedBloc<…>` — needs `companyUserId` (factory param) → resolves company id once in `fetchPage` (cache it). Keep the special rule: filter `pendingApproval` means `[pendingApproval, incomplete]`. Extra events: `CompanyBodyguardsStatusChanged(UserStatus?)`, `CompanyBodyguardDeleted(BodyGuardModel)` (optimistic remove + rollback, `actionStatus`). Replaces `CompanyBodyguardsCubit`.
  - `BodyguardDetailsBloc` (param `bodyguardId`, optional preview model) — `Started`, `Refreshed`. Used by `guard_detail.screen.dart`, `body_guard_profile_screen.dart` (company view).
  - `GuardProfileBloc` (param `RecordOwner owner`) — the complete/edit profile flow for **both** a self-registered guard (`AccountOwner(userId)`) and a company-managed bodyguard (`ManagedBodyguardOwner(id)` or `null` id for "add new").
    - Events: `GuardProfileStarted`, `GuardProfileAvatarPicked(XFile)`, `GuardProfileServicesChanged(List<String>)`, `GuardProfileSubmitted(BodyguardProfileRequest)`, `GuardProfileBioSaved(String)`, `GuardProfileKeyDetailsSaved(...)` (used by the edit sheets).
    - State: `loadStatus`, `profile: BodyGuardModel?`, `selectedServiceIds`, `pickedAvatar`, `submitStatus: ApiState<String>` (success carries the saved bodyguard id for navigation to documents).
    - Submit sequence for **account owner** must equal today's `_handleNext` in `body_guard_complete_profile_screen.dart`: upload avatar to `StorageBuckets.avatars` at `'$userId/avatar_<millis>.jpg'` (upsert) → write `users.name`/`profile_image_url` (via `UserRepository.updateAccount`) **after** the `bodyguards` row (ordering rule in `ProfileFields` doc: profile row first, then account) → `ServicesRepository.assign` → `AuthProfileRefreshRequested`.
    - Submit for **managed bodyguard** must equal today's `_saveCompanyBodyguard`: read it and port step by step (save row, assign services, seed default availability for new rows).
    - Edit sheets (`edit_bio_sheet.dart`, `edit_key_details_sheet.dart`, `edit_services_sheet.dart`) receive the existing `GuardProfileBloc` via `BlocProvider.value` when opened from the profile screen and only dispatch events. **Remove their `users.metadata` writes** (legacy) — confirm with `grep -rn "metadata" lib/features/body_guard` that nothing reads them after §7.3.
  - `AvailabilityBloc` (param `RecordOwner`) — `Started`, `DayToggled(WeekDay)`, `TimeChanged(WeekDay, from, to)`, `Saved`. State: `Map<WeekDay, AvailabilityDraft>`, `loadStatus`, `saveStatus`. On empty result, default selection Mon–Fri (today's behaviour). **No metadata fallback / double-write** after the §7.3 backfill.
- **Delete after migration:** `bloc/bodyguards/bodyguards_cubit.dart`, `bloc/company_bodyguards/company_bodyguards_cubit.dart`, `domain/helpers/bodyguard_availability.helper.dart` (→ extension), every `Supabase.instance` and `sl<` in this feature's presentation.

### 6.4 `company`
- **Model `CompanyModel`** → admin fields (`id, userId, companyName, businessEmail, companyType, companyPhoneCode, companyPhoneNumber, experienceYears, address, latitude, longitude, licenseNumber, status, rejectionReason, createdAt, updatedAt`) + embedded `user` (the select in `CompanyRepository` embeds `user:users!companies_user_id_fkey(id,name,status,profile_image_url)` — keep it as a light `CompanyUserSummary` or `UserModel`; check how cards use it). Verify each column in `20261124000019_split_user_profiles.sql`. `companyType` is stored as `BusinessType.apiValue` (memory rule) — parse to the enum, label via extension.
- **Filters:** `CompanyFilters { List<UserStatus>? statuses; }` (default `[UserStatus.active]` for customers), applied via the `account_status` computed field — never an `!inner` join to `users` (customers cannot read `users`; that join emptied the customer list).
- **Request:** `CompanyProfileRequest` (company columns only) and the account part via `UserAccountRequest`.
- **Repository:** keep `CompanyRepository` (filters object instead of `status`/`statuses`); add `upsertForAccount(String userId, CompanyProfileRequest)` (upsert on `user_id`); `getByUserId(userId)`.
- **Blocs:** `CompaniesBloc extends PaginatedBloc<CompanyModel, CompanyFilters>`; `CompanyProfileBloc` for `company_complete_profile_screen.dart`, `company_edit_profile_screen.dart`, `company_information_screen.dart` (load, logo pick/upload, submit). Port `_handleNext` / `_handleSave` sequences exactly (logo upload path, order of writes, `AuthProfileRefreshRequested`).
- **Delete after migration:** `bloc/companies/companies_cubit.dart`, `CompanyModel.fakeData` → fixtures.

### 6.5 `auth` (do last — highest risk; §9.1 parity list is mandatory)
- **Before touching it:** write characterization tests (Phase 0.3).
- **`UserModel`**: already close to admin. Switch embeds to `EmbeddedParser`; `serviceListData` → `List<ServiceModel>`; `bankAccounts` → `List<UserBankAccountModel>`; remove `fromRequest` and `fakeData` (fixtures). Keep `@JsonKey(includeToJson: false)` on embeds.
- **`AuthRepository`** → a thin wrapper over `GoTrueClient` like admin `auth.repository.dart` (`currentUserId`, `authStateChanges` as `Stream<String?>`, `signIn`, `signUp`, `verifyOtp`, `resendOtp`, `sendPasswordReset`, `updatePassword`, `signOut`, `deleteAccount`). Keep the existing method bodies (OTP type mapping, email normalisation). Remove `domain/repositories/auth_repository.dart`; move `OtpType`/`OAuthProvider` exports to the barrel.
- **`UserRepository extends BaseSupabaseRepository<UserModel>`** (table `users`):
  - `static const _profileSelect` = today's `_fetchProfileRow` select **plus** the embeds the router and role screens need, so the separate `_fetchUserServices` / `_fetchUserDocuments` queries in `AuthBloc` disappear:
    ```
    *,
    bodyguard:bodyguards!bodyguards_user_id_fkey(*),
    company:companies!companies_user_id_fkey(*),
    availabilities:user_availabilities!user_availabilities_user_id_fkey(*),
    user_services!user_services_user_id_fkey(id, service:services(id, name, description, icon_name, icon_url, is_active, display_order)),
    documents:user_documents!user_documents_user_id_fkey(*, document_type:document_types(*))
    ```
    **Verify each FK name** in the migrations (`split_user_profiles.sql` adds `bodyguard_id` FKs, which is why hints are required). Test this select in the Supabase SQL/REST console before using it.
  - `Future<UserModel?> getProfile(String id)`, `Stream<UserModel?> watchProfile(String id)` — keep today's `watchUserData` algorithm (listen to `users` row + role table, re-read merged row, generation counter, keep last good row on re-read failure) but emit `UserModel` and also listen to `user_documents` for that `user_id` (so admin document rejections arrive without the old "reload role data" event).
  - `updateAccount(String id, UserAccountRequest request)`.
  - `checkRegistrationConflict(...)`, `checkEmailExists(...)` unchanged (RPC `check_registration_conflict`; add `DatabaseFunctions.checkRegistrationConflict` and `JsonKeys.pEmail/pPhoneNumber/pPhoneCode`). Note: they currently swallow errors and return "no conflict" — **keep** (PARITY: sign-up must not be blocked by a failed pre-check).
  - Delete `getUserData` (raw map), `createUserProfile`, `deleteUserProfile`, `userProfileExists`, `updateProfileFields` once callers use typed methods. Delete `profile_fields.dart` and replace its test with request-model tests.
- **`AuthBloc`** (app-wide, session only):
  - State: `sessionStatus`, `user: UserModel?`, `pendingRole: UserRole?` (role picked on select-role screen before sign-up), `pendingEmail: String?` (email awaiting OTP). Derived getters keep today's names used by the router: `isUnknown, isAuthenticated, isUnauthenticated, isGuard, isCompany, isCustomer, isApproved, isPendingApproval, isRejected, isBlocked, isDeleted, requiresOnboarding, hasRejectedDocuments, isProfileRejected, …`, all computed from `effectiveStatus` (customer ⇒ `active`, PARITY) and `user.documents`.
  - Events: `AuthStarted` (subscribes to `authRepository.authStateChanges` with `emit.onEach` → adds `_AuthUserIdChanged`), `_AuthUserIdChanged(String?)` (restartable; `null` → unauthenticated; else `await emit.forEach(userRepository.watchProfile(id), onData: _mapProfile)`), `AuthProfileRefreshRequested`, `AuthRoleSelected(UserRole)`, `AuthSignOutRequested`.
  - `_mapProfile` implements §9.1 rows 1, 6, 7.
- **`AuthFormBloc`** (screen-scoped: login, signup, email verification, forgot/reset password) — events `LoginSubmitted`, `SignUpSubmitted`, `OtpSubmitted`, `OtpResendRequested`, `PasswordResetCodeRequested`, `NewPasswordSubmitted`; state `status: ApiState<AuthFormResult>` where `AuthFormResult` is an enum (`signedIn`, `signedUp`, `otpVerified`, `resetCodeSent`, `passwordChanged`, `emailNotConfirmed`). Error text comes from `asyncHandler`'s `getAuthMessage` (replaces `errStr.contains(...)` sniffing). `email_not_confirmed` (Supabase `AuthException.code`) maps to result `emailNotConfirmed` (replaces the `'EMAIL_NOT_CONFIRMED'` sentinel) and triggers the OTP resend first (PARITY).
- **`AccountBloc`** (screen-scoped: `edit_profile_screen.dart`, `change_password_screen.dart`, profile screen delete action) — `AccountProfileSaved(UserAccountRequest, XFile? avatar)`, `AccountPasswordChanged`, `AccountDeleteRequested`.
- **Screens:** `admin_approval_screen.dart` `_checkStatus` (calls `getUserData` directly) → dispatch `AuthProfileRefreshRequested` and read state. `registration_fee_screen.dart` → `RegistrationFeeBloc` (§6.6).
- **Delete after migration:** `domain/` folder, `AuthUpdateUserServices`, `AuthUpdateUserDocuments`, `AuthReloadRoleDataRequested`, `AuthUpdateUserStatusRequested` (local status override — check who calls it; if used to move UI forward before realtime arrives, replace with `AuthProfileRefreshRequested`), mock branches.

### 6.6 `payments`
- **Models:** `UserBankAccountModel` (as admin `user_bank_account.model.dart`; replaces `BankAccount` + `fromSupabase`), `MembershipPlanModel` (as admin `membership_plan.model.dart`, `DiscountType` enum; remove redundant `@JsonKey(name:)`; replaces `PlanModel`). `TransactionModel` stays prototype (fixtures).
- **Repositories:** `BankAccountRepository` (`user_bank_accounts`, filter by `user_id`, order `is_primary desc, created_at desc` in the query — not in Dart), `MembershipPlanRepository` (`membership_plans`, `is_active = true`, order `display_order`).
- **Request:** `BankAccountRequest` (trim, upper-case IFSC only if the current screen does).
- **Blocs:** `BankAccountsBloc` (`Started`, `Added(BankAccountRequest)`, `Deleted(id)`, `PrimarySet(id)` — only the actions the screen has today), used by `my_bank_details_screen.dart` and `withdraw_money_sheet.dart` (read-only list). `MembershipPlansBloc` (`Started`, `PlanSelected`). The commented-out `membership_plan_id` writes stay commented (column does not exist) — delete the comments and leave a `// TODO(migration): membership purchase not implemented (no column)`.
- **`RegistrationFeeBloc`** — port `_handlePayment` in `registration_fee_screen.dart` exactly (fee from `AdminSettingsCubit.getRegistrationFee(role)` → injected; profile/status write via `UserRepository`; then `AuthProfileRefreshRequested`). Remove its mock values.

### 6.7 `legal`
- `LegalContentRepository` (`legal_content`): `getLatest({required UserRole role, required ContentType type, required String language})` with `JsonKeys.role/contentType/language/lastPublishedAt`, `.maybeSingle()`.
- `ContactUsRepository extends BaseSupabaseRepository<ContactUsModel>` + `ContactUsRequest { userId?, role, fullName, email, message }` (status `ContactUsStatus.pending.apiValue` — port the enum from admin `help-support/data/enums/contact_us_status.enum.dart`).
- `LegalContentBloc`, `ContactUsBloc` keep their events/states; constructor-inject repository + a `UserRole Function()` or the role as an event field — **no `sl<AuthBloc>()` inside**. Fallback to `staticContent` stays (PARITY: offline/no-row shows bundled text), moved to fixtures.
- Delete `domain/repositories/*`.

### 6.8 `settings` (move)
Move `core/config/admin_settings/` → `features/settings/` (`data/models`, `data/repositories`, `bloc/admin_settings_cubit.dart`). Pure move; update imports; no logic change. `AppGateCubit` stays in `app/gate/`.

### 6.9 `notifications` (polish only — the good module)
- Remove the `userId.isEmpty → fakeData` branch in `NotificationsBloc._onFetchRequested` (emit empty success instead).
- Wrap repository calls in `asyncHandler`; failure states carry `error: e`; replace `e.toString()`.
- `actionError: 'Failed to …'` literals → l10n via the screen (`actionStatus` pattern).
- Replace the `for` loops calling `decrement()` N times with `decrement(decreaseBy: n)`.
- Add `restartable()` to fetch/category events, `droppable()` to load-more.
- `getUserId: () => sl<AuthBloc>()...` in DI is acceptable (closure), but prefer injecting `AuthRepository` and reading `currentUserId`.

### 6.10 `app/` and `shared/`
- `app/app.dart`: providers per §4.3; add `SessionListener`.
- `app/routes/app_router.dart`: typed args (§4.8); extract redirect into `app/routes/redirect.dart` `String? resolveRedirect({required AuthState auth, required String location})` (Phase 0) and call it from `redirect:`.
- `main_navigation.screen.dart`: the `loadCount` call on init moves to `SessionListener`; badge uses `BlocBuilder<UnreadNotificationCountCubit, int>` without `bloc: sl<…>()`.
- `LanguageCubit`: inject `LocalStorage` and a `void Function(String code) onLanguageChanged` (wired in DI to `sl<UserDeviceCubit>().updateDeviceLanguage`) — removes `sl` from the cubit.
- `customer/*` screens: consume `BodyguardsBloc`, `CompaniesBloc`, `ServicesCatalogCubit` via providers created in the screen.

---

## 7. Known bugs and traps (fix them — each in its own commit, inside the phase that touches the file)

| # | Trap | Fix |
|---|---|---|
| 7.1 | `UserStatus.fromApiValue(null)` → `active` | Parse with `SafeEnumConverter(UserStatus.values, defaultValue: UserStatus.incomplete)`; audit every call site of `fromApiValue` (`grep -rn "fromApiValue" lib`). |
| 7.2 | `WeekDay` uppercase `@JsonValue` vs lowercase DB | §6.3. Add a unit test parsing both `'monday'` and `'MONDAY'`. |
| 7.3 | Legacy availability stored in `users.metadata['availability']` | **Before** removing the fallback, add migration `supabase/migrations/2026112600000X_backfill_user_availabilities_from_metadata.sql`: for each `users` row with `metadata ? 'availability'` and no `user_availabilities` rows, insert 7 rows (`day_of_week` lowercase key, `is_available`, `from_time = ->>'from'`, `to_time = ->>'to'`) `ON CONFLICT (user_id, day_of_week) DO NOTHING`. Do **not** delete the metadata key. Document it in `documentation/user_profile_data.md` and link from `README.md` (memory rule: backend changes ship with docs). |
| 7.4 | Unquoted search filter | §5.4. |
| 7.5 | Dropped `code` column still read | §6.1, §6.2. |
| 7.6 | `DatabaseTables.userProfiles` / `documents` constants | `documents` table does not exist → delete constant. `user_profiles` view exists but the app should not read it (the merged read uses embeds) → delete the constant from the app if unused. |
| 7.7 | `set_user_services` delete+insert fallback | Delete (RPC exists). |
| 7.8 | DI-time subscription & preload | §4.3. |
| 7.9 | `LanguageCubit`/`ConnectivityCubit` factories used as singletons | §4.3. |
| 7.10 | `PaginationState` default `const` inference | §5.6 note. |
| 7.11 | Generic events not matching | §5.6 trap. |
| 7.12 | `AuthState.authenticated` forces customer status to `active` | Keep (PARITY) as `effectiveStatus`; add a test. |
| 7.13 | `BaseSupabaseRepository.getDetails` ignores `selectColumns` | §5.4.3; check `BodyguardRepository`/`CompanyRepository` overrides. |

---

## 8. Execution plan

### 8.0 Gate (run after **every** step)
```bash
cd guardup
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed lib test   # only the files you touched
flutter analyze                              # must print: No issues found!
flutter test
```
Plus the manual smoke tests from §10 for the roles the step touched. If anything fails, fix within the step or revert it.

### Phase 0 — Safety net (no behaviour change)
- 0.1 Commit/stash the current WIP (P20) so the migration starts from a clean tree; create branch `refactor/app-bloc-architecture`.
- 0.2 Add dev deps `bloc_test`, `mocktail`; add `bloc_concurrency`.
- 0.3 **Characterization tests** for today's behaviour (they must pass before and after the migration):
  - `AuthBloc`: rows of §9.1 using mocked `AuthRepository`/`UserRepository`.
  - Extract `resolveRedirect` (pure move from `app_router.dart`) and test every branch: unknown, unauthenticated public/private, blocked, deleted, pending, rejected (profile / documents / both), onboarding guard/company/payment, approved on auth route, company-only routes.
  - `ProfileFields.split` test already exists — keep until 6.5.
- 0.4 Write `documentation/app_architecture.md` skeleton (final version in Phase 10).

### Phase 1 — Core (§5): one commit per subsection 5.1 → 5.8 (5.7 removals wait for Phase 9).

### Phase 2 — Models & enums
- 2.1 Port enum pattern + `SafeEnumConverter` to all DB enums (`UserStatus`, `UserRole`, `GenderType`, `DocumentStatus`, `WeekDay`, `NotificationType`, `ContentType`, `BusinessType`, …). Keep old `fromApiValue` as `@Deprecated` wrappers → fix all call sites → delete.
- 2.2 `ServiceModel` (6.1), `DocumentTypeModel` / `UserDocumentModel` (6.2), `UserAvailabilityModel` (6.3), `UserBankAccountModel`, `MembershipPlanModel` (6.6).
- 2.3 `BodyGuardModel`, `CompanyModel`, `UserModel` alignment (6.3/6.4/6.5) with `@Deprecated` bridges for removed getters; extensions for display helpers.
- 2.4 Filters + request models for every feature (§6), with unit tests for `toJson()` (keys, trimming, null handling).
- 2.5 Fixtures move (§5.9).

### Phase 3 — Repositories & DI
- 3.1 Register `SupabaseClient`/`GoTrueClient`; make every repository take a required client; create `di/<feature>.di.dart` files; `injection_container.dart` only calls them (no behaviour change yet).
- 3.2 New repositories: `ServicesRepository`, `DocumentTypesRepository`, `UserDocumentsRepository`, `AvailabilityRepository`, `BankAccountRepository`, `MembershipPlanRepository`, `LegalContentRepository`, `ContactUsRepository`. Unit-test query construction where practical (mock `SupabaseClient` is heavy — at minimum test request/filters models and parsing of sample JSON rows copied from real responses).
- 3.3 Upgrade `BodyguardRepository`, `CompanyRepository`, `UserRepository`, `AuthRepository` (§6.3–6.5) keeping old methods as `@Deprecated` delegates.

### Phase 4 — Shared pagination bloc (§5.6) + tests (load, search, next page, stale-response drop, error, last page).

### Phase 5 — Feature blocs, lowest risk first (each = bloc + tests + screens switched + old code deleted)
- 5.1 `ServicesCatalogCubit` (6.1)
- 5.2 `settings` move (6.8)
- 5.3 `legal` (6.7)
- 5.4 `notifications` polish (6.9)
- 5.5 `CompaniesBloc` (6.4 list)
- 5.6 `BodyguardsBloc` + customer screens (6.3, 6.10)
- 5.7 `CompanyBodyguardsBloc` (6.3)
- 5.8 `BodyguardDetailsBloc` (6.3)
- 5.9 `BankAccountsBloc`, `MembershipPlansBloc` (6.6)
- 5.10 Backfill SQL 7.3 + docs → then `AvailabilityBloc` (6.3)
- 5.11 `DocumentsBloc` (6.2) — all four document screens/tabs
- 5.12 `GuardProfileBloc` + edit sheets (6.3)
- 5.13 `CompanyProfileBloc` (6.4)
- 5.14 `RegistrationFeeBloc` (6.6)

### Phase 6 — Auth (6.5), in this order, each its own commit
- 6.1 `UserRepository.watchProfile` returning `UserModel` with the full embed select; verify in console.
- 6.2 New `AuthBloc` (session only) behind the same public `AuthState` getters; §9.1 tests green.
- 6.3 `AuthFormBloc`; switch login, signup, email verification, forgot/reset screens.
- 6.4 `AccountBloc`; switch edit profile, change password, delete account.
- 6.5 Delete old events, `domain/`, `ProfileFields`, raw-map methods.

### Phase 7 — Presentation sweep
- 7.1 Remove every `sl<` from presentation except `BlocProvider.create` (§11 audit).
- 7.2 Typed route args (§4.8).
- 7.3 Localise remaining literals (both arb files) and replace raw error display with `context.apiErrorText`.
- 7.4 `SessionListener`, `LanguageCubit` injection (6.10).

### Phase 8 — Dead code
Delete everything listed under "Delete after migration" in §6 that is still present; `grep` for each symbol before deleting.

### Phase 9 — Mechanical consistency (separate commits, zero logic)
- 9.1 Folder renames `enum/` → `enums/`, `model/` → `models/` (use `git mv`, then fix imports).
- 9.2 File naming: pick `.screen.dart` / `.widget.dart` / `.model.dart` / `.repository.dart` / `_bloc.dart` consistently (admin style) — one feature per commit.
- 9.3 Remove unused packages (§5.7), one per commit, building Android + iOS.

### Phase 10 — Documentation
- Finalise `documentation/app_architecture.md` (layers, Bloc vs Cubit rule, DI, how to add a feature — step-by-step using `services` as the example).
- Update `rules.md` (both copies: repo root and `guardup/rules.md`) §1 and §7 with the Bloc rules of §4.
- Mark `documentation/app_architecture_refactoring_plan.md` as superseded (one line at the top).

---

## 9. Behaviour parity checklists

### 9.1 AuthBloc (test every row in Phase 0.3, keep green through Phase 6)

| # | Situation | Expected |
|---|---|---|
| 1 | App start, session exists, profile row found | `authenticated`, `user` set, status from DB (customer ⇒ `active`) |
| 2 | App start, session exists, no profile row | `unauthenticated` |
| 3 | App start, no session | `unauthenticated` |
| 4 | Login OK, status not deleted | `authenticated`; realtime watch started |
| 5 | Login OK but profile status `DELETED` | sign out, stay on login, error "Invalid email or password. Please try again." |
| 6 | Realtime: admin sets `BLOCKED` | stay `authenticated`, status `blocked` (router → blocked screen) |
| 7 | Realtime: admin sets `DELETED` | sign out → `unauthenticated` |
| 8 | Realtime: status → `REJECTED` or `PENDING_APPROVAL` | user (incl. documents & services) re-read |
| 9 | Login with unconfirmed email | OTP resent to that email; UI navigates to email verification with that email |
| 10 | Sign up | auth user created with metadata `role` (apiValue), `name`, `phone`, `phone_code` (default `+91`); state stays unauthenticated with `pendingEmail` set; `public.users` row created by trigger (no client insert) |
| 11 | Verify OTP (signup) | customer ⇒ `active`; guard/company ⇒ status from DB (normally `incomplete`) |
| 12 | Verify OTP (recovery) | keeps DB status |
| 13 | Reset password | password changed, then signed out |
| 14 | Delete account | `deleteAccount`; on success `unauthenticated`; on failure error "Failed to delete account. Please try again." and stays signed in |
| 15 | Role picked before sign-up | kept in state (`pendingRole`) and used for signup metadata and OTP target status |
| 16 | Sign out | device row cleared (via `SessionListener`), unread count 0, `unauthenticated` |

### 9.2 Profile / onboarding flows (manual, per role)
- Guard: sign up → OTP → complete profile (photo, name, rate, bio, services) → documents → registration fee → pending approval screen. Reopen app at each step: router resumes at the same step.
- Company: same with company profile and logo; logo document syncs to company/profile image exactly as today.
- Company-managed bodyguard: add → profile → services → documents → submitted (`PENDING_APPROVAL`); edit existing; rejected one shows rejection reason and can be resubmitted; delete with confirmation; list filters (all / pending incl. incomplete / active / rejected) and search.
- Availability: guard edits days and times; company edits a managed bodyguard's schedule; values round-trip in the admin panel's availability section.

---

## 10. Smoke test script (run for the touched roles after each Phase 5/6 step)

| Role | Steps |
|---|---|
| Customer | launch (logged out) → sign up → OTP → home loads services, companies, bodyguards → search bodyguards → open guard details → open company details → notifications (mark read, delete) → contact us submit → legal pages → change language EN/AR → logout |
| Guard | login → pending/rejected/approved screens per status → profile: edit bio, key details, services, availability → documents tab → bank details add → notifications → logout |
| Company | login → home → bodyguards roster (filters, search, pagination, delete) → add bodyguard full flow → edit bodyguard → company edit profile → documents → logout |
| Admin actions (use guardup_admin) | approve / reject profile / reject document / block / delete a test user while the app is open → app reacts in realtime per §9.1 rows 6–8 |
| Offline | turn off network on a list screen → error state with localised "no internet" text and retry works |

---

## 11. Definition of done (all must hold; the commands are the audit)

```bash
cd guardup/lib
# 1. No Supabase outside repositories / DI / core services
grep -rn "Supabase.instance" --include='*.dart' . | grep -v "^./core/di/\|^./bootstrap/"           # → empty
grep -rln "supabase_flutter" --include='*.dart' features/*/bloc features/*/presentation app shared # → empty
# 2. No service locator in widgets except BlocProvider.create (review remaining lines by hand)
grep -rn "sl<\|sl\.isRegistered" --include='*.dart' features/*/presentation shared app | grep -v "create:"
# 3. Cubits only from the allow-list (§4.2)
grep -rn "extends Cubit<" --include='*.dart' .
# 4. No raw keys in queries/payloads
grep -rnE "\.(eq|neq|select|order|inFilter|isFilter)\(['\"]" --include='*.dart' --exclude='*.g.dart' .  # → empty
grep -rnE "\{\s*['\"][a-z_]+['\"]\s*:" --include='*.dart' --exclude='*.g.dart' --exclude-dir=gen features core  # → empty (except l10n/tests)
# 5. Fake data only in fixtures
grep -rln "fakeData\|[Mm]ock" --include='*.dart' --exclude-dir=gen . | grep -v "/fixtures/"          # → empty
# 6. No swallowed / stringified errors
grep -rn "catch (_) {}" --include='*.dart' .                                                         # → empty
grep -rn "e.toString()" --include='*.dart' features                                                  # → empty
# 7. No domain layer, no document_submission service
ls features/*/domain core/services/document_submission 2>/dev/null                                   # → nothing
```
And: `flutter analyze` clean, `flutter test` green (≥ one test file per bloc, plus model/request/enum tests), §10 smoke tests pass on Android and iOS, docs of Phase 10 merged.

---

## 12. Appendix — old → new map

| Old | New |
|---|---|
| `features/body_guard/bloc/services/services_cubit.dart` | `features/services/bloc/services_catalog_cubit.dart` |
| `features/body_guard/data/model/service_item.model.dart` | `features/services/data/models/service.model.dart` |
| `core/services/document_submission/document_submission_service.dart` | `features/documents/data/repositories/{document_types,user_documents}.repository.dart` + `features/documents/bloc/documents/` |
| `features/body_guard/data/model/{document_type,user_document}.model.dart` | `features/documents/data/models/` |
| `features/body_guard/bloc/bodyguards/bodyguards_cubit.dart` (untracked WIP) | `features/body_guard/bloc/bodyguards/bodyguards_bloc.dart` (PaginatedBloc) |
| `features/body_guard/bloc/company_bodyguards/company_bodyguards_cubit.dart` | `features/body_guard/bloc/company_bodyguards/company_bodyguards_bloc.dart` |
| `features/company/bloc/companies/companies_cubit.dart` | `features/company/bloc/companies/companies_bloc.dart` |
| logic in `body_guard_complete_profile_screen.dart`, `body_guard_profile_screen.dart`, `sheets/*.dart` | `features/body_guard/bloc/guard_profile/` |
| logic in `bodyguard_availability.widget.dart` | `features/body_guard/bloc/availability/` + `AvailabilityRepository` |
| logic in `company_complete_profile_screen.dart`, `company_edit_profile_screen.dart` | `features/company/bloc/company_profile/` |
| logic in `my_bank_details_screen.dart`, `withdraw_money_sheet.dart` | `features/payments/bloc/bank_accounts/` + `BankAccountRepository` |
| logic in `membership_plans_screen.dart` | `features/payments/bloc/membership_plans/` + `MembershipPlanRepository` |
| logic in `registration_fee_screen.dart` | `features/payments/bloc/registration_fee/` |
| `features/payments/data/model/{bank_account,plan}.model.dart` | `user_bank_account.model.dart`, `membership_plan.model.dart` |
| `features/auth/bloc/auth_bloc.dart` (805 lines) | `bloc/auth/` (session) + `bloc/auth_form/` + `bloc/account/` |
| `features/auth/data/profile_fields.dart` | request models: `UserAccountRequest`, `BodyguardProfileRequest`, `CompanyProfileRequest` |
| `features/*/domain/repositories/*` | deleted |
| `core/config/admin_settings/` | `features/settings/` |
| DI listeners in `injection_container.dart` | `app/session/session_listener.dart` |
| `*.fakeData` | `features/*/data/fixtures/*.fixtures.dart` |
