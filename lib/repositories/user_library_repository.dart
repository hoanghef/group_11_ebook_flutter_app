import '../models/book_note.dart';
import '../models/bookmark.dart';
import '../models/reading_progress_entry.dart';
import '../models/search_history_entry.dart';

abstract class UserLibraryRepository {
  Future<Set<String>> getFavorites(String uid);
  Future<void> setFavorite(String uid, String bookId, bool favorite);
  Future<void> clearFavorites(String uid);
  Future<double?> getReadingProgress(String uid, String bookId);
  Future<void> saveReadingProgress(String uid, String bookId, double ratio);
  Future<List<ReadingProgressEntry>> getRecentReadingProgress(String uid);
  Future<List<SearchHistoryEntry>> getSearchHistory(String uid);
  Future<SearchHistoryEntry> submitSearchQuery(String uid, String query);
  Future<void> deleteSearchQuery(String uid, String id);
  Future<void> clearSearchHistory(String uid);
  Future<List<Bookmark>> getBookmarks(String uid);
  Future<Bookmark> createBookmark(
    String uid,
    String bookId,
    double ratio,
    String label,
  );
  Future<void> deleteBookmark(String uid, String bookmarkId);
  Future<List<BookNote>> getNotes(String uid);
  Future<BookNote> createNote(String uid, String bookId, String text);
  Future<void> updateNote(String uid, String noteId, String text);
  Future<void> deleteNote(String uid, String noteId);
}
