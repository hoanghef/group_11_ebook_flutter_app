import 'dart:async';

import 'package:app_ebook/main.dart';
import 'package:app_ebook/models/book.dart';
import 'package:app_ebook/models/book_note.dart';
import 'package:app_ebook/models/bookmark.dart';
import 'package:app_ebook/models/user.dart';
import 'package:app_ebook/screens/book_reader_screen.dart';
import 'package:app_ebook/screens/personal_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catalog_test.dart';
import 'fake_auth_repository.dart';
import 'fake_user_library_repository.dart';

const reader = AppUser(
  uid: 'reader',
  email: 'reader@example.com',
  displayName: 'Reader',
);

Future<void> openApp(
  WidgetTester tester,
  FakeUserLibraryRepository library, {
  FakeCatalogRepository? catalog,
  bool guest = false,
}) async {
  await tester.pumpWidget(
    EbookApp(
      authRepository: FakeAuthRepository(currentUser: guest ? null : reader),
      catalogRepository: catalog ?? FakeCatalogRepository(),
      userLibraryRepository: library,
    ),
  );
  await tester.pumpAndSettle();
  if (guest) {
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
  }
}

Future<void> openReader(WidgetTester tester) async {
  await tester.tap(find.text('Moonlight Stories').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Read Preview'));
  await tester.pumpAndSettle();
}

Future<void> openPersonalLibrary(WidgetTester tester) async {
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Bookmarks & Notes'));
  await tester.pumpAndSettle();
  expect(find.byType(PersonalLibraryScreen), findsOneWidget);
}

void main() {
  testWidgets('Bookmark opens the same book near its saved scroll ratio', (
    tester,
  ) async {
    final catalog = FakeCatalogRepository();
    catalog.books[0] = Book(
      id: 'one',
      title: 'Moonlight Stories',
      author: 'Alice Writer',
      coverImage: 'missing.jpg',
      description: 'Description',
      categoryIds: ['short'],
      content: List.filled(120, 'A long preview paragraph.').join(' '),
    );
    final library = FakeUserLibraryRepository();
    await openApp(tester, library, catalog: catalog);
    await openReader(tester);
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save bookmark'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Return here');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final savedRatio = library.bookmarks['reader']!.single.ratio;
    expect(savedRatio, greaterThan(0));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await openPersonalLibrary(tester);
    expect(find.text('Return here'), findsOneWidget);
    await tester.tap(find.text('Return here'));
    await tester.pumpAndSettle();
    expect(find.byType(BookReaderScreen), findsOneWidget);
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).last)
        .controller!;
    expect(
      scroll.offset / scroll.position.maxScrollExtent,
      closeTo(savedRatio, 0.03),
    );
  });

  testWidgets('Reader creates note and library edits and deletes it', (
    tester,
  ) async {
    final library = FakeUserLibraryRepository();
    await openApp(tester, library);
    await openReader(tester);
    await tester.tap(find.byTooltip('Add note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'First thought');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await openPersonalLibrary(tester);
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('First thought'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Updated thought');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Updated thought'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete note'));
    await tester.pumpAndSettle();
    expect(find.text('No notes yet. Open a book to add one.'), findsOneWidget);
  });

  testWidgets('Orphan note remains editable and deletable', (tester) async {
    final library = FakeUserLibraryRepository()
      ..notes['reader'] = [
        const BookNote(
          id: 'note_1',
          bookId: 'removed_book',
          text: 'Keep this note',
        ),
      ];
    await openApp(tester, library);
    await openPersonalLibrary(tester);
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Book unavailable (ID: removed_book)'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Edited orphan');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Edited orphan'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete note'));
    await tester.pumpAndSettle();
    expect(library.notes['reader'], isEmpty);
  });

  testWidgets('Personal library shows load error and Retry', (tester) async {
    final library = FakeUserLibraryRepository()
      ..failBookmarksLoad = true
      ..failNotesLoad = true;
    await openApp(tester, library);
    await openPersonalLibrary(tester);
    expect(find.text('Bookmarks could not load.'), findsOneWidget);
    library.failBookmarksLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No bookmarks yet'), findsOneWidget);
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Notes could not load.'), findsOneWidget);
  });

  testWidgets('Personal library shows loading before empty results', (
    tester,
  ) async {
    final library = FakeUserLibraryRepository()
      ..pendingBookmarks['reader'] = Completer<List<Bookmark>>()
      ..pendingNotes['reader'] = Completer<List<BookNote>>();
    await openApp(tester, library);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bookmarks & Notes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    library.pendingBookmarks['reader']!.complete([]);
    await tester.pump();
    expect(find.text('No bookmarks yet'), findsOneWidget);
    await tester.tap(find.text('Notes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    library.pendingNotes['reader']!.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No notes yet. Open a book to add one.'), findsOneWidget);
  });

  testWidgets('Failed note write keeps dialog open for retry', (tester) async {
    final library = FakeUserLibraryRepository()..failPersonalWrite = true;
    await openApp(tester, library);
    await openReader(tester);
    await tester.tap(find.byTooltip('Add note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Keep my draft');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Note could not be saved. Retry.'), findsOneWidget);
    expect(library.notes['reader'], isNull);
    library.failPersonalWrite = false;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(library.notes['reader']!.single.text, 'Keep my draft');
  });

  testWidgets('Guest sees sign-in guidance and cannot create bookmark', (
    tester,
  ) async {
    final library = FakeUserLibraryRepository();
    await openApp(tester, library, guest: true);
    await openReader(tester);
    await tester.tap(find.byTooltip('Sign in to save bookmarks'));
    await tester.pump();
    expect(find.text('Sign in to save bookmarks and notes.'), findsOneWidget);
    expect(library.bookmarks, isEmpty);
  });
}
