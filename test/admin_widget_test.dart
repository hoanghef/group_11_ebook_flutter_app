import 'package:app_ebook/main.dart';
import 'package:app_ebook/models/user.dart';
import 'package:app_ebook/screens/admin_book_form_screen.dart';
import 'package:app_ebook/screens/admin_category_form_screen.dart';
import 'package:app_ebook/screens/admin_workspace_screen.dart';
import 'package:app_ebook/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catalog_test.dart';
import 'fake_admin_repositories.dart';
import 'fake_auth_repository.dart';
import 'fake_user_library_repository.dart';

const adminUser = AppUser(
  uid: 'admin-user',
  email: 'admin@example.com',
  displayName: 'Admin',
);

Future<void> pumpAdminApp(
  WidgetTester tester,
  FakeAdminAccessRepository access,
  FakeAdminCatalogRepository catalog, {
  bool signedIn = true,
}) async {
  await tester.pumpWidget(
    EbookApp(
      key: UniqueKey(),
      authRepository: FakeAuthRepository(
        currentUser: signedIn ? adminUser : null,
      ),
      catalogRepository: FakeCatalogRepository(),
      userLibraryRepository: FakeUserLibraryRepository(),
      adminAccessRepository: access,
      adminCatalogRepository: catalog,
    ),
  );
  await tester.pumpAndSettle();
  if (!signedIn) {
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
}

Future<void> openWorkspace(WidgetTester tester) async {
  await tester.tap(find.text('Admin workspace'));
  await tester.pumpAndSettle();
  expect(find.byType(AdminWorkspaceScreen), findsOneWidget);
}

void main() {
  testWidgets('Guest and ordinary user have no Admin entry or access', (
    tester,
  ) async {
    final access = FakeAdminAccessRepository();
    await pumpAdminApp(tester, access, FakeAdminCatalogRepository());
    expect(find.text('Admin workspace'), findsNothing);
    Navigator.of(
      tester.element(find.byType(SettingsScreen)),
    ).push(MaterialPageRoute(builder: (_) => const AdminWorkspaceScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Admin access required.'), findsOneWidget);
    expect(find.text('Add book'), findsNothing);

    await pumpAdminApp(
      tester,
      FakeAdminAccessRepository(claim: true),
      FakeAdminCatalogRepository(),
      signedIn: false,
    );
    expect(find.text('Admin workspace'), findsNothing);
  });

  testWidgets('Admin lists all statuses and confirms status changes', (
    tester,
  ) async {
    final catalog = FakeAdminCatalogRepository();
    await pumpAdminApp(tester, FakeAdminAccessRepository(claim: true), catalog);
    await openWorkspace(tester);
    expect(find.text('draft_book · draft'), findsOneWidget);
    expect(find.text('archived_book · archived'), findsOneWidget);
    await tester.tap(find.byTooltip('Change book status').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Published').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Change Draft Book to published'),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(catalog.books.first.status, 'published');
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('hidden · Inactive'), findsOneWidget);
  });

  testWidgets('Book form validates and failed save can be retried', (
    tester,
  ) async {
    final catalog = FakeAdminCatalogRepository();
    await pumpAdminApp(tester, FakeAdminAccessRepository(claim: true), catalog);
    await openWorkspace(tester);
    await tester.tap(find.text('Add book'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminBookFormScreen), findsOneWidget);
    final formScroll = find
        .descendant(
          of: find.byType(AdminBookFormScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Save book'),
      250,
      scrollable: formScroll,
    );
    await tester.tap(find.text('Save book'));
    await tester.pumpAndSettle();
    expect(find.textContaining('lowercase letters'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('admin_book_id')),
      -250,
      scrollable: formScroll,
    );
    await tester.enterText(find.byKey(const Key('admin_book_id')), 'new_book');
    await tester.enterText(
      find.byKey(const Key('admin_book_title')),
      'New Book',
    );
    await tester.enterText(
      find.byKey(const Key('admin_book_author')),
      'Writer',
    );
    await tester.scrollUntilVisible(
      find.text('Fiction'),
      250,
      scrollable: formScroll,
    );
    await tester.tap(find.text('Fiction'));
    catalog.failSave = true;
    await tester.scrollUntilVisible(
      find.text('Save book'),
      250,
      scrollable: formScroll,
    );
    await tester.tap(find.text('Save book'));
    await tester.pumpAndSettle();
    expect(find.text('Save failed. Retry.'), findsOneWidget);
    expect(catalog.books.any((book) => book.id == 'new_book'), isFalse);
    catalog.failSave = false;
    await tester.tap(find.text('Save book'));
    await tester.pumpAndSettle();
    expect(catalog.books.any((book) => book.id == 'new_book'), isTrue);
  });

  testWidgets('Inactive old category remains visible; catalog load retries', (
    tester,
  ) async {
    final catalog = FakeAdminCatalogRepository()..failLoad = true;
    await pumpAdminApp(tester, FakeAdminAccessRepository(claim: true), catalog);
    await openWorkspace(tester);
    expect(find.text('Catalog unavailable. Retry.'), findsOneWidget);
    catalog.failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archived Book'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Inactive or missing category'),
      220,
      scrollable: find
          .descendant(
            of: find.byType(AdminBookFormScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.textContaining('hidden (retained)'), findsOneWidget);
  });

  testWidgets('Admin creates and deactivates a category with confirmation', (
    tester,
  ) async {
    final catalog = FakeAdminCatalogRepository();
    await pumpAdminApp(tester, FakeAdminAccessRepository(claim: true), catalog);
    await openWorkspace(tester);
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminCategoryFormScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('admin_category_id')),
      'new_category',
    );
    await tester.enterText(
      find.byKey(const Key('admin_category_name')),
      'New Category',
    );
    final formScroll = find
        .descendant(
          of: find.byType(AdminCategoryFormScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Save category'),
      200,
      scrollable: formScroll,
    );
    await tester.tap(find.text('Save category'));
    await tester.pumpAndSettle();
    expect(catalog.categories.last.name, 'New Category');
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Deactivate New Category'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(catalog.categories.last.isActive, isFalse);
  });
}
