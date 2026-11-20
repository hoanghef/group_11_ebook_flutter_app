import 'dart:async';

import 'package:app_ebook/main.dart';
import 'package:app_ebook/models/book.dart';
import 'package:app_ebook/models/category.dart';
import 'package:app_ebook/repositories/catalog_repository.dart';
import 'package:app_ebook/screens/category_books_screen.dart';
import 'package:app_ebook/screens/book_detail_screen.dart';
import 'package:app_ebook/screens/home_tab_screen.dart';
import 'package:app_ebook/screens/search_screen.dart';
import 'package:app_ebook/widgets/book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catalog_test.dart';
import 'fake_auth_repository.dart';

class PendingCatalogRepository implements CatalogRepository {
  final pendingBooks = Completer<List<Book>>();

  @override
  Future<List<Book>> getBooks() => pendingBooks.future;

  @override
  Future<List<Category>> getCategories() async => [];
}

class ChangingCatalogRepository extends FakeCatalogRepository {
  bool fail = false;

  @override
  Future<List<Book>> getBooks() async {
    if (fail) throw StateError('Offline');
    return books;
  }

  @override
  Future<List<Category>> getCategories() async => categories;
}

Future<void> openGuest(
  WidgetTester tester,
  ChangingCatalogRepository repository,
) async {
  await tester.pumpWidget(
    EbookApp(
      authRepository: FakeAuthRepository(),
      catalogRepository: repository,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Skip for now'));
  await tester.pumpAndSettle();
}

Future<void> openHome(WidgetTester tester) async {
  await tester.pumpWidget(
    EbookApp(
      authRepository: FakeAuthRepository(),
      catalogRepository: FakeCatalogRepository(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Skip for now'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home shows loading until catalog request completes', (
    tester,
  ) async {
    final repository = PendingCatalogRepository();
    await tester.pumpWidget(
      EbookApp(
        authRepository: FakeAuthRepository(),
        catalogRepository: repository,
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Skip for now'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.pendingBooks.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No books available'), findsOneWidget);
  });

  testWidgets('Catalog error is visible and Retry reloads Home', (
    tester,
  ) async {
    final repository = ChangingCatalogRepository()..fail = true;
    await openGuest(tester, repository);
    expect(find.text('Catalog could not load.'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Moonlight Stories'), findsWidgets);
  });

  testWidgets('Empty catalog is explicit on Home, Explore and Search', (
    tester,
  ) async {
    final repository = ChangingCatalogRepository();
    repository.books.clear();
    repository.categories.clear();
    await openGuest(tester, repository);
    expect(find.text('No books available'), findsOneWidget);

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('No categories or books available'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('No books available to search'), findsOneWidget);
  });

  testWidgets('Category Books distinguishes error and empty results', (
    tester,
  ) async {
    final repository = ChangingCatalogRepository()..fail = true;
    await openGuest(tester, repository);
    Navigator.of(tester.element(find.byType(HomeTabScreen))).push(
      MaterialPageRoute<void>(
        builder: (_) => const CategoryBooksScreen(categoryId: 'short'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Catalog could not load.'), findsOneWidget);
    repository.fail = false;
    repository.books.clear();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No books found'), findsOneWidget);
  });

  testWidgets('Home shows books supplied by the repository', (tester) async {
    await openHome(tester);
    expect(find.byType(BookCover), findsWidgets);
    expect(find.text('Moonlight Stories'), findsWidgets);
    expect(find.text('Ocean Tales'), findsWidgets);
  });

  testWidgets('Explore and Category Books share category results', (
    tester,
  ) async {
    await openHome(tester);
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();

    expect(find.text('Short Stories'), findsOneWidget);
    expect(find.byType(BookCover), findsWidgets);
    expect(find.text('Moonlight Stories'), findsOneWidget);
    await tester.tap(find.text('See All').first);
    await tester.pumpAndSettle();

    expect(find.byType(CategoryBooksScreen), findsOneWidget);
    expect(find.byType(BookCover), findsWidgets);
    expect(find.text('Moonlight Stories'), findsOneWidget);
    expect(find.text('Ocean Tales'), findsNothing);
  });

  testWidgets('Search uses repository books by author', (tester) async {
    await openHome(tester);
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ALICE WRITER');
    await tester.pump();

    expect(find.text('Moonlight Stories'), findsOneWidget);
    expect(find.byType(BookCover), findsWidgets);
    expect(find.text('Ocean Tales'), findsNothing);
  });

  testWidgets('Book Detail draws the generated cover without a JPG', (
    tester,
  ) async {
    await openHome(tester);
    Navigator.of(tester.element(find.byType(HomeTabScreen))).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BookDetailScreen(book: FakeCatalogRepository().books.first),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BookDetailScreen), findsOneWidget);
    expect(find.byType(BookCover), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
