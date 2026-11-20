import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardup_admin/app/routes/admin_navigation.dart';
import 'package:guardup_admin/app/theme/app_theme.dart';
import 'package:guardup_admin/features/dashboard/presentation/screens/dashboard.screen.dart';
import 'package:guardup_admin/features/users/data/enums/user_role.enum.dart';
import 'package:guardup_admin/features/users/data/enums/user_status.enum.dart';
import 'package:guardup_admin/features/users/presentation/screens/user_details.screen.dart';
import 'package:guardup_admin/features/users/presentation/screens/users_management.screen.dart';
import 'package:guardup_admin/gen/app_localizations.dart';
import 'package:guardup_admin/shared/widgets/admin_layout/admin_command_palette.dart';
import 'package:guardup_admin/shared/widgets/admin_layout/admin_page_body.dart';
import 'package:guardup_admin/shared/widgets/admin_layout/admin_scaffold.dart';
import 'package:guardup_admin/shared/widgets/admin_layout/models.dart';
import 'package:guardup_admin/shared/widgets/table/admin_table_builder.dart';
import 'package:guardup_admin/shared/widgets/table/table_models.dart';

/// Renders the admin frame and data table at each breakpoint and in each
/// table state, failing on any layout exception (overflow, unbounded
/// constraints, missing Material, ...).

typedef _Row = ({String id, String name, bool isActive});

const _rows = <_Row>[
  (id: '1', name: 'Close protection', isActive: true),
  (id: '2', name: 'Event security', isActive: false),
  (id: '3', name: 'Residential detail', isActive: true),
];

final _sections = <AdminNavSection>[
  (
    title: null,
    items: const [
      AdminNavItem(
        icon: Icons.space_dashboard_outlined,
        label: 'Dashboard',
        route: '/home',
        matchPrefix: false,
      ),
    ],
  ),
  (
    title: 'Users',
    items: const [
      AdminNavItem(
        icon: Icons.security_outlined,
        label: 'Bodyguards',
        route: '/guards',
        children: [
          AdminNavItem(
            icon: Icons.pending_actions_outlined,
            label: 'Pending',
            route: '/guards/pending',
            badgeCount: 4,
          ),
          AdminNavItem(
            icon: Icons.verified_user_outlined,
            label: 'Approved',
            route: '/guards/approved',
          ),
        ],
      ),
    ],
  ),
];

List<TableColumn<_Row>> _columns() => [
  TableColumn<_Row>(
    title: '#',
    width: 56,
    cellBuilder: (_, index) => Text('${index + 1}'),
  ),
  TableColumn<_Row>(
    title: 'Name',
    flex: 3,
    alignment: Alignment.centerLeft,
    sortable: true,
    key: 'name',
    cellBuilder: (row, _) => Text(row.name),
  ),
  TableColumn<_Row>(
    title: 'Status',
    width: 120,
    cellBuilder: (row, _) => Text(row.isActive ? 'Active' : 'Inactive'),
  ),
  TableColumn<_Row>(
    title: 'Actions',
    width: 120,
    cellBuilder: (_, _) =>
        IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
  ),
];

Widget _table({
  List<_Row> data = _rows,
  bool load = false,
  Future<void> Function(int, int)? onReorder,
}) {
  return AdminTableBuilder<_Row>(
    title: 'Protection Services',
    subtitle: 'Catalog of services',
    columns: _columns(),
    tableData: data,
    searchController: TextEditingController(),
    showSearchField: true,
    showCheckbox: true,
    itemKey: (row) => row.id,
    currentPage: 1,
    totalEntries: data.length,
    load: load,
    filterChips: const [
      (label: 'All', value: null),
      (label: 'Active', value: true),
    ],
    onRefresh: () async {},
    onPageSelected: (_) {},
    onLimitChange: (_) {},
    onReorder: onReorder,
    sortState: (columnKey: 'name', ascending: true),
    onSort: (_, _) {},
  );
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  required Widget body,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => AdminScaffold(
          sections: _sections,
          location: '/guards/pending',
          page: (
            icon: Icons.pending_actions_outlined,
            title: 'Pending',
            parentLabel: 'Bodyguards',
            description: 'Awaiting review',
            breadcrumbs: const [
              (label: 'Home', route: '/home', icon: null),
              (label: 'Users', route: null, icon: null),
              (label: 'Bodyguards', route: '/guards', icon: null),
              (label: 'Pending', route: '/guards/pending', icon: null),
            ],
          ),
          onNavigate: (_) {},
          onSearch: () {},
          body: AdminPageBody(child: body),
        ),
      ),
    ),
  );
  // QuickContainer and Shimmer animate forever, so never pumpAndSettle.
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  const desktop = Size(1440, 900);
  const tablet = Size(1000, 800);
  const phone = Size(400, 860);

  testWidgets('desktop: expanded sidebar, breadcrumbs, virtualized table', (
    tester,
  ) async {
    await _pumpShell(tester, size: desktop, body: _table());

    expect(tester.takeException(), isNull);
    expect(find.text('Close protection'), findsOneWidget);
    expect(find.text('Bodyguards'), findsWidgets); // sidebar + breadcrumb
    expect(find.text('Users'), findsOneWidget); // breadcrumb section
    expect(find.text('USERS'), findsOneWidget); // sidebar section header

    // Sidebar labels are vertically centred in their rows.
    final label = find.text('Dashboard');
    final row = find
        .ancestor(of: label, matching: find.byType(AnimatedContainer))
        .first;
    expect(
      tester.getCenter(label).dy,
      moreOrLessEquals(tester.getCenter(row).dy, epsilon: 1),
    );
  });

  testWidgets('desktop dark mode renders', (tester) async {
    await _pumpShell(
      tester,
      size: desktop,
      body: _table(),
      themeMode: ThemeMode.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet: icon rail, no section titles', (tester) async {
    await _pumpShell(tester, size: tablet, body: _table());

    expect(tester.takeException(), isNull);
    expect(find.text('USERS'), findsNothing);
    expect(find.text('Close protection'), findsOneWidget);
  });

  testWidgets('phone: drawer and card table', (tester) async {
    await _pumpShell(tester, size: phone, body: _table());

    expect(tester.takeException(), isNull);
    // Compact header keeps the last two crumbs only.
    expect(find.text('Users'), findsNothing);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Close protection'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.text('USERS'), findsOneWidget);
  });

  for (final (name, size) in [('desktop', desktop), ('phone', phone)]) {
    testWidgets('$name: loading skeleton', (tester) async {
      await _pumpShell(
        tester,
        size: size,
        body: _table(data: [], load: true),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('$name: empty state', (tester) async {
      await _pumpShell(
        tester,
        size: size,
        body: _table(data: []),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('$name: reorderable table', (tester) async {
      await _pumpShell(
        tester,
        size: size,
        body: _table(onReorder: (_, _) async {}),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Event security'), findsOneWidget);
    });
  }

  testWidgets('desktop: narrow viewport scrolls reorder table horizontally', (
    tester,
  ) async {
    await _pumpShell(
      tester,
      size: const Size(800, 700),
      body: _table(onReorder: (_, _) async {}),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('command palette filters, highlights and opens a page', (
    tester,
  ) async {
    AdminNavItem? opened;
    await _pumpShell(tester, size: desktop, body: _table());

    final context = tester.element(find.byType(AdminPageBody));
    AdminCommandPalette.show(
      context,
      sections: _sections,
      onSelect: (item) => opened = item,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.text('Bodyguards · Pending'), findsWidgets);

    final paletteField = find.descendant(
      of: find.byType(AdminCommandPalette),
      matching: find.byType(EditableText),
    );
    await tester.enterText(paletteField, 'zzz-no-match');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No matching pages'), findsOneWidget);

    await tester.enterText(paletteField, 'approved');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    // First frame starts the route's reverse animation, second finishes it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(opened?.route, '/guards/approved');
    expect(find.byType(AdminCommandPalette), findsNothing);
  });

  test('nav lookup prefers exact matches and builds trails', () {
    final match = _sections.lookup('/guards/pending');
    expect(match?.section.title, 'Users');
    expect(match?.trail.map((item) => item.label), ['Bodyguards', 'Pending']);

    final detail = _sections.lookup('/guards/pending/42');
    expect(detail?.trail.last.label, 'Pending');

    expect(_sections.lookup('/home/anything'), isNull);
    expect(_sections.first.items.first.totalBadgeCount, 0);
    expect(_sections.last.items.first.totalBadgeCount, 4);
  });

  group('screen-owned routes', () {
    test('user list locations follow /users/<role>/<status>', () {
      expect(
        UsersManagementScreen.location(
          UserRoleType.guard,
          UserStatus.approvalPending,
        ),
        '/users/bodyguard/pending',
      );
      expect(UsersManagementScreen.defaultLocation, '/users/customer/verified');
      expect(UserDetailsScreen.location('42'), '/users/detail/42');
    });

    test('navigation tree resolves page meta from screen routes', () {
      final pending = AdminNavigation.pageFor(
        UsersManagementScreen.location(
          UserRoleType.company,
          UserStatus.approvalPending,
        ),
      );
      expect(pending.title, 'Pending');
      expect(pending.parentLabel, 'Companies');
      expect(pending.breadcrumbs.map((crumb) => crumb.label), [
        'Home',
        'Users',
        'Companies',
        'Pending',
      ]);

      final dashboard = AdminNavigation.pageFor(DashboardScreen.route);
      expect(dashboard.breadcrumbs.map((crumb) => crumb.label), [
        'Home',
        'Dashboard',
      ]);
    });
  });
}
