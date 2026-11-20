/// Structural layout tokens for the admin console chrome (shell, sidebar,
/// top bar, page body, tables and icons).
///
/// [AppSpacing] and [AppRadius] cover gaps and corners; this class holds the
/// fixed component dimensions and responsive breakpoints so they are defined
/// once instead of being re-derived with token arithmetic in every widget.
final class AppLayout {
  AppLayout._();

  // ── Breakpoints (width of the shell viewport) ──────────────────────────────

  /// Below this width the sidebar moves into a slide-in drawer.
  static const double compactBreakpoint = 768;

  /// At or above this width the sidebar is expanded by default; between
  /// [compactBreakpoint] and this value it starts as an icon rail.
  static const double expandedBreakpoint = 1200;

  /// Below this width (of the table itself) rows render as cards.
  static const double tableCardBreakpoint = 640;

  // ── Shell chrome ───────────────────────────────────────────────────────────

  static const double topBarHeight = 64;
  static const double sidebarWidth = 264;
  static const double sidebarMinWidth = 224;
  static const double sidebarMaxWidth = 360;
  static const double sidebarRailWidth = 72;
  static const double drawerWidth = 288;
  static const double sidebarResizeHandleWidth = 8;

  /// Height of a top-level navigation row in the sidebar.
  static const double navItemHeight = 40;

  /// Height of a nested navigation row in the sidebar.
  static const double navSubItemHeight = 34;

  // ── Controls ───────────────────────────────────────────────────────────────

  /// Standard height for buttons, search fields and selectors in bars.
  static const double controlHeight = 36;

  /// Compact control height (dense toolbars, pagination pills).
  static const double controlHeightSm = 32;

  /// Width of the quick-search trigger in the top bar.
  static const double searchTriggerWidth = 280;

  /// Width of the search field in a table top bar.
  static const double tableSearchWidth = 260;

  // ── Tables ─────────────────────────────────────────────────────────────────

  static const double tableHeaderHeight = 44;
  static const double tableRowHeight = 52;
  static const double tableCheckboxColumnWidth = 48;
  static const double tableDragHandleWidth = 44;

  /// Flex columns never shrink below this width; the table scrolls instead.
  static const double tableMinFlexColumnWidth = 140;

  // ── Overlays ───────────────────────────────────────────────────────────────

  static const double commandPaletteWidth = 600;
  static const double commandPaletteHeight = 460;
  static const double commandPaletteItemHeight = 52;
  static const double menuItemHeight = 40;

  // ── Icons ──────────────────────────────────────────────────────────────────

  static const double iconXs = 14;
  static const double iconSm = 16;
  static const double iconMd = 18;
  static const double iconLg = 20;
  static const double iconXl = 24;

  // ── Avatars & marks ────────────────────────────────────────────────────────

  static const double avatarSm = 28;
  static const double avatarMd = 36;
  static const double brandMarkSize = 32;
}
