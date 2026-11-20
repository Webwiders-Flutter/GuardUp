# GuardUp Development Rules & Architectural Guidelines

This document outlines the fundamental development principles, architectural patterns, and coding standards for the GuardUp Flutter codebase.

---

## 1. State Management: ValueNotifier over setState
- Prefer `ValueNotifier<T>` with `ValueListenableBuilder<T>` (or specialized controllers like `SelectionController<T>`) over full-widget `setState()`.
- Keeps rebuild scopes minimal, isolated, and performant without triggering unnecessary full-tree widget rebuilds.
- For feature-level asynchronous business logic, continue using `Bloc` / `Cubit` via `flutter_bloc`.

```dart
// Preferred: Isolated rebuild using ValueNotifier
final ValueNotifier<bool> isPressedNotifier = ValueNotifier<bool>(false);

ValueListenableBuilder<bool>(
  valueListenable: isPressedNotifier,
  builder: (context, isPressed, child) {
    return AnimatedScale(
      scale: isPressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: child,
    );
  },
  child: const MyStaticChild(),
);
```

---

## 2. Utilize Prebuilt & Custom Components
- Always reuse and build upon existing shared components instead of creating ad-hoc duplicate implementations or using raw Flutter primitives:
  - **Typography & Rich Text**: `AppRichText` (with `AppTextSpan`) - **NEVER use raw `RichText`**.
  - **Buttons**: `AppButton` (supports sizes, variants, loading states, custom borders, gradients, and box shadows).
  - **Inputs & Fields**: `AppTextField`, `AppFieldLabel`, `DocumentUploadCard`, `AppMediaPickerSheet`.
  - **Feedback & Overlays**: `AppSnackbar`, `AppSheet`, `AppPopup`, `AppDialog`, `AppFilePreviewSheet`.
  - **Navigation**: `AppAppBar`, `AppTabBar`, `AppTabView`.
  - **Selection**: `SelectionController`, `AppSelectableCard`, `AppSelectableChip`, `PlanSelectionCard`.
  - **Images & Icons**: `AppImage`, `Assets.svg.*.svg(...)`.

---

## 3. Theme, Colors & Typography: Always Use Context Extensions
- Never hardcode raw hex colors or access `Theme.of(context)` directly for colors and text styles.
- Always use the centralized extensions:
  - **Colors**: `context.colors.*` (`context.colors.primary`, `context.colors.surfaceContainer`, `context.colors.outlineVariant`, etc.).
  - **Typography**: `context.textTheme.*` combined with style extensions (`.bold()`, `.semiBold()`, `.medium()`, `.colour(...)`, `.size(...)`, `.decreaseSize(...)`).

```dart
// Preferred
Text(
  'Section Header',
  style: context.textTheme.titleMedium?.bold().colour(context.colors.onSurface),
)
```

---

## 4. Design Tokens & Extension Synergy
- Always use semantic design tokens instead of magic numbers:
  - **Spacing**: `AppSpacing.*` (`xs`, `sm`, `md`, `lg`, `xl`, `xxl`, `huge`, `massive`).
  - **Corner Radius**: `AppRadius.*` (`sm`, `md`, `lg`, `xl`, `xxl`, `round`, `full`).
  - **Durations**: `AppDurations.*` (`fast`, `normal`, `medium`, `slow`).
  - **Sizes**: `AppSizes.*`.
- Combine tokens with spacing extensions for clean, readable layout code:
  - `AppSpacing.md.h` (vertical SizedBox)
  - `AppSpacing.sm.w` (horizontal SizedBox)
  - `AppSpacing.lg.allPadding` (EdgeInsets.all)
  - `context.horizontalEdgeInsets` (standard screen horizontal insets)
  - `AppRadius.md.toBorderRadius`

---

## 5. Responsive Dimensions: MediaQuery Extensions
- For dynamic dimensions relative to screen size, use the `BuildContext` and `num` extensions:
  - `context.height` and `context.width`
  - `context.horizontalScreenPadding`
  - Responsive percentage helpers: `32.wPercent(context)`, `20.hPercent(context)`
  - `context.systemPadding`

---

## 6. Screen Layout Structure & IntrinsicHeight Precautions

### A. Fixed Form & Onboarding Screens (Spacer + IntrinsicHeight)
Use the `LayoutBuilder + ConstrainedBox + IntrinsicHeight + Spacer()` pattern **ONLY** for static forms, authentication, and fixed-item selection screens (e.g. Login, Signup, Forgot Password, Change Password, Upload Documents, Membership Plans):
- It pins the primary bottom button (`AppButton`) to the bottom of the viewport on tall displays.
- It smoothly becomes scrollable without keyboard overflow when the keyboard appears or on smaller viewports.

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    
    appBar: AppAppBar.transparent(
      title: 'Screen Title', // or titleWidget
      showBackIcon: true,
      centerTitle: true,
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: context.horizontalEdgeInsets,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSpacing.lg.h,

                    // Static screen content...

                    const Spacer(),
                    AppSpacing.lg.h,

                    // Bottom Primary Action Button
                    AppButton(
                      text: 'Continue',
                      
                      onPressed: _handleContinue,
                    ),
                    AppSpacing.xl.h,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
```

### ⚠️ CRITICAL PRECAUTION: Do NOT Blindly Use IntrinsicHeight
> **Never wrap dynamic lists, pagination, or shrink-wrapping viewports in `IntrinsicHeight`:**
> 1. **No `ListView(shrinkWrap: true)` inside `IntrinsicHeight`**: Flutter will throw `RenderShrinkWrappingViewport does not support returning intrinsic dimensions`. If you have a small fixed list inside an IntrinsicHeight layout (e.g. 3 membership plans), use a plain `Column` with a `for` loop (`for (final item in items)`) instead of `ListView`.
> 2. **Breaks Lazy Virtualization**: `IntrinsicHeight` performs a speculative layout pass forcing every descendant to be pre-measured. This destroys `ListView.builder` and `AppPagination` lazy-loading, forcing off-screen items into memory all at once.
> 3. **Severe Frame Drops & Layout Errors**: When dynamic or paginated lists grow, calculating the intrinsic height of every component causes heavy CPU spikes, frame stuttering, and unbounded height assertion failures.

### B. Dynamic Lists, Paginated Feeds, & Content Screens
For screens displaying lists, paginated feeds (`AppPagination`), or variable dynamic content:
- **Paginated / Full Lists**: Use a `Column` with `Expanded(child: AppPagination<T>(...))` or `Expanded(child: ListView.separated(...))`.
- **Mixed Content + List**: Use `CustomScrollView` with slivers (`SliverToBoxAdapter` for headers/controls and `SliverList` for lazy-loaded items).
- **Simple Dynamic Forms without Sticky Spacers**: Use a direct `SingleChildScrollView(padding: context.horizontalEdgeInsets, child: Column(...))` without `IntrinsicHeight`.

---

## 7. Professional, Flexible, & Scalable Code Quality
- **Feature-First Architecture**: Group related components, models, blocs, and screens within `lib/features/<feature_name>/` (e.g. `auth`, `legal`, `payments`).
- **Clean Barrels**: Export public models, screens, and widgets in `<feature_name>.dart`.
- **Localization**: Never hardcode user-facing strings; add keys to `app_en.arb` and `app_ar.arb` and access via `context.l10n.*`.
- **Screen-Owned Routes**: Every screen declares its own path (`static const route = '/my-wallet';`, or several named constants such as `LegalContentScreen.termsRoute`). Navigate with `context.push(MyWalletScreen.route)` and register the same constant in `app_router.dart`. There is no central `AppRoutes` file; never hardcode path strings.
- **Null-Safety & Immutability**: Prefer `final` and `const` constructors wherever possible.
- **Dumb Presentation vs Business Logic**: Keep presentation widgets modular and composable. Delegate state transitions to controllers (`SelectionController`) or BLoCs.

---

## 8. Lightweight Structured Arguments: Record Typedefs with Named Parameters
- For small, lightweight structured arguments, route DTOs, or styling configurations, **always prefer Dart 3 record typedefs with named fields over full boilerplate classes**:
  - Eliminates verbose constructors, field declarations, and boilerplate.
  - Type-safe, immutable, and easy to pass across navigation `extra` or helper builders.

```dart
// Preferred: Clean named record typedef
typedef MembershipPlanArgs = ({
  MembershipPlanMode? mode,
  double? bookingAmount,
  String? operativeName,
  String? activePlanId,
});

// Usage in routing / navigation:
context.push(
  MembershipPlansScreen.route,
  extra: (
    mode: MembershipPlanMode.booking,
    bookingAmount: 240.0,
    operativeName: 'Operative Vikram Singh',
    activePlanId: 'gold_sentinel',
  ),
);
```

> [!WARNING]
> **Dart Record Literal Shape Matching**: In Dart 3, named record fields are structural, not optional parameters. If a typedef defines fields (e.g. `({String? a, String? b})`), any record literal cast to that typedef must provide all named fields (even if set to `null`). If optional parameters are needed across navigation where callers supply different subsets of fields, use a lightweight immutable class with a `const` constructor instead of a record typedef to prevent runtime `_TypeError` cast exceptions.


