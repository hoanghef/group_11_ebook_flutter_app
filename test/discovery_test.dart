import 'dart:async';

import 'package:app_ebook/controllers/auth_controller.dart';
import 'package:app_ebook/controllers/catalog_controller.dart';
import 'package:app_ebook/controllers/user_library_controller.dart';
import 'package:app_ebook/main.dart';
import 'package:app_ebook/models/book.dart';
import 'package:app_ebook/models/reading_progress_entry.dart';
import 'package:app_ebook/models/search_history_entry.dart';
import 'package:app_ebook/models/user.dart';
import 'package:app_ebook/screens/book_detail_screen.dart';
import 'package:app_ebook/screens/book_reader_screen.dart';
import 'package:app_ebook/screens/category_books_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catalog_test.dart';
import 'fake_auth_repository.dart';
import 'fake_user_library_repository.dart';

const alice = AppUser(uid: 'alice', email: 'a@example.com', displayName: 'A');
const bob = AppUser(uid: 'bob', email: 'b@example.com', displayName: 'B');

Future<void> pumpDiscovery(
  WidgetTester tester,
  FakeAuthRepository auth,
  FakeUserLibraryRepository library, {
  FakeCatalogRepository? catalog,
}) async {
  await tester.pumpWidget(
    EbookApp(
      authRepository: auth,
      catalogRepository: catalog ?? FakeCatalogRepository(),
      userLibraryRepository: library,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Recently Added sorts timestamps and missing dates deterministically',
    () async {
      final repo = FakeCatalogRepository();
      repo.books.addAll([
        Book(
          id: 'old',
          title: 'Old',
          author: 'A',
          coverImage: '',
          description: '',
          categoryIds: ['short'],
          content: '',
          createdAt: DateTime.utc(2020),
        ),
        Book(
          id: 'new',
          title: 'New',
          author: 'A',
          coverImage: '',
          description: '',
          categoryIds: ['short'],
          content: '',
          createdAt: DateTime.utc(2025),
        ),
        Book(
          id: 'draft',
          title: 'Draft',
          author: 'A',
          coverImage: '',
          description: '',
          categoryIds: ['short'],
          content: '',
          isPublished: false,
          createdAt: DateTime.utc(2026),
        ),
      ]);
      final controller = CatalogController(repo);
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.recentlyAddedBooks.map((book) => book.id), [
        'new',
        'old',
        'one',
        'two',
      ]);
      expect(controller.books.map((book) => book.id), isNot(contains('draft')));
    },
  );

  testWidgets('Home category chip opens matching category', (tester) async {
    await pumpDiscovery(
      tester,
      FakeAuthRepository(),
      FakeUserLibraryRepository(),
    );
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Short Stories'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryBooksScreen), findsOneWidget);
    expect(find.text('Moonlight Stories'), findsOneWidget);
    expect(find.text('Ocean Tales'), findsNothing);
  });

  testWidgets('Continue Reading restores ratio and skips orphan progress', (
    tester,
  ) async {
    final library = FakeUserLibraryRepository()
      ..recentProgress['alice'] = [
        ReadingProgressEntry(
          bookId: 'one',
          ratio: 0.4,
          updatedAt: DateTime.now(),
        ),
        ReadingProgressEntry(
          bookId: 'missing',
          ratio: 0.9,
          updatedAt: DateTime.now(),
        ),
      ];
    final catalog = FakeCatalogRepository();
    catalog.books[0] = Book(
      id: 'one',
      title: 'Moonlight Stories',
      author: 'Alice Writer',
      coverImage: 'missing.jpg',
      description: '',
      categoryIds: ['short'],
      content: List.filled(120, 'Long preview text.').join(' '),
    );
    await pumpDiscovery(
      tester,
      FakeAuthRepository(currentUser: alice),
      library,
      catalog: catalog,
    );
    expect(find.text('Continue Reading'), findsOneWidget);
    expect(find.text('40% of preview'), findsOneWidget);
    expect(find.text('90% of preview'), findsNothing);
    await tester.tap(find.text('40% of preview'));
    await tester.pumpAndSettle();
    expect(find.byType(BookReaderScreen), findsOneWidget);
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).last)
        .controller!;
    expect(scroll.offset / scroll.position.maxScrollExtent, closeTo(0.4, 0.03));
  });

  testWidgets('Continue Reading guest, empty, error and retry states', (
    tester,
  ) async {
    final guestLibrary = FakeUserLibraryRepository();
    await pumpDiscovery(tester, FakeAuthRepository(), guestLibrary);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(find.text('Continue Reading'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());

    final library = FakeUserLibraryRepository()..failRecentProgress = true;
    await pumpDiscovery(
      tester,
      FakeAuthRepository(currentUser: alice),
      library,
    );
    expect(find.text('Continue Reading could not load.'), findsOneWidget);
    library.failRecentProgress = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.text('No reading progress in the available catalog.'),
      findsOneWidget,
    );
  });

  testWidgets('More from Author opens another book and excludes current', (
    tester,
  ) async {
    final catalog = FakeCatalogRepository();
    catalog.books.add(
      Book(
        id: 'three',
        title: 'Another Moon',
        author: 'ALICE WRITER',
        coverImage: 'missing.jpg',
        description: '',
        categoryIds: ['short'],
        content: 'Preview',
      ),
    );
    await pumpDiscovery(
      tester,
      FakeAuthRepository(),
      FakeUserLibraryRepository(),
      catalog: catalog,
    );
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moonlight Stories').first);
    await tester.pumpAndSettle();
    expect(find.byType(BookDetailScreen), findsOneWidget);
    expect(find.text('Another Moon'), findsOneWidget);
    await tester.ensureVisible(find.text('Another Moon'));
    await tester.tap(find.text('Another Moon'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<BookDetailScreen>(find.byType(BookDetailScreen)).book.id,
      'three',
    );
  });

  testWidgets('Book details copy only public metadata', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpDiscovery(
      tester,
      FakeAuthRepository(),
      FakeUserLibraryRepository(),
    );
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moonlight Stories').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Copy book details'));
    await tester.pump();
    expect(copied, contains('Moonlight Stories'));
    expect(copied, contains('Alice Writer'));
    expect(copied, isNot(contains('uid')));
    expect(find.text('Public book details copied.'), findsOneWidget);
  });

  test(
    'Search history saves submitted queries only, caps at ten and isolates UID',
    () async {
      final authRepo = FakeAuthRepository(currentUser: alice);
      final auth = AuthController(authRepo);
      final repo = FakeUserLibraryRepository();
      final library = UserLibraryController(auth, repo);
      addTearDown(library.dispose);
      addTearDown(auth.dispose);
      addTearDown(authRepo.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(await library.submitSearchQuery('  Moonlight  '), isTrue);
      expect(library.searchHistory.single.query, 'Moonlight');
      for (var i = 0; i < 12; i++) {
        expect(await library.submitSearchQuery('Query $i'), isTrue);
      }
      expect(library.searchHistory, hasLength(10));
      expect(repo.history['alice'], hasLength(10));
      final first = library.searchHistory.first.id;
      expect(await library.deleteSearchQuery(first), isTrue);
      expect(library.searchHistory, hasLength(9));
      authRepo.emitUser(bob);
      await Future<void>.delayed(Duration.zero);
      expect(library.searchHistory, isEmpty);
      expect(await library.submitSearchQuery('Bob query'), isTrue);
      expect(repo.history['bob']!.single.query, 'Bob query');
      repo.failHistoryWrite = true;
      expect(
        await library.deleteSearchQuery(library.searchHistory.single.id),
        isFalse,
      );
      expect(library.searchHistory.single.query, 'Bob query');
      expect(await library.clearSearchHistory(), isFalse);
      expect(library.searchHistory, hasLength(1));
      repo.failHistoryWrite = false;
      expect(await library.clearSearchHistory(), isTrue);
      expect(library.searchHistory, isEmpty);
      authRepo.emitUser(null);
      await Future<void>.delayed(Duration.zero);
      expect(library.searchHistory, isEmpty);
      expect(await library.submitSearchQuery('Guest query'), isFalse);
    },
  );

  test(
    'Late history and progress responses cannot replace a new UID',
    () async {
      final authRepo = FakeAuthRepository(currentUser: alice);
      final auth = AuthController(authRepo);
      final repo = FakeUserLibraryRepository()
        ..pendingHistory['alice'] = Completer<List<SearchHistoryEntry>>()
        ..pendingRecentProgress['alice'] =
            Completer<List<ReadingProgressEntry>>();
      final library = UserLibraryController(auth, repo);
      addTearDown(library.dispose);
      addTearDown(auth.dispose);
      addTearDown(authRepo.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(library.isLoadingSearchHistory, isTrue);
      expect(library.isLoadingRecentProgress, isTrue);
      authRepo.emitUser(bob);
      await Future<void>.delayed(Duration.zero);
      repo.pendingHistory['alice']!.complete([
        SearchHistoryEntry(
          id: 'old',
          query: 'Alice',
          submittedAt: DateTime.now(),
        ),
      ]);
      repo.pendingRecentProgress['alice']!.complete([
        ReadingProgressEntry(
          bookId: 'one',
          ratio: 0.8,
          updatedAt: DateTime.now(),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(library.searchHistory, isEmpty);
      expect(library.recentProgress, isEmpty);
    },
  );

  testWidgets(
    'Search stores only submitted queries and supports reuse and removal',
    (tester) async {
      final library = FakeUserLibraryRepository();
      await pumpDiscovery(
        tester,
        FakeAuthRepository(currentUser: alice),
        library,
      );
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  alice writer  ');
      await tester.pump();
      expect(find.text('Moonlight Stories'), findsOneWidget);
      expect(library.history['alice'], isNull);
      await tester.tap(find.byTooltip('Submit search'));
      await tester.pumpAndSettle();
      expect(library.history['alice']!.single.query, 'alice writer');
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.text('Recent searches'), findsOneWidget);
      await tester.tap(find.text('alice writer'));
      await tester.pumpAndSettle();
      expect(find.text('Moonlight Stories'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove alice writer'));
      await tester.pumpAndSettle();
      expect(library.history['alice'], isEmpty);
    },
  );

  testWidgets('History load error retries and guest never writes history', (
    tester,
  ) async {
    final library = FakeUserLibraryRepository()..failHistory = true;
    await pumpDiscovery(
      tester,
      FakeAuthRepository(currentUser: alice),
      library,
    );
    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pumpAndSettle();
    expect(find.text('Recent searches could not load.'), findsOneWidget);
    library.failHistory = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Search for books'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());

    final guestLibrary = FakeUserLibraryRepository();
    await pumpDiscovery(tester, FakeAuthRepository(), guestLibrary);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Moonlight');
    await tester.tap(find.byTooltip('Submit search'));
    await tester.pumpAndSettle();
    expect(guestLibrary.history, isEmpty);
  });
}
