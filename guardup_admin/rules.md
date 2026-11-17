# Project Code & Design Guidelines (rules.md)

This document defines the strict code consistency and design rules for the **Supplr Transport Hub** Flutter project (`supplr_transport_hub`).
All AI agents and developers **MUST** follow these guidelines when creating or modifying code in this codebase.

---

## 1. Architecture & Folder Structure

The project follows a **Feature-First Clean Architecture** pattern:

```text
lib/
├── app/                  # Application configuration (router, theme, global setup)
│   ├── routes/           # AppRoutes constants & GoRouter config
│   └── theme/            # Theme, color accessor, text themes
├── bootstrap/            # App initialization & bootstrapping logic
├── core/                 # Shared core utilities, extensions, network, constants
│   ├── constants/        # AppSpacing, AppRadius, AppRegx, AppConstants
│   ├── extensions/       # Context, TextStyle, Space, Layout, String extensions
│   ├── error/            # Failures, exceptions
│   ├── logger/           # AppLogger instance
│   └── services/         # Storage, network, API services
├── features/             # Feature modules (feature-first)
│   └── <feature_name>/
│       ├── data/         # Models, DTOs, Repositories implementations, Data sources
│       ├── domain/       # Entities, Repository interfaces, Use cases
│       └── presentation/ # Screens, Widgets, Controllers/Providers
├── gen/                  # FlutterGen generated assets (Assets.svg, Assets.png)
├── l10n/                 # Localization files
└── shared/               # Reusable UI widgets, inputs, buttons, dialogs
```

### Key Rules:
- New features **MUST** be placed inside `lib/features/<feature_name>/`.
- Generic, reusable UI components belong in `lib/shared/widgets/` organized by category (`buttons/`, `inputs/`, `sections/`, `state/`, etc.).
- Never place feature-specific business logic or UI directly into `core/` or `app/`.

---

## 2. Design System & Styling Rules

### A. Colors (Theme Accessor)
- **NEVER hardcode raw hex colors** (`Color(0xFF...)`) inside screens or widgets.
- **ALWAYS** access colors through `context.colors.<colorName>`.

```dart
// ✅ GOOD
Container(
  color: context.colors.primary,
  borderColor: context.colors.borderLight,
)

// ❌ BAD
Container(
  color: Color(0xFF1E88E5), // Direct hex prohibited
)
```

### Color Reference (`context.colors`):
- Brand: `primary`, `onPrimary`, `secondary`, `secondaryLight`, `surface`, `onSurface`
- Backgrounds: `backgroundLight`, `backgroundDark`
- Status: `success`, `successLight`, `warning`, `warningLight`, `info`, `infoLight`, `error`, `errorLight`
- Borders & Accents: `borderLight`, `borderDark`, `onSurfaceSecondary`, `white`, `black`, `transparent`

---

### B. Typography & TextStyle Extensions
- Access the base font style via `context.textTheme.<styleName>`.
- Use `TextStyleExtension` methods to chain text styling instead of instantiating raw `TextStyle(...)`.

```dart
// ✅ GOOD
Text(
  'Welcome Back',
  style: context.textTheme.titleLarge
      ?.semiBold()
      .colour(context.colors.onSurface)
      .size(20),
)

// ❌ BAD
Text(
  'Welcome Back',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  ),
)
```

#### Available Extension Methods:
- Weight: `.bold()`, `.semiBold()`, `.medium()`, `.regular()`, `.weight(FontWeight)`
- Color: `.colour(Color)`
- Size: `.size(double)`, `.increaseSize(int)`, `.decreaseSize(int)`
- Line Height & Spacing: `.lineHeight(double)`, `.textSpacing(double)`
- Style: `.italic()`, `.underline()`

---

### C. Spacing & Dimensions (Token Standardization)
- **NEVER hardcode raw dimension numbers** (e.g., `28`, `38`, `44`, `12`, `14`, `16`, `18`, `8.w`) for heights, widths, font sizes, icon sizes, paddings, or margins.
- **ALWAYS use design tokens** from `AppSpacing` (`xs: 4`, `sm: 8`, `md: 12`, `lg: 16`, `xl: 20`, `xxl: 24`, `xxxl: 32`) and `AppRadius` (`xs: 4`, `sm: 8`, `md: 12`, `lg: 16`, `xl: 20`, `xxl: 24`, `round: 28`, `full: 999`).
- **Composing Nearest Tokens**: When an exact single token does not match an intermediate dimension, compose tokens using token arithmetic or token offsets rather than arbitrary magic numbers:
  - Small button height (`28`): `AppRadius.round`
  - Medium button height (`38`): `(AppSpacing.md * 3) + 2`
  - Large button height (`44`): `AppSpacing.xxl + AppSpacing.xl`
  - Font size 14: `AppSpacing.md + 2`
  - Icon gap 8: `AppSpacing.sm.w` (never `8.w`)
  - Spinner dimension 18: `AppSpacing.lg + 2`
- Use `SpaceExtension` getters (`.h`, `.w`, `.hp`, `.vp`, `.ap`) and `AppSpacing` constants for margins, paddings, and sized boxes.
- Access screen padding via `context.screenPadding`, `context.horizontalPadding`, `context.verticalPadding`.
- For dynamic responsiveness, use percentage shortcuts (`50.pw(context)` or `context.widthPercent(50)`).

```dart
// ✅ GOOD
Column(
  children: [
    Text('Title'),
    AppSpacing.md.h, // Uses AppSpacing token
    Text('Subtitle'),
  ],
)

// Compose nearest tokens when intermediate dimension is needed
height: (AppSpacing.md * 3) + 2, // 38
padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
gap: AppSpacing.sm.w, // instead of raw 8.w

// ❌ BAD
Column(
  children: [
    Text('Title'),
    SizedBox(height: 16.0), // Manual SizedBox prohibited
    Text('Subtitle'),
  ],
)

height: 38, // Hardcoded magic number prohibited
SizedBox(width: 8.0) // Raw width prohibited (use AppSpacing.sm.w)
```

---

### D. Corner Radius & Borders
- Use `AppRadius` constants (`xs`, `sm`, `md`, `lg`, `xl`, `xxl`, `round`, `full`) and pre-built `BorderRadius` helpers (`AppRadius.mdRadius`).

```dart
// ✅ GOOD
ClipRRect(
  borderRadius: AppRadius.mdRadius,
  child: child,
)

// ❌ BAD
BorderRadius.circular(12.0) // Hardcoded radius numbers prohibited
```

---

### E. Container Styling
- Use `QuickContainer` (from `package:quick_container/quick_container.dart`) or styled `Container` for rounded cards, borders, and shadows to maintain visual consistency.

---

## 3. Assets & Image Usage

- **ALWAYS** use generated asset references from `lib/gen/assets.gen.dart` (`Assets.svg.*` and `Assets.png.*`).
- Use `AppImage` widget from `lib/shared/widgets/sections/app_image.dart` or `flutter_svg` for rendering SVGs and network/asset images.

```dart
// ✅ GOOD
Assets.svg.logoIcon.svg(
  width: 40,
  height: 40,
)

// ❌ BAD
SvgPicture.asset('assets/svg/Logo Icon.svg') // String literal asset paths prohibited
```

---

## 4. Navigation & Routing

- All routes **MUST** be defined in `AppRoutes` (`lib/app/routes/app_routes.dart`).
- Use `go_router` for navigation (`context.go(...)`, `context.push(...)`).

```dart
// ✅ GOOD
context.push(AppRoutes.verifyOtp);

// ❌ BAD
Navigator.push(context, MaterialPageRoute(...)); // Raw Navigator push prohibited
context.go('/verifyOtp');                       // Hardcoded string route prohibited
```

---

## 5. State Management & Data Models

- **State Management**: Use `flutter_riverpod` (`ConsumerWidget`, `ConsumerStatefulWidget`, `Notifier` / `AsyncNotifier`).
- **Local Widget State**: For local UI states (active tabs, view modes, hover states, toggles, loading flags), **NEVER** use `setState()`. **ALWAYS** use `ValueNotifier<T>` and `ValueListenableBuilder<T>` (see Section 18 for full specification).
- **Data Models & Sample Data Location**: Data models (e.g., `EnquiryData`, `TruckData`, `OrderModel`) and their sample datasets (`sampleList`) **MUST** be placed in the feature data layer (`lib/features/<feature>/data/models/<model_name>.model.dart`), **NEVER** declared directly inside UI presentation screens or widget files.
- **Data Models Serialization**: Use `@freezed` and `@JsonSerializable` for immutable data classes and DTOs.
- **Global `field_rename: snake` & `@JsonKey` Rule**:
  - `build.yaml` has `field_rename: snake` globally configured for `json_serializable`. Standard Dart `camelCase` properties automatically map to `snake_case` JSON keys (e.g., `isActive` -> `is_active`, `createdAt` -> `created_at`).
  - **DO NOT specify `@JsonKey(name: ...)` for standard field names in data models**. Redundant `@JsonKey` annotations are strictly prohibited.
  - **Only use `@JsonKey` for non-standard overrides**:
    - Fallback for unknown enum values: `@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)`
    - Non-snake-case or irregular backend column names
    - Custom type converters or conditional inclusion (e.g., `@JsonKey(includeIfNull: false)`)
- **Centralized `JsonKeys` in Core vs. Data Models**: All database column names and API payload keys for raw queries, sorting, and update payloads **MUST** be referenced via `JsonKeys.<key>` in `lib/core/constants/api/json_keys.dart`. Data models are exempt since `build.yaml` handles `field_rename: snake` automatically.
- Always generate code using `build_runner` after adding/updating model annotations:
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```

```dart
// ✅ GOOD - Riverpod Consumer Widget
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileProvider);
    return Scaffold(...);
  }
}
```

---

## 6. Logging & Error Handling

- **NEVER** use `print()` or `debugPrint()`.
- Use `AppLogger` (`lib/core/logger/app_logger.dart`) for structured logging across the app.
- Wrap asynchronous state mutations and API calls in try-catch blocks returning domain `Failure` instances.

```dart
// ✅ GOOD
AppLogger.i('Navigating to otp verification screen');
AppLogger.e('Failed to authenticate user', error, stackTrace);

// ❌ BAD
print('User logged in');
```

---

---

## 7. Modular Form Step Architecture & Controller Lifecycle Management

- **Form Step Widget Encapsulation**: Form step widgets (e.g. `BuyerSignupStep1..5`, `TransportSignupStep1..5`, `CreateTripStep1..3`, etc.) **MUST** manage their input controllers (`TextEditingController`, `SelectionController`, `ValueNotifier`, etc.) **internally** within their `StatefulWidget` state.
- **Clean Constructors**: Step widgets should only accept optional validation parameters such as `final GlobalKey<FormState>? formKey;` instead of receiving external controllers through constructor arguments.
- **Resource Lifecycle & Disposal**: All internally created controllers and listeners **MUST** be explicitly disposed in the widget state's `dispose()` method to avoid memory leaks.

```dart
// ✅ GOOD - Self-contained Step widget with internal controllers & disposal
class BuyerSignupStep1 extends StatefulWidget {
  final GlobalKey<FormState>? formKey;

  const BuyerSignupStep1({super.key, this.formKey});

  @override
  State<BuyerSignupStep1> createState() => _BuyerSignupStep1State();
}

class _BuyerSignupStep1State extends State<BuyerSignupStep1> {
  final TextEditingController _businessNameController = TextEditingController();
  final SelectionController<BusinessType> _businessTypeController =
      SelectionController<BusinessType>([]);

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(...),
    );
  }
}
```

---

## 8. Feedback, Dialogs & Shared Components

- **Feedback Overlays**: Use `AppSnackbar.show(...)`, `AppPopup.show(...)`, and `AppSheet.show(...)` from `lib/shared/widgets/feedbacks/` instead of raw `ScaffoldMessenger`, `showDialog`, or `showModalBottomSheet`.
- **Inputs & Selection**: Always prefer `lib/shared/widgets/inputs/` (`AppTextField`, `AppDropdown`, `AppPinInput`, `DocumentUploadCard`) and `lib/shared/widgets/buttons/` (`AppButton`) to enforce uniform user experience across forms.
- **Localization**: Access localized UI text through `context.l10n.<stringKey>`.

---

## 9. Formatting & Code Quality Checklist

Before submitting code:
1. Run `flutter analyze` and resolve all warnings/errors.
2. Maintain strict lint rules configured in `analysis_options.yaml`.
3. Keep constructors `const` whenever possible.
4. Ensure files have docstrings describing screens and complex components.
5. Never leave empty catch blocks, unused imports, or undisposed controllers/listeners.

---

## 10. Screen Headers & AppAppBar Standard

- Standard screens **MUST** use `AppAppBar` from `lib/shared/widgets/sections/app_appbar.dart` instead of raw `AppBar`.
- Use the provided factory constructors:
  - `AppAppBar.primary(title: 'Title', showNotificationIcon: true)` for primary screens.
  - `AppAppBar.transparent(title: 'Title')` for transparent overlays.
  - `AppAppBar.modal(title: 'Title')` for modal/sheet headers.

```dart
// ✅ GOOD
Scaffold(
  appBar: AppAppBar.primary(
    title: 'Status History',
    showNotificationIcon: true,
  ),
  body: ...,
)

// ❌ BAD
Scaffold(
  appBar: AppBar(title: Text('Status History')), // Raw AppBar prohibited
)
```

---

## 11. Form Input Layout & Field Labeling

- Form input fields **MUST** follow the standardized sequence:
  1. `AppFieldLabel(text: 'Label', isRequired: true/false)`
  2. `AppSpacing.xs.h`
  3. `AppTextField` or `AppDropdown`
  4. `AppSpacing.lg.h` (spacing to the next field)

```dart
// ✅ GOOD
const AppFieldLabel(text: 'Vehicle Number', isRequired: true),
AppSpacing.xs.h,
AppTextField(
  controller: _vehicleController,
  decoration: const InputDecoration(hintText: 'e.g. MH 12 AB 1234'),
),
AppSpacing.lg.h,
```

---

## 12. Sticky Bottom Action Bar Pattern

- Persistent or bottom-pinned action buttons on screens **MUST** be placed in `Scaffold.bottomNavigationBar` wrapped in `QuickContainer`:

```dart
// ✅ GOOD
Scaffold(
  body: SingleChildScrollView(...),
  bottomNavigationBar: QuickContainer(
    px: context.horizontalScreenPadding,
    pb: context.verticalScreenPadding,
    child: AppButton(
      text: 'Save',
      onPressed: () => _handleSave(),
    ),
  ),
)
```

---

## 13. UI-Internal Record Typedefs & Specification Mappings

- For UI-internal specifications, configuration maps, tuples, sheet actions, steps, or static presentation items, **ALWAYS** use Dart record `typedef` declarations.
- **NEVER** declare boilerplate private helper classes (e.g. `class _ButtonStyleSpec`, `class _ButtonSizeSpec`, `class _AppTextFieldTypeSpec`, `class _AppInputSizeSpec`).
- Combine record `typedef` with declarative `static const Map<EnumType, RecordTypedef>` mappings for clean, compile-time constant component configurations:

```dart
// ✅ GOOD - Record typedefs for component specs
typedef _ButtonStyleSpec = ({
  Color background,
  Color foreground,
  BorderSide? border,
  double? elevation,
});

typedef _ButtonSizeSpec = ({
  double height,
  EdgeInsets padding,
  double fontSize,
});

static const Map<ButtonSize, _ButtonSizeSpec> _sizeSpecs = {
  ButtonSize.small: (
    height: AppRadius.round,
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    fontSize: AppSpacing.md,
  ),
  ButtonSize.medium: (
    height: (AppSpacing.md * 3) + 2,
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
    fontSize: AppSpacing.md + 2,
  ),
};

// ❌ BAD - Creating repetitive boilerplate classes
class _ButtonStyleSpec {
  final Color background;
  final Color foreground;
  ...
}
```

---

## 14. Checkbox & Agreement Tile Standard Pattern

- Checkboxes accompanied by text labels **MUST** use `CheckboxListTile` configured with:
  - `activeColor: context.colors.secondary`
  - `dense: true`
  - `visualDensity: const VisualDensity(vertical: -AppSpacing.xs, horizontal: -AppSpacing.xs)`
  - `contentPadding: EdgeInsets.zero`
  - `controlAffinity: ListTileControlAffinity.leading`

```dart
// ✅ GOOD - Controlled with ValueNotifier & ValueListenableBuilder
ValueListenableBuilder<bool>(
  valueListenable: _saveForFutureNotifier,
  builder: (context, saveForFuture, _) => CheckboxListTile(
    activeColor: context.colors.secondary,
    dense: true,
    visualDensity: const VisualDensity(
      vertical: -AppSpacing.xs,
      horizontal: -AppSpacing.xs,
    ),
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    title: Text(
      'Save for future use',
      style: context.textTheme.bodyMedium?.colour(context.colors.onSurface),
    ),
    value: saveForFuture,
    onChanged: (val) => _saveForFutureNotifier.value = val ?? false,
  ),
)
```

---

## 15. Clean Widget Architecture & Standard Overrides (Anti-Overburdening Rule)

- **NEVER overburden or overfill widgets with dozens of fragmented micro-properties**:
  - Do **NOT** introduce piecemeal properties like `horizontalPadding`, `verticalPadding`, `leftPadding`, `rightPadding`, `horizontalMargin`, `verticalMargin`, `color`, `textColor`, `borderColor`, `iconSideSpace`, `fontSize`, `fontWeight`, `fontFamily`, `textAlign`, `isSolid`, `isBorder`, etc.
  - Fragmented micro-properties clutter widget APIs, make maintenance brittle, and break design consistency.
- **ALWAYS provide standard Flutter object overrides**:
  - `padding: EdgeInsetsGeometry?` (callers supply `EdgeInsets.only(...)`, `EdgeInsets.symmetric(...)`, `EdgeInsets.all(...)`).
  - `margin: EdgeInsetsGeometry?` (wrapped with outer `Padding` if provided).
  - `backgroundColor: Color?` & `foregroundColor: Color?`.
  - `border: BorderSide?` & `borderRadius: BorderRadius?`.
  - `elevation: double?`.
  - `textStyle: TextStyle?` (callers control typography through text extensions).
  - `width: double?` & `height: double?`.

```dart
// ✅ GOOD - Clean, standard Flutter overrides
class AppButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;

  // Standard overrides
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderSide? border;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  ...
}

// ❌ BAD - Fragmented, cluttered micro-properties
class BadButton extends StatelessWidget {
  final double? leftPadding;
  final double? rightPadding;
  final double? horizontalPadding;
  final double? verticalPadding;
  final double? verticalMargin;
  final Color? color;
  final Color? textColor;
  final Color? borderColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  ...
}
```

---

## 16. Professional Enterprise Console Standards & Web Preloader Harmonization

- **Enterprise B2B Aesthetics**: Supplr Transport Hub is a mission-critical fleet and logistics management console (comparable to Stripe, Linear, or AWS Console). It is **NOT** a gaming, crypto, or cyberpunk portal.
- **Prohibited Styling Tropes**:
  - **NEVER** use rotating conic-gradient halos, glowing orbs, 90px blurs, cyberpunk tech grid overlays, or heavy multi-color shimmer sweeps.
- **Color Discipline**:
  - Canvas: Clean enterprise light surface `context.colors.backgroundLight` (`#F4F8F8`).
  - Brand Mark: Solid Primary Navy `context.colors.primary` (`#0F2A3D`) with clean white icon.
  - Accent: Tasteful Teal `context.colors.secondary` (`#0EA5A4`) used with restraint for active focal points.
  - Cards: Crisp white surfaces `context.colors.white` with subtle border `context.colors.borderLight` and soft, understated elevation.
- **Web Splash / Preloader (`web/index.html`)**:
  - The web preloader **MUST** strictly mirror the Flutter app's palette and layout (`#F4F8F8` background, `#0F2A3D` logo box, `#FFFFFF` elevated card, clean typography).
  - Must connect to `flutter-first-frame` and DOM mutation observers to seamlessly fade out on engine mount with **zero color flash or visual jump**.

---

## 17. Selection & Checkbox Standard (`AppRadio`)

- For selection options and branded checkboxes (e.g. *"Remember me on this device"*), use `AppRadio` from `lib/shared/widgets/inputs/app_radio.dart`:
  - `type: AppRadioType.checkbox` for squared checkboxes.
  - `type: AppRadioType.radio` for circular option groups.
  - Managed by a `SelectionController<T>` with explicit disposal in `dispose()`.

```dart
// ✅ GOOD - AppRadio with SelectionController
AppRadio<String>(
  controller: _rememberMeController,
  type: AppRadioType.checkbox,
  isRow: true,
  optionsList: const [
    AppRadioOption(
      value: 'remember',
      label: 'Keep me signed in on this device',
    ),
  ],
)
```

---

## 18. Local UI State & Performance: ValueNotifier over setState Standard

- **NEVER use `setState()` for local widget state updates**:
  - Calling `setState()` marks the entire `StatefulWidget` dirty and rebuilds its **complete widget subtree**, triggering unnecessary re-evaluations of child widgets, layout passes, and text rendering.
  - In complex dashboards, tables, dialogs, drawers, and forms, frequent `setState()` invocations cause noticeable UI frame drops, mouse lag, and excessive GC pressure.
- **ALWAYS use `ValueNotifier<T>` paired with `ValueListenableBuilder<T>` or `ListenableBuilder`**:
  - For local mutable UI values (active tabs, view modes, fullscreen toggles, hover indices, search text clear toggles, loading flags, accordion expansion states, etc.), declare a `final ValueNotifier<T>` in the widget state.
- **Keep Rebuild Scopes Minimal**:
  - Wrap **ONLY** the specific widget or sub-tree that genuinely depends on the state value inside `ValueListenableBuilder<T>`. Parent layouts, sibling widgets, and static headers stay un-rebuilt.
- **Resource Disposal**:
  - Every `ValueNotifier<T>` declared in a `StatefulWidget` **MUST** be explicitly disposed in `dispose()`.
- **Stateless Sub-Widgets with ValueListenable**:
  - When a sub-component's state derives from an existing listenable (e.g., a clear button in a search bar listening to `TextEditingController`), make the sub-component a `StatelessWidget` and use `ValueListenableBuilder<TextEditingValue>` rather than turning it into a `StatefulWidget` with `addListener` + `setState`.
- **Single Micro-Input Exception**:
  - Only isolated, self-contained micro-inputs (such as `AppTextField` password obscure/hasText toggles) may retain local boolean state. All screen-level, table-level, dialog-level, and panel-level states must use `ValueNotifier`.

```dart
// ✅ GOOD - ValueNotifier with minimal scoped ValueListenableBuilder
class _ProductTableScreenState extends State<ProductTableScreen> {
  final ValueNotifier<int?> _hoveredRowNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<bool> _isSavingNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hoveredRowNotifier.dispose();
    _isSavingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StaticHeaderWidget(), // Static: never rebuilds on row hover or save!
        Expanded(
          child: TableView.builder(
            cellBuilder: (context, vicinity) {
              return MouseRegion(
                onEnter: (_) => _hoveredRowNotifier.value = vicinity.yIndex,
                onExit: (_) => _hoveredRowNotifier.value = null,
                child: ValueListenableBuilder<int?>(
                  valueListenable: _hoveredRowNotifier,
                  builder: (context, hoveredIndex, _) {
                    final isHovered = hoveredIndex == vicinity.yIndex;
                    return Container(color: isHovered ? hoverColor : baseColor);
                  },
                ),
              );
            },
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isSavingNotifier,
          builder: (context, isSaving, _) => AppButton(
            text: 'Save Changes',
            isLoading: isSaving,
            onPressed: isSaving ? null : () => _handleSave(),
          ),
        ),
      ],
    );
  }
}

// ❌ BAD - setState causing the entire screen / table tree to rebuild
class _BadTableState extends State<BadTable> {
  int? _hoveredRow;
  bool _isSaving = false;

  void _onHover(int index) {
    setState(() => _hoveredRow = index); // Rebuilds entire table and header on every mouse movement!
  }

  void _save() {
    setState(() => _isSaving = true); // Rebuilds entire widget tree!
  }
}
```

---

## 19. Asynchronous Error Handling & Service Callback Standard (`asyncHandler`)

- **ALWAYS wrap asynchronous repository methods and database operations in `asyncHandler`**:
  - Import from `/core/utils/callback/async_callback.handler.dart`.
  - `asyncHandler` provides unified translation of Supabase exceptions (`AuthException`, `PostgrestException`, `StorageException`), network socket timeouts (`SocketException`, `TimeoutException`), and generic exceptions into structured `ApiException` objects with localized error messages and automatic `AppLogger.e` logging.
- **In Riverpod AsyncNotifiers, guard async mutations**:
  - Use `AsyncValue.guard(() => asyncHandler(...))` to reliably set `state` and handle errors cleanly in the presentation layer.

```dart
// ✅ GOOD - asyncHandler wrapping asynchronous service logic
Future<List<TruckType>> getTruckTypes() async {
  return asyncHandler(() async {
    final response = await _client.from('truck_types').select();
    return response.map((json) => TruckType.fromJson(json)).toList();
  });
}

// Controller usage with AsyncValue.guard
Future<void> createTruckType(TruckType payload) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(
    () => asyncHandler(() async {
      await _repository.create(payload);
      return _repository.getAll();
    }),
  );
}

// ❌ BAD - Raw try-catch or unhandled async exceptions
Future<List<TruckType>> getTruckTypes() async {
  try {
    final response = await _client.from('truck_types').select();
    return response.map((json) => TruckType.fromJson(json)).toList();
  } catch (e) {
    print(e); // Prohibited
    rethrow;
  }
}
```

---

## 20. Feature Dependency Injection & Riverpod Providers (`di/`)

- Every feature module **MUST** have a dedicated `di/` folder containing `<feature_name>.providers.dart`:
  - `lib/features/<feature>/di/<feature>.providers.dart`
- Structure:
  - Repositories are exposed via `Provider<RepositoryName>` watching dependencies (e.g. `supabaseClientProvider`).
  - Controllers are exposed via `AsyncNotifierProvider<ControllerName, StateType>(ControllerName.new)` or `NotifierProvider`.
- Widgets access controllers via `ref.watch(controllerProvider)` or `ref.read(controllerProvider.notifier)`.

```dart
// ✅ GOOD - lib/features/truck-type/di/truck_type.providers.dart
final truckTypeRepositoryProvider = Provider<TruckTypeRepository>((ref) {
  return TruckTypeRepository(ref.watch(supabaseClientProvider));
});

final truckTypeControllerProvider = AsyncNotifierProvider<
    TruckTypeController, PaginationState<TruckType>>(
  TruckTypeController.new,
);
```

---

## 21. Unified State & Feedback Presentation (`AppStateView`)

- **Empty, Error, Loading, Offline, and Permission views MUST use `AppStateView`**:
  - Located in `lib/shared/widgets/state/app_state_view.dart`.
  - **NEVER** build ad-hoc centered icons or custom empty text columns.
- Supported `AppViewType` values:
  - `AppViewType.empty`: For default blank lists/tables.
  - `AppViewType.noResults`: When search filters return zero results (includes clear filter action).
  - `AppViewType.error`: For API errors or failed network requests (includes retry action).
  - `AppViewType.offline`: When network connectivity is unavailable.
  - `AppViewType.unauthorized`: For insufficient user permissions or roles.
- Supports customizable actions (`onAction`, `actionText`), secondary actions, Lottie animations, and compact rendering.

```dart
// ✅ GOOD - AppStateView for empty or error presentation
if (state.items.isEmpty) {
  return AppStateView(
    type: AppViewType.noResults,
    message: 'No matching records found',
    subtitle: 'Try adjusting your search terms or filters',
    actionText: 'Clear Search',
    onAction: () => _searchController.clear(),
  );
}

// ❌ BAD - Ad-hoc placeholder
Center(
  child: Column(
    children: [
      Icon(Icons.inbox),
      Text('No data available'),
    ],
  ),
)
```

---

## 22. Standardized Pagination Architecture (`PaginationController` & `PaginationState`)

- **Pagination State Model**:
  - Use `PaginationState<T>` from `lib/shared/states/pagination.state.dart` with properties: `items`, `isLoading`, `hasError`, `isLastPage`, `page`, `pageSize`, `totalCount`.
- **Pagination Controller**:
  - Use `PaginationController<T>` from `lib/shared/controllers/pagination.controller.dart`.
  - Extends `ValueNotifier<PaginationState<T>>` with built-in scroll controller listening, threshold auto-fetching (`maxScrollExtent - viewportDimension * 0.2`), and safe disposal.

```dart
// ✅ GOOD - PaginationController usage
final _paginationController = PaginationController<TruckType>(
  onRefresh: () => ref.read(truckTypeControllerProvider.notifier).refresh(),
  onLoadMore: () => ref.read(truckTypeControllerProvider.notifier).loadMore(),
);

@override
void dispose() {
  _paginationController.dispose();
  super.dispose();
}
```

---

## 23. Enterprise Admin Data Table Standard (`AdminTableBuilder`)

- All admin data tables **MUST** be built using `AdminTableBuilder<T>` (`lib/shared/widgets/table/admin_table_builder.dart`).
- Standard features provided:
  - Responsive desktop 2D virtualized spreadsheet (`TableView.builder`) and mobile card list.
  - Type-safe `TableColumn<T>` definitions with dedicated column widths and alignment.
  - Column sorting with `sortState` (`TableSortState`) and animated direction chevrons.
  - Drag-and-drop row reordering (`onReorder`) with reorder handles on desktop & mobile views.
  - Row hover highlights powered by `ValueNotifier<int?>` (avoiding table-wide rebuilds).
  - Checkbox selection & batch actions (`selectionActions`).
  - Search field with clear button (`ValueListenableBuilder<TextEditingValue>`).
  - Pagination pills (`[1] [2] [3] ... [N]`) with row counts (`1 - 10 of 124 entries`).
  - Integrated `AppStateView` for loading, empty, and search miss states.

```dart
// ✅ GOOD - AdminTableBuilder configuration
AdminTableBuilder<TruckType>(
  title: 'Truck Types',
  subtitle: 'Manage all vehicle categories and dimensions',
  tableData: paginatedState.items,
  columns: [
    TableColumn(title: 'Name', width: 220, cellBuilder: (item, index) => Text(item.name)),
    TableColumn(title: 'Capacity', width: 140, cellBuilder: (item, index) => Text('${item.capacity} Tons')),
  ],
  searchController: _searchController,
  currentPage: paginatedState.page,
  totalEntries: paginatedState.totalCount,
  onPageSelected: (page) => controller.getPaginatedRecords(page: page),
)
```

---

## 24. Slide-Over Drawers (`AppSidePanel`) & Document Previews (`AppFilePreview`)

- **Slide-Over Side Drawers**:
  - Use `AppSidePanel` (`lib/shared/widgets/feedbacks/app_side_panel.dart`) for detailed views, edit forms, or creation sidebars.
  - Provides uniform headers, scrolling content containers, and sticky footer action buttons with loading states (`isSaving` powered by `ValueNotifier<bool>`).
- **File & Document Previews**:
  - Use `AppFilePreview` (`lib/shared/widgets/feedbacks/app_file_preview.dart`) for image and PDF previews, thumbnail generation, file size calculation, and download actions.

---


## 25. Screen Provider & Controller Getters Standard (Riverpod Consumer Screens)

- In `ConsumerWidget` or `ConsumerStatefulWidget` screen states, **ALWAYS** declare dedicated `provider` and `controller` getters for primary feature providers/notifiers instead of repeating inline `ref.watch(myProvider)` or `ref.read(myProvider.notifier)` calls throughout handlers and build methods:
  ```dart
  // ✅ GOOD - Standard getters in ConsumerState
  ProviderListenable<AsyncValue<PaginationState<MyModel>>> get provider =>
      myControllerProvider;
  MyController get controller =>
      ref.read(myControllerProvider.notifier);

  // Usage:
  // final asyncState = ref.watch(provider);
  // await controller.getPaginatedRecords();
  ```
- **Benefits & Consistency**:
  - Keeps event callbacks (`_onSave()`, `_onDelete()`, table pagination callbacks, search actions) concise, clean, and DRY.
  - Standardizes `ref.listen(provider, ...)` for error/success snackbars and side effects.
  - Simplifies screens with parameterized family providers (e.g. `usersControllerProvider((role: role, status: status))`).

---

## 26. Base Repository Pattern (`BaseRepository<T>` & `BaseSupabaseRepository<T>`)

- All feature repositories **MUST** implement `BaseRepository<T>` by extending `BaseSupabaseRepository<T>` (`lib/core/repositories/base.repository.dart`).
- **Capabilities Provided**:
  - Generic CRUD operations (`getPaginated`, `getDetails`, `addOrUpdate`, `delete`).
  - Standardized exact count pagination with range queries.
  - Multi-column `ilike` search matching across fields.
  - Automatic `id` stripping on updates/inserts.
  - Centralized `ApiException` wrapping on database failures.
  ```dart
  // ✅ GOOD - Standard Repository inheriting from BaseSupabaseRepository
  final class TruckTypeRepository extends BaseSupabaseRepository<TruckType> {
    TruckTypeRepository(SupabaseClient client)
        : super(
            client: client,
            tableName: DatabaseTables.truckTypes,
            fromJson: TruckType.fromJson,
            entityName: 'truck type',
          );
  }
  ```

---

## 27. Centralized JSON & Database Column Keys (`JsonKeys`)

- **NEVER** use hardcoded field strings like `'name_hi'`, `'is_active'`, `'created_at'`, `'sort_order'`, `'image_url'`, `'description_hi'`, `'applies_to'`, `'question_hi'`, `'answer_hi'`, etc. anywhere in repositories, controllers, or form payloads.
- **Centralized Definition**:
  - All database column names and API payload keys for raw queries, sorting, and update payloads **MUST** be defined and referenced via `JsonKeys.<key>` in `lib/core/constants/api/json_keys.dart`.
  - **Data Models Exemption**: Data models with `@freezed` / `@JsonSerializable` are exempt from `JsonKeys` because `build.yaml` has `field_rename: snake` globally configured.
  ```dart
  // ❌ BAD - Hardcoded string literals
  query.eq('is_active', isActive);
  payload['name_hi'] = nameHi;

  // ✅ GOOD - Centralized JsonKeys constant
  query.eq(JsonKeys.isActive, isActive);
  payload[JsonKeys.nameHi] = nameHi;
  ```

---

## 28. Feature Scaffolding with Mason Bricks (`mason.yaml` & `bricks/feature`)

- All new features **MUST** be scaffolded using the project's standardized Mason brick template located in `bricks/feature`:
  ```bash
  # Generate a complete enterprise feature slice
  mason make feature --feature_name <feature_name> --entity_name "<entity display name>" --table_name <tableProperty>

  # Example:
  mason make feature --feature_name vehicle_brand --entity_name "vehicle brand" --table_name vehicleBrands
  ```
- **Scaffolded Layer Structure**:
  - `data/models/<feature_name>.model.dart` (Freezed + JSON serialization model)
  - `data/repositories/<feature_name>.repository.dart` (Extends `BaseSupabaseRepository<T>`)
  - `di/<feature_name>.providers.dart` (Riverpod Repository & AutoDispose Controller Providers)
  - `presentation/controllers/<feature_name>.controller.dart` (Pagination state async notifier with standard CRUD)
  - `presentation/screens/<feature_name>_management.screen.dart` (Enterprise Data Table screen adhering to Section 25)
  - `presentation/screens/<feature_name>.form.dart` (Enterprise Slide-in Form drawer adhering to Section 25)

---

## 29. Optimistic Instant UI Updates & Non-Blocking Background Operations

- All interactive row actions (e.g., status toggling, row reordering, inline verification/blocking) **MUST** update local state optimistically before issuing API requests to provide zero-latency user feedback.
- **Controller Implementation Pattern**:
  1. Update local list state immediately using list extensions (e.g. `current.items.updateItem(id: id, item: updatedItem)` or `previousItems.reorderWithSortOrder(...)`).
  2. Emit local state update: `state = AsyncData(current.copyWith(items: updated));`.
  3. Invoke background repository update with `loading: false`:
     ```dart
     return updateRecord({JsonKeys.isActive: isActive}, id, loading: false);
     ```
- **Non-Blocking `updateRecord` Standard**:
  In feature controllers, `updateRecord` MUST condition `state = result;` on `if (loading)`. When `loading: false` is passed, the network call executes silently without showing full-screen/table loaders or undoing optimistic local state updates:
  ```dart
  Future<void> updateRecord(
    Map<String, dynamic> data,
    String id, {
    bool loading = true,
  }) async {
    final current = state.value;
    if (loading) {
      state = const AsyncLoading();
    }

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final updated = await _repository.addOrUpdate(data, id: id);
        final currentItems = current?.items ?? [];
        final updatedItems = currentItems.map((item) {
          return item.id == id ? updated : item;
        }).toList();

        return (current ?? const PaginationState<T>()).copyWith(
          items: updatedItems,
        );
      }),
    );
    if (loading) {
      state = result;
    }
  }
  ```

---

## 30. Drag-and-Drop Row Reordering Standard (`ListReorderExtension` & `AppConstants.sortOrderGap`)

- **Table Configuration**:
  - Enable drag-and-drop in any admin table by providing `onReorder` to `AdminTableBuilder`:
  ```dart
  AdminTableBuilder<TruckType>(
    // ...
    onReorder: (oldIndex, newIndex) async {
      controller.reorderRecords(
        paginationState.items[oldIndex].id,
        oldIndex,
        newIndex,
      );
    },
  )
  ```
- **List Extension Utility (`ListReorderExtension`)**:
  - Reordering logic and intermediate sort order calculations **MUST** use `ListReorderExtension.reorderWithSortOrder(...)` from `lib/core/extensions/list.extension.dart`.
  ```dart
  Future<void> reorderRecords(String id, int oldIndex, int newIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    final previousItems = currentState.items;
    final result = previousItems.reorderWithSortOrder(
      oldIndex: oldIndex,
      newIndex: newIndex,
      getSortOrder: (item) => item.sortOrder,
      copyWithSortOrder: (item, newSortOrder) =>
          item.copyWith(sortOrder: newSortOrder),
    );

    if (result == null) return;

    state = AsyncData(currentState.copyWith(items: result.items));

    updateRecord(
      {JsonKeys.sortOrder: result.reorderedItem.sortOrder},
      id,
      loading: false,
    );
  }
  ```
- **Form Sort Order Default**:
  - Forms for entities supporting display ordering **MUST** default new record sort order using `AppConstants.sortOrderGap` (1000):
  ```dart
  JsonKeys.sortOrder: widget.item?.sortOrder ?? AppConstants.sortOrderGap,
  ```

---

## 31. Core vs Shared Architecture & File Placement Standard

To prevent structural entropy and confusing orphan directories, strictly adhere to the **Core vs Shared Boundary Rule**:

### A. The Core Boundary (`lib/core/` = Foundation & Infrastructure)
- **NO UI widgets or presentation controllers belong in `core/`**.
- **Foundations**:
  - `config/`: App environments (`dev.config.dart`, `prod.config.dart`, `staging.config.dart`).
  - `constants/`: Design tokens (`app_spacing.dart`, `app_radius.dart`, `app_strings.dart`, `app_durations.dart`, `app_regx.dart`) and backend database contracts in `constants/api/` (`database_tables.dart`, `json_keys.dart`, `api_endpoints.dart`, `storage_buckets.dart`).
  - `enums/`: App-wide cross-cutting enums (e.g. `language.enum.dart`).
  - `error/`: Universal error models (`api_exception.dart`, `error_code_parser.dart`).
  - `extensions/`: Dart & Flutter utility extensions.
  - `logger/`: `app_logger.dart`.
  - `network/`: `api_client.dart`.
  - `providers/`: Low-level infrastructure providers (`supabase.provider.dart`, `internet_connectivity`, `permission`).
  - `repositories/`: Foundation contracts (`base.repository.dart`).
  - `services/`: **ALL device, OS, platform, hardware, and file services**:
    - `connectivity/`: Internet connectivity status & monitoring.
    - `file_storage/`: Supabase cloud storage file uploads and downloads.
    - `launcher/`: `AppLauncher` (system URL, email, phone, SMS, WhatsApp, Google Maps, file opening).
    - `local_storage/`: Secure storage and local key-value preferences.
    - `media/`: `MediaPickerService` (camera/gallery image & video picking, document picking, cropping).
    - `permission/`: Device hardware permissions.
  - `utils/`: Universal utilities (async handlers, JSON converters, validators, pagination math).

### B. The Shared Boundary (`lib/shared/` = Reusable UI & Presentation)
- **Shared contains ONLY reusable presentation components and UI states**.
- **There is NO `shared/services/`**: Hardware and OS services belong in `core/services/`.
- **There is NO top-level `shared/models/` or `shared/enums/`**:
  - Do NOT create orphan top-level folders for single 10-line models.
  - **Widget-Scoped Models**: Models configuring a specific UI component MUST be co-located with that component (e.g., `widgets/dashboard/models/dashboard_stats_models.dart`, `widgets/admin_layout/models.dart`, `widgets/table/table_models.dart`).
  - **Selection Models**: `SelectableItem<V, D>` is co-located directly inside `lib/shared/controllers/selection.controller.dart` where `SelectionController` lives.
- **Shared Folder Structure**:
  ```text
  lib/shared/
  ├── controllers/      # Reusable UI controllers (SelectionController & SelectableItem, PaginationController)
  ├── states/           # Reusable UI states (PaginationState, ApiState)
  └── widgets/          # Component-first UI widgets (each with its own co-located models/painters)
      ├── admin_layout/ # Sidebar, header, navigation panel & models.dart
      ├── buttons/      # AppButton, BackButton
      ├── connectivity/ # InternetConnectivityWidget
      ├── dashboard/    # Charts, switchers, filters & dashboard_stats_models.dart
      ├── editor/       # Rich content editor
      ├── feedbacks/    # AppDialog, AppSnackbar, AppSheet, AppPopup, AppFilePreview, FeedbackService
      ├── inputs/       # AppTextField, AppDropdown, AppRadio, AppSelectableChip
      ├── misc/         # AppChip, AppRichText, AppShowMoreText
      ├── navigation/   # AppTabBar
      ├── pagination/   # AppPagination
      ├── permission/   # PermissionDialogs
      ├── sections/     # AppAppbar, AppImage, InfoBanner
      ├── selection/    # AppSelectable
      ├── state/        # AppStateView
      └── table/        # AdminTableBuilder, views, and table_models.dart
  ```

---

## 32. Prohibition of "Master Data" Dumping Grounds & Anti-Orphan Domain Rule

To preserve architecture integrity, prevent spaghetti dependencies, and stop junior developers and AI agents from creating monolithic dumping grounds:

### A. Absolute Prohibition on Generic Grab-Bag Folders
- **NEVER** create any folder named `master_data`, `common_data`, `shared_data`, `helpers`, `misc`, or `utilities` inside `lib/core/`, `lib/shared/`, or `lib/features/`.
- Dumping unrelated entities (e.g. `BusinessType`, `MaterialType`, `TruckType`, `DocumentType`) into a single `master_data` folder is **STRICTLY FORBIDDEN**.

### B. Feature Encapsulation for Domain Entities
- All domain concepts—even reference catalogs, dropdown datasets, and lookup entities—are first-class feature domains.
- Place them inside their dedicated modular feature directories under `lib/features/common/<domain_name>/`:
  - Business Types: `lib/features/common/business-type/`
  - Material Types: `lib/features/common/material-type/`
  - Truck Types & Truck Body Types: `lib/features/common/truck-type/`
  - Document Types: `lib/features/common/document-type/`
  - Locations & Phone Codes: `lib/features/common/location-and-phone-code/`

### C. Standard Modular Feature Structure for Reference Domains
Each reference domain module must follow clean architecture:
```text
lib/features/common/<domain_name>/
├── data/
│   ├── models/            # Freezed data models (e.g. business_type.model.dart)
│   └── repositories/      # Supabase repository implementation extending BaseSupabaseRepository
├── di/
│   └── <domain>.providers.dart  # Repository & AsyncNotifier providers
├── controller/            # AsyncNotifier controller (for CRUD, cached lookups, filters)
└── presentation/
    └── widgets/           # Specialized picker/sheet widgets (e.g. business_type_picker.widget.dart)
```

---

## 33. Enterprise Domain Modeling & Future-Proof Entities (Anti-Raw Strings Rule)

All domain models and entity representations must be engineered for long-term maintainability, type-safety, and future extensibility.

### A. Zero Raw Strings / Magic Numbers for Domain States
- **NEVER** store domain statuses, roles, types, categories, or volumes as bare `String` or `int` in models (e.g. `UserModel`, `OrderModel`, `TripModel`).
- Raw values like `'BUYER_SELLER'`, `'ADMIN'`, `'PENDING'`, `'VERIFIED'` **MUST** be backed by strongly-typed Dart enums.

### B. Rich Type-Safe Enum Pattern (`lib/features/<feature>/data/enums/<name>.enum.dart`)
Every enum must be self-describing, serializable, and provide UI presentation helpers:
```dart
// ✅ GOOD - Rich, localized, type-safe enum
enum UserRoleType {
  @JsonValue('ADMIN')
  admin('ADMIN'),

  @JsonValue('BUYER_SELLER')
  buyerSeller('BUYER_SELLER'),

  @JsonValue('TRANSPORTER_TRUCK_OWNER')
  transporterTruckOwner('TRANSPORTER_TRUCK_OWNER'),

  @JsonValue('DRIVER')
  driver('DRIVER');

  final String apiValue;
  const UserRoleType(this.apiValue);

  String label(AppLocalizations l10n) {
    switch (this) {
      case UserRoleType.admin:
        return 'Admin';
      case UserRoleType.buyerSeller:
        return l10n.roleBuyerSeller;
      case UserRoleType.transporterTruckOwner:
        return l10n.roleTransporterTruckOwner;
      case UserRoleType.driver:
        return l10n.roleDriver;
    }
  }

  SvgGenImage get svg => ...;
  IconData get icon => ...;
  Color color(BuildContext context) => ...;
}
```

### C. Future-Proof Freezed Models & Composite Nested Relations
- **Resilient Deserialization**: For all enum fields in `@freezed` models, always add `@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)` so that new backend enum values never crash older app builds:
  ```dart
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  DealType? dealType,
  ```
- **Composite Nested Relations**: Parent models (like `UserModel`) must hold structured, joined relation entities rather than only flat IDs:
  ```dart
  // ✅ GOOD - Joined relation models populated on fetch
  BusinessType? businessTypeData,
  List<MaterialType>? materialTypes,
  List<UserBankDetailModel>? bankDetails,
  List<UserDocumentModel>? documents,
  List<UserTruckModel>? trucks,
  ```
- **Computed Model Getters**: Encapsulate presentation formatting in getters on the model (e.g. `user.stateModel`, `user.cityModel`, `user.address`) rather than repeatedly writing formatting logic inside UI widgets.
- **Contract Standardization**: All database column mappings in serialization **MUST** reference `JsonKeys` (e.g. `@JsonKey(name: JsonKeys.addressLine1)`).

---

## 34. Authentication & Buyer/Seller Multi-Step Signup Flow Architecture

Multi-step onboarding and registration flows (such as `BuyerSignupScreen` and `TransporterSignupScreen`) must strictly adhere to the following lifecycle and state persistence standards:

### A. Form Step Widget Encapsulation
- Step widgets (e.g. `BuyerSignupStep1..5`, `TransportSignupStep1..5`) **MUST** instantiate and manage their own input controllers (`TextEditingController`, `SelectionController`, `ValueNotifier`) inside their widget `State`.
- **Constructor Purity**: Never pass external `TextEditingController`s from the parent screen into child step widgets.
- **Lifecycle Management**: Every internally instantiated controller and listener **MUST** be explicitly disposed in `dispose()`.

### B. Strongly-Typed Callback Signatures
- Step widgets must communicate forward through strongly-typed callbacks rather than untyped maps:
  ```dart
  // ✅ GOOD
  final void Function(
    String addressLine1,
    String? addressLine2,
    int stateId,
    String state,
    int cityId,
    String city,
    String pincode,
  ) onNext;

  // ❌ BAD
  final void Function(Map<String, dynamic> data) onNext;
  ```

### C. Immediate Step-by-Step State Persistence
- Upon each step's validation success, the parent screen **MUST** immediately persist progress to Supabase via `authController.updateUser({...})` (or `createUser({...})`) using `JsonKeys`:
  ```dart
  await controller.updateUser({
    JsonKeys.addressLine1: addressLine1,
    JsonKeys.addressLine2: addressLine2,
    JsonKeys.state: stateId,
    JsonKeys.city: cityId,
    JsonKeys.pincode: pincode,
  });
  ```
- This ensures that if the user backgrounds or leaves the app, their progress is permanently preserved in the database.
- Transition between steps by handling controller outcomes:
  ```dart
  ref.read(authControllerProvider).handleResult(
    onSuccess: (value) async {
      _nextPage();
    },
  );
  ```

---

## 35. Controller, Repository & DI Layer Separation (No Raw Supabase in UI)

Strict boundaries between Presentation, Business Logic, and Data layers must be maintained without exception:

### A. Presentation Layer (Screens & Widgets)
- Screens and widgets observe state via `ref.watch(provider)` and dispatch user actions via `ref.read(provider.notifier).methodName()`.
- **STRICT PROHIBITION**: **NEVER import `package:supabase_flutter` inside presentation screens or widgets.** Never invoke `Supabase.instance.client.from(...)` in UI.

### B. Controller Layer (`lib/features/<feature>/presentation/controller/`)
- Controllers extend `AsyncNotifier<T>` or `Notifier<T>`.
- Controllers contain business logic, coordinate API calls via repositories, update UI state, and manage error feedback.
- Controllers **MUST NOT** execute direct SQL or table queries; all data operations must delegate to the repository.
- Use `AsyncValue.guard` or `asyncHandler` with `AppLogger` for robust error capture.

### C. Repository Layer (`lib/features/<feature>/data/repositories/`)
- Repositories encapsulate database queries, network calls, and deserialization.
- Standard feature entities must extend `BaseSupabaseRepository<T>`.
- Auth and specialized repositories wrap `SupabaseClient` or `GoTrueClient` through `asyncHandler`.
- Repositories must catch network/Postgrest exceptions and rethrow typed `ApiException` or domain `Failure`.

### D. Dependency Injection Layer (`lib/features/<feature>/di/<feature>.providers.dart`)
- Every feature module must centralize its Riverpod providers inside a dedicated `di/` folder (e.g. `auth.provider.dart`, `document.providers.dart`).
- Adhere to the standard provider hierarchy:
  1. **Infrastructure Providers**: Accessed from `core/providers/supabase/supabase.provider.dart`.
  2. **Repository Providers**: `final nameRepositoryProvider = Provider<NameRepository>((ref) => ...);`
  3. **Controller Providers**: `final nameControllerProvider = AsyncNotifierProvider<NameController, State>(() => NameController());`
  4. **Derived Selectors & Stream Providers**: `final streamProvider = StreamProvider<T>((ref) => ...);`
- **NEVER** declare global Riverpod providers inside screen or widget files.

---

## 36. AI Agent Guardrails, Zero-Assumption Policy & Escalation Protocol

All AI coding assistants working in this repository **MUST** adhere to these operational directives:

### A. The Ask-When-Stuck Rule (Zero Assumptions)
- When a requirement, database schema, or design spec is ambiguous, underspecified, or conflicting, the AI **MUST NOT** guess, invent ad-hoc directories, or make up column names.
- The AI **MUST STOP and ASK the user for clarification** using clear multiple-choice or direct questions before modifying code.

### B. The Anti-Hallucination & Architecture Verification Rule
- Before creating a new model, enum, service, or repository, the AI **MUST inspect existing code** in `lib/core/` and `lib/features/auth/` to discover existing patterns.
- Do NOT invent parallel or duplicate abstractions (e.g. do NOT use raw Flutter `Radio` when `AppRadio` exists; do NOT use `Color(0xFF...)` when `context.colors` exists; do NOT use `SizedBox(height: 16)` when `AppSpacing.lg.h` exists).

### C. Verification Checklist Before Answering
Before concluding any task, the AI **MUST**:
1. Run `flutter analyze` and resolve all new warnings and errors.
2. Run `dart run build_runner build --delete-conflicting-outputs` whenever models or code-generation annotations change.
3. Verify that all internally created controllers and listeners have explicit `dispose()` calls.
4. Ensure zero `print()`, `debugPrint()`, empty catch blocks, or temporary placeholder comments.

---

## 37. Detail Screens & Single Source of Truth via Foreign Key Joins Standard

When building entity detail views (such as `OrderDetailsScreen`, `TripDetailsScreen`), backend tables frequently maintain denormalized convenience snapshots (e.g. `driver_name`, `driver_contact`, `transporter_name`, `vehicle_number`, `material_name` in `trips`).

### Mandatory Directives:
1. **Never Rely Solely on Denormalized Snapshots in Detail Views**:
   - Denormalized table columns are strictly for high-throughput table indexing, list summaries, or fallback when references are nullified.
   - For all detail screens, **ALWAYS query and join master records by their foreign key ID** (`driver_id`, `transporter_id`, `user_id`, `truck_id`, `material_type_id`, `unit_id`, `order_id`).
2. **Master Record as Source of Truth**:
   - Detail views must display real-time master information (e.g., driver's live verification status and registered phone, transporter's full profile, vehicle's verified capacity and documents, material type specifications).
   - Use denormalized table columns strictly as fallbacks if the foreign entity is unassigned or has been deleted (`on delete set null`).
3. **Repository PostgREST Join Pattern**:
   - In `getDetails(id)`, explicitly join relations using foreign key relation aliases:
     ```dart
     const String tripJoinedSelect = '''
       *,
       driver:users!trips_driver_id_fkey(*),
       transporter:users!trips_transporter_id_fkey(*),
       user:users!trips_user_id_fkey(*),
       truck:trucks(*),
       material_type:material_types(*),
       unit_type:unit_types(*),
       order:orders(*)
     ''';
     ```
4. **Interactive Navigation from Detail Views**:
   - When viewing joined entities (such as Driver, Transporter, Order, or Vehicle), provide clickable redirects to open their respective detail sidebar/screens (e.g. `UserDetailsScreen.showAsSidebar(context: context, userId: trip.driverId!)`), enabling seamless cross-module audit and verification.

