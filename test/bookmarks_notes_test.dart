import 'dart:async';

import 'package:app_ebook/controllers/auth_controller.dart';
import 'package:app_ebook/controllers/user_library_controller.dart';
import 'package:app_ebook/models/book_note.dart';
import 'package:app_ebook/models/bookmark.dart';
import 'package:app_ebook/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';
import 'fake_user_library_repository.dart';

const a = AppUser(uid: 'a', email: 'a@example.com', displayName: 'A');
const b = AppUser(uid: 'b', email: 'b@example.com', displayName: 'B');

void main() {
  test('Bookmarks and notes support create, edit, delete and reload', () async {
    final authRepo = FakeAuthRepository(currentUser: a);
    final auth = AuthController(authRepo);
    final repo = FakeUserLibraryRepository();
    final library = UserLibraryController(auth, repo);
    addTearDown(library.dispose);
    addTearDown(auth.dispose);
    addTearDown(authRepo.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(await library.createBookmark('one', 0.42, 'Middle'), isTrue);
    expect(await library.createNote('one', 'First thought'), isTrue);
    final markId = library.bookmarks.single.id;
    final noteId = library.notes.single.id;
    expect(library.bookmarks.single.ratio, 0.42);
    expect(await library.updateNote(noteId, 'Updated thought'), isTrue);
    expect(library.notes.single.text, 'Updated thought');
    await library.loadBookmarks();
    await library.loadNotes();
    expect(library.bookmarks.single.id, markId);
    expect(library.notes.single.text, 'Updated thought');
    expect(await library.deleteBookmark(markId), isTrue);
    expect(await library.deleteNote(noteId), isTrue);
    expect(library.bookmarks, isEmpty);
    expect(library.notes, isEmpty);
  });

  test('UID change and guest clear personal lists and reject writes', () async {
    final authRepo = FakeAuthRepository(currentUser: a);
    final auth = AuthController(authRepo);
    final repo = FakeUserLibraryRepository()
      ..bookmarks['a'] = [
        const Bookmark(id: 'm1', bookId: 'one', ratio: 0.2, label: ''),
      ]
      ..notes['b'] = [const BookNote(id: 'n1', bookId: 'two', text: 'B only')];
    final library = UserLibraryController(auth, repo);
    addTearDown(library.dispose);
    addTearDown(auth.dispose);
    addTearDown(authRepo.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(library.bookmarks, hasLength(1));
    authRepo.emitUser(b);
    await Future<void>.delayed(Duration.zero);
    expect(library.bookmarks, isEmpty);
    expect(library.notes.single.text, 'B only');
    authRepo.emitUser(null);
    await Future<void>.delayed(Duration.zero);
    auth.enterGuest();
    expect(library.notes, isEmpty);
    expect(await library.createBookmark('one', 0.5, ''), isFalse);
    expect(await library.createNote('one', 'Guest'), isFalse);
  });

  test('Late reads and writes cannot populate another UID', () async {
    final authRepo = FakeAuthRepository(currentUser: a);
    final auth = AuthController(authRepo);
    final repo = FakeUserLibraryRepository()
      ..pendingBookmarks['a'] = Completer<List<Bookmark>>()
      ..pendingNotes['a'] = Completer<List<BookNote>>();
    final library = UserLibraryController(auth, repo);
    addTearDown(library.dispose);
    addTearDown(auth.dispose);
    addTearDown(authRepo.dispose);
    await Future<void>.delayed(Duration.zero);
    authRepo.emitUser(b);
    await Future<void>.delayed(Duration.zero);
    repo.pendingBookmarks['a']!.complete([
      const Bookmark(id: 'old', bookId: 'one', ratio: 0.7, label: ''),
    ]);
    repo.pendingNotes['a']!.complete([
      const BookNote(id: 'old', bookId: 'one', text: 'Old'),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(library.bookmarks, isEmpty);
    expect(library.notes, isEmpty);

    repo.pendingPersonalWrite = Completer<void>();
    final write = library.createBookmark('two', 0.4, 'B mark');
    authRepo.emitUser(a);
    await Future<void>.delayed(Duration.zero);
    repo.pendingPersonalWrite!.complete();
    expect(await write, isFalse);
    expect(library.bookmarks.any((item) => item.label == 'B mark'), isFalse);
  });

  test('Load and write errors retain data and allow retry', () async {
    final authRepo = FakeAuthRepository(currentUser: a);
    final auth = AuthController(authRepo);
    final repo = FakeUserLibraryRepository()
      ..failBookmarksLoad = true
      ..failNotesLoad = true;
    final library = UserLibraryController(auth, repo);
    addTearDown(library.dispose);
    addTearDown(auth.dispose);
    addTearDown(authRepo.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(library.bookmarksError, isNotNull);
    expect(library.notesError, isNotNull);
    repo.failBookmarksLoad = false;
    repo.failNotesLoad = false;
    await library.loadBookmarks();
    await library.loadNotes();
    expect(library.bookmarksError, isNull);
    expect(library.notesError, isNull);
    repo.failPersonalWrite = true;
    expect(await library.createBookmark('one', 0.3, ''), isFalse);
    expect(await library.createNote('one', 'Thought'), isFalse);
    expect(library.bookmarks, isEmpty);
    expect(library.notes, isEmpty);
    repo.failPersonalWrite = false;
    expect(await library.createBookmark('one', 0.3, ''), isTrue);
    expect(await library.createNote('one', 'Thought'), isTrue);
  });
}
