import 'dart:async';

import 'package:app_ebook/models/book_note.dart';
import 'package:app_ebook/models/bookmark.dart';
import 'package:app_ebook/models/reading_progress_entry.dart';
import 'package:app_ebook/models/search_history_entry.dart';
import 'package:app_ebook/repositories/user_library_repository.dart';

class FakeUserLibraryRepository implements UserLibraryRepository {
  final Map<String, Set<String>> favorites = {};
  final Map<String, Map<String, double>> progress = {};
  final Map<String, List<ReadingProgressEntry>> recentProgress = {};
  final Map<String, List<SearchHistoryEntry>> history = {};
  final Map<String, Completer<List<ReadingProgressEntry>>>
  pendingRecentProgress = {};
  final Map<String, Completer<List<SearchHistoryEntry>>> pendingHistory = {};
  bool failRecentProgress = false;
  bool failHistory = false;
  bool failHistoryWrite = false;
  final Map<String, List<Bookmark>> bookmarks = {};
  final Map<String, List<BookNote>> notes = {};
  final Map<String, Completer<List<Bookmark>>> pendingBookmarks = {};
  final Map<String, Completer<List<BookNote>>> pendingNotes = {};
  Completer<void>? pendingPersonalWrite;
  bool failBookmarksLoad = false;
  bool failNotesLoad = false;
  bool failPersonalWrite = false;
  int _nextId = 0;
  final Map<String, Completer<Set<String>>> pendingFavorites = {};
  Completer<void>? pendingWrite;
  Completer<double?>? pendingProgressLoad;
  Completer<void>? pendingProgressWrite;
  bool failLoad = false;
  bool failWrite = false;
  bool failProgress = false;
  int progressWrites = 0;

  @override
  Future<Set<String>> getFavorites(String uid) async {
    if (pendingFavorites.containsKey(uid)) return pendingFavorites[uid]!.future;
    if (failLoad) throw StateError('Offline');
    return {...favorites[uid] ?? {}};
  }

  @override
  Future<void> setFavorite(String uid, String bookId, bool favorite) async {
    if (pendingWrite != null) await pendingWrite!.future;
    if (failWrite) throw StateError('Offline');
    final ids = favorites.putIfAbsent(uid, () => {});
    if (favorite) {
      ids.add(bookId);
    } else {
      ids.remove(bookId);
    }
  }

  @override
  Future<void> clearFavorites(String uid) async {
    if (failWrite) throw StateError('Offline');
    favorites[uid] = {};
  }

  @override
  Future<double?> getReadingProgress(String uid, String bookId) async {
    if (pendingProgressLoad != null) return pendingProgressLoad!.future;
    if (failProgress) throw StateError('Offline');
    return progress[uid]?[bookId];
  }

  @override
  Future<void> saveReadingProgress(
    String uid,
    String bookId,
    double ratio,
  ) async {
    progressWrites++;
    if (pendingProgressWrite != null) await pendingProgressWrite!.future;
    if (failProgress) throw StateError('Offline');
    progress.putIfAbsent(uid, () => {})[bookId] = ratio;
    recentProgress[uid] = [
      ReadingProgressEntry(
        bookId: bookId,
        ratio: ratio,
        updatedAt: DateTime.now(),
      ),
      ...?recentProgress[uid]?.where((item) => item.bookId != bookId),
    ];
  }

  @override
  Future<List<ReadingProgressEntry>> getRecentReadingProgress(
    String uid,
  ) async {
    if (pendingRecentProgress.containsKey(uid)) {
      return pendingRecentProgress[uid]!.future;
    }
    if (failRecentProgress) throw StateError('Offline');
    return List.of(recentProgress[uid] ?? []);
  }

  @override
  Future<List<SearchHistoryEntry>> getSearchHistory(String uid) async {
    if (pendingHistory.containsKey(uid)) return pendingHistory[uid]!.future;
    if (failHistory) throw StateError('Offline');
    return List.of(history[uid] ?? []);
  }

  @override
  Future<SearchHistoryEntry> submitSearchQuery(String uid, String query) async {
    if (failHistoryWrite) throw StateError('Offline');
    final items = history.putIfAbsent(uid, () => []);
    final old = items.where(
      (item) => item.query.toLowerCase() == query.toLowerCase(),
    );
    final entry = SearchHistoryEntry(
      id: old.isEmpty ? 'search_${++_nextId}' : old.first.id,
      query: query,
      submittedAt: DateTime.now(),
    );
    items.removeWhere(
      (item) => item.query.toLowerCase() == query.toLowerCase(),
    );
    items.insert(0, entry);
    if (items.length > 10) items.removeRange(10, items.length);
    return entry;
  }

  @override
  Future<void> deleteSearchQuery(String uid, String id) async {
    if (failHistoryWrite) throw StateError('Offline');
    history[uid]?.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clearSearchHistory(String uid) async {
    if (failHistoryWrite) throw StateError('Offline');
    history[uid] = [];
  }

  @override
  Future<List<Bookmark>> getBookmarks(String uid) async {
    if (pendingBookmarks.containsKey(uid)) return pendingBookmarks[uid]!.future;
    if (failBookmarksLoad) throw StateError('Offline');
    return List.of(bookmarks[uid] ?? []);
  }

  @override
  Future<Bookmark> createBookmark(
    String uid,
    String bookId,
    double ratio,
    String label,
  ) async {
    if (pendingPersonalWrite != null) await pendingPersonalWrite!.future;
    if (failPersonalWrite) throw StateError('Offline');
    final item = Bookmark(
      id: 'bookmark_${++_nextId}',
      bookId: bookId,
      ratio: ratio,
      label: label,
    );
    bookmarks.putIfAbsent(uid, () => []).add(item);
    return item;
  }

  @override
  Future<void> deleteBookmark(String uid, String bookmarkId) async {
    if (failPersonalWrite) throw StateError('Offline');
    bookmarks[uid]?.removeWhere((item) => item.id == bookmarkId);
  }

  @override
  Future<List<BookNote>> getNotes(String uid) async {
    if (pendingNotes.containsKey(uid)) return pendingNotes[uid]!.future;
    if (failNotesLoad) throw StateError('Offline');
    return List.of(notes[uid] ?? []);
  }

  @override
  Future<BookNote> createNote(String uid, String bookId, String text) async {
    if (pendingPersonalWrite != null) await pendingPersonalWrite!.future;
    if (failPersonalWrite) throw StateError('Offline');
    final item = BookNote(id: 'note_${++_nextId}', bookId: bookId, text: text);
    notes.putIfAbsent(uid, () => []).add(item);
    return item;
  }

  @override
  Future<void> updateNote(String uid, String noteId, String text) async {
    if (failPersonalWrite) throw StateError('Offline');
    final items = notes[uid] ?? [];
    final index = items.indexWhere((item) => item.id == noteId);
    if (index < 0) throw StateError('Note missing');
    items[index] = items[index].withText(text);
  }

  @override
  Future<void> deleteNote(String uid, String noteId) async {
    if (failPersonalWrite) throw StateError('Offline');
    notes[uid]?.removeWhere((item) => item.id == noteId);
  }
}
