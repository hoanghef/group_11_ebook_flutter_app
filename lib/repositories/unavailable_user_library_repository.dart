import '../models/book_note.dart';
import '../models/bookmark.dart';
import '../models/reading_progress_entry.dart';
import '../models/search_history_entry.dart';
import 'user_library_repository.dart';

class UnavailableUserLibraryRepository implements UserLibraryRepository {
  Never _unavailable() => throw StateError('Firebase is not configured.');

  @override
  Future<Set<String>> getFavorites(String uid) async => _unavailable();

  @override
  Future<void> setFavorite(String uid, String bookId, bool favorite) async =>
      _unavailable();

  @override
  Future<void> clearFavorites(String uid) async => _unavailable();

  @override
  Future<double?> getReadingProgress(String uid, String bookId) async =>
      _unavailable();

  @override
  Future<void> saveReadingProgress(
    String uid,
    String bookId,
    double ratio,
  ) async => _unavailable();

  @override
  Future<List<ReadingProgressEntry>> getRecentReadingProgress(
    String uid,
  ) async => _unavailable();

  @override
  Future<List<SearchHistoryEntry>> getSearchHistory(String uid) async =>
      _unavailable();

  @override
  Future<SearchHistoryEntry> submitSearchQuery(
    String uid,
    String query,
  ) async => _unavailable();

  @override
  Future<void> deleteSearchQuery(String uid, String id) async => _unavailable();

  @override
  Future<void> clearSearchHistory(String uid) async => _unavailable();

  @override
  Future<List<Bookmark>> getBookmarks(String uid) async => _unavailable();

  @override
  Future<Bookmark> createBookmark(
    String uid,
    String bookId,
    double ratio,
    String label,
  ) async => _unavailable();

  @override
  Future<void> deleteBookmark(String uid, String bookmarkId) async =>
      _unavailable();

  @override
  Future<List<BookNote>> getNotes(String uid) async => _unavailable();

  @override
  Future<BookNote> createNote(String uid, String bookId, String text) async =>
      _unavailable();

  @override
  Future<void> updateNote(String uid, String noteId, String text) async =>
      _unavailable();

  @override
  Future<void> deleteNote(String uid, String noteId) async => _unavailable();
}
