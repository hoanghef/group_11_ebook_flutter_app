import 'package:app_ebook/main.dart';
import 'package:app_ebook/models/book.dart';
import 'package:app_ebook/models/user.dart';
import 'package:app_ebook/screens/book_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_ebook/widgets/book_cover.dart';

import 'catalog_test.dart';
import 'fake_auth_repository.dart';
import 'fake_user_library_repository.dart';

const reader = AppUser(
  uid: 'reader',
  email: 'reader@example.com',
  displayName: 'Reader',
);

Future<void> pumpLibraryApp(
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
  testWidgets('Restored favorites appear in Settings library', (tester) async {
    final library = FakeUserLibraryRepository()..favorites['reader'] = {'one'};
    await pumpLibraryApp(
      tester,
      FakeAuthRepository(currentUser: reader),
      library,
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.byType(BookCover), findsOneWidget);
    expect(find.text('Moonlight Stories'), findsOneWidget);
    expect(find.text('Ocean Tales'), findsNothing);
  });

  testWidgets('Favorite load error shows Retry instead of an empty library', (
    tester,
  ) async {
    final library = FakeUserLibraryRepository()..failLoad = true;
    await pumpLibraryApp(
      tester,
      FakeAuthRepository(currentUser: reader),
      library,
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites could not load.'), findsOneWidget);
    expect(find.text('No favorites yet'), findsNothing);
    library.failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('Failed favorite write leaves icon off and reports error', (
    tester,
  ) async {
    final library = FakeUserLibraryRepository()..failWrite = true;
    await pumpLibraryApp(
      tester,
      FakeAuthRepository(currentUser: reader),
      library,
    );
    await tester.tap(find.text('Moonlight Stories').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Favorite'));
    await tester.pump();
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(library.favorites['reader'], isNull);
    expect(find.textContaining('could not be saved'), findsOneWidget);
    library.failWrite = false;
    await tester.tap(find.byTooltip('Retry favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Favorite'));
    await tester.pump();
    expect(library.favorites['reader'], contains('one'));
  });

  testWidgets('Reader restores scroll ratio and debounces writes', (
    tester,
  ) async {
    final catalog = FakeCatalogRepository();
    catalog.books[0] = Book(
      id: 'one',
      title: 'Moonlight Stories',
      author: 'Alice Writer',
      coverImage: 'missing.jpg',
      description: 'A sample description',
      categoryIds: ['short'],
      content: List.filled(120, 'A long paragraph of preview text.').join(' '),
    );
    final library = FakeUserLibraryRepository()
      ..progress['reader'] = {'one': 0.4};
    await pumpLibraryApp(
      tester,
      FakeAuthRepository(currentUser: reader),
      library,
      catalog: catalog,
    );
    await tester.tap(find.text('Moonlight Stories').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read Preview'));
    await tester.pumpAndSettle();
    expect(find.byType(BookReaderScreen), findsOneWidget);
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).last)
        .controller!;
    expect(scroll.offset / scroll.position.maxScrollExtent, closeTo(0.4, 0.03));
    final before = library.progressWrites;
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -180),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(library.progressWrites, before);
    await tester.pump(const Duration(milliseconds: 650));
    expect(library.progressWrites, before + 1);
    final savedRatio = library.progress['reader']!['one']!;
    expect(savedRatio, greaterThan(0.4));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read Preview'));
    await tester.pumpAndSettle();
    final reopened = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).last)
        .controller!;
    expect(
      reopened.offset / reopened.position.maxScrollExtent,
      closeTo(savedRatio, 0.03),
    );
  });

  testWidgets('A short preview cannot overwrite saved reading progress', (
    tester,
  ) async {
    final catalog = FakeCatalogRepository();
    catalog.books[0] = Book(
      id: 'one',
      title: 'Moonlight Stories',
      author: 'Alice Writer',
      coverImage: 'missing.jpg',
      description: 'A sample description',
      categoryIds: ['short'],
      content: 'A short preview.',
    );
    final library = FakeUserLibraryRepository()
      ..progress['reader'] = {'one': 0.8};
    await pumpLibraryApp(
      tester,
      FakeAuthRepository(currentUser: reader),
      library,
      catalog: catalog,
    );
    await tester.tap(find.text('Moonlight Stories').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read Preview'));
    await tester.pumpAndSettle();
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).last)
        .controller!;
    expect(scroll.position.maxScrollExtent, 0);
    expect(find.text('80% of preview'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(library.progress['reader']!['one'], 0.8);
    expect(library.progressWrites, 0);
  });

  testWidgets('Guest reading does not write progress', (tester) async {
    final library = FakeUserLibraryRepository();
    await pumpLibraryApp(tester, FakeAuthRepository(), library);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moonlight Stories').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read Preview'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(library.progressWrites, 0);
  });

  testWidgets('Reader load failure shows Retry and does not save zero', (
    tester,
  ) async {
    final library = FakeUserLibraryRepository()..failProgress = true;
    await pumpLibraryApp(
      tester,
      FakeAuthRepository(currentUser: reader),
      library,
    );
    await tester.tap(find.text('Moonlight Stories').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read Preview'));
    await tester.pumpAndSettle();
    expect(find.text('Reading position could not load.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(library.progressWrites, 0);

    await tester.tap(find.text('Read Preview'));
    await tester.pumpAndSettle();
    expect(find.text('Reading position could not load.'), findsOneWidget);
    library.failProgress = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Reading position could not load.'), findsNothing);
  });
}
