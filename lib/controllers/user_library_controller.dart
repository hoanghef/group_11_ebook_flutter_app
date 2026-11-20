import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/book_note.dart';
import '../models/bookmark.dart';
import '../models/reading_progress_entry.dart';
import '../models/search_history_entry.dart';
import '../repositories/user_library_repository.dart';
import 'auth_controller.dart';

class UserLibraryController extends ChangeNotifier {
  UserLibraryController(this.auth, this.repository) {
    auth.addListener(_syncUser);
    _syncUser();
  }

  final AuthController auth;
  final UserLibraryRepository repository;
  String? _uid;
  int _generation = 0;
  bool _disposed = false;
  Set<String> _favoriteIds = {};
  final Set<String> _writingFavorites = {};
  final Map<String, double> _unsavedProgress = {};
  final Map<String, Future<void>> _progressWrites = {};
  List<Bookmark> _bookmarks = [];
  List<BookNote> _notes = [];
  List<ReadingProgressEntry> _recentProgress = [];
  List<SearchHistoryEntry> _searchHistory = [];

  String? get uid => _uid;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);
  List<BookNote> get notes => List.unmodifiable(_notes);
  List<ReadingProgressEntry> get recentProgress =>
      List.unmodifiable(_recentProgress);
  List<SearchHistoryEntry> get searchHistory =>
      List.unmodifiable(_searchHistory);
  bool isLoadingRecentProgress = false;
  bool isLoadingSearchHistory = false;
  bool isWritingSearchHistory = false;
  String? recentProgressError;
  String? searchHistoryError;
  bool isLoadingFavorites = false;
  bool isLoadingBookmarks = false;
  bool isLoadingNotes = false;
  bool isWritingBookmark = false;
  bool isWritingNote = false;
  String? favoritesError;
  String? bookmarksError;
  String? notesError;
  String? progressError;
  bool progressLoadFailed = false;

  bool isFavorite(String bookId) => _favoriteIds.contains(bookId);
  bool isWritingFavorite(String bookId) => _writingFavorites.contains(bookId);
  bool get isWritingFavorites => _writingFavorites.isNotEmpty;

  bool _isCurrent(String uid, int generation) =>
      !_disposed && _uid == uid && _generation == generation;

  void _syncUser() {
    final nextUid = auth.status == AuthStatus.signedIn
        ? auth.currentUser?.uid
        : null;
    if (nextUid == _uid) return;
    _uid = nextUid;
    _generation++;
    _favoriteIds = {};
    _writingFavorites.clear();
    _unsavedProgress.clear();
    _progressWrites.clear();
    _bookmarks = [];
    _notes = [];
    _recentProgress = [];
    _searchHistory = [];
    isLoadingFavorites = false;
    isLoadingBookmarks = false;
    isLoadingNotes = false;
    isWritingBookmark = false;
    isWritingNote = false;
    isLoadingRecentProgress = false;
    isLoadingSearchHistory = false;
    isWritingSearchHistory = false;
    favoritesError = null;
    bookmarksError = null;
    notesError = null;
    progressError = null;
    progressLoadFailed = false;
    recentProgressError = null;
    searchHistoryError = null;
    notifyListeners();
    if (nextUid != null) {
      unawaited(loadFavorites());
      unawaited(loadBookmarks());
      unawaited(loadNotes());
      unawaited(loadRecentProgress());
      unawaited(loadSearchHistory());
    }
  }

  Future<void> loadFavorites() async {
    final uid = _uid;
    if (uid == null) return;
    final generation = _generation;
    _favoriteIds = {};
    isLoadingFavorites = true;
    favoritesError = null;
    notifyListeners();
    try {
      final ids = await repository.getFavorites(uid);
      if (!_isCurrent(uid, generation)) return;
      _favoriteIds = ids;
    } catch (_) {
      if (!_isCurrent(uid, generation)) return;
      favoritesError = 'Favorites could not load.';
    } finally {
      if (_isCurrent(uid, generation)) {
        isLoadingFavorites = false;
        notifyListeners();
      }
    }
  }

  Future<bool> setFavorite(String bookId, bool favorite) async {
    final uid = _uid;
    if (uid == null ||
        isLoadingFavorites ||
        favoritesError != null ||
        _writingFavorites.contains(bookId)) {
      return false;
    }
    if (_favoriteIds.contains(bookId) == favorite) return true;
    final generation = _generation;
    _writingFavorites.add(bookId);
    notifyListeners();
    try {
      await repository.setFavorite(uid, bookId, favorite);
      if (!_isCurrent(uid, generation)) return false;
      if (favorite) {
        _favoriteIds.add(bookId);
      } else {
        _favoriteIds.remove(bookId);
      }
      return true;
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        favoritesError = 'Favorite could not be saved. Retry.';
      }
      return false;
    } finally {
      if (_isCurrent(uid, generation)) {
        _writingFavorites.remove(bookId);
        notifyListeners();
      }
    }
  }

  Future<bool> clearFavorites() async {
    final uid = _uid;
    if (uid == null || isLoadingFavorites || isWritingFavorites) return false;
    final generation = _generation;
    try {
      await repository.clearFavorites(uid);
      if (!_isCurrent(uid, generation)) return false;
      _favoriteIds = {};
      favoritesError = null;
      notifyListeners();
      return true;
    } catch (_) {
      if (_isCurrent(uid, generation)) await loadFavorites();
      if (_isCurrent(uid, generation)) {
        favoritesError = 'Favorites could not be cleared. Retry.';
        notifyListeners();
      }
      return false;
    }
  }

  Future<double?> loadReadingProgress(String bookId) async {
    final uid = _uid;
    if (uid == null) return null;
    final generation = _generation;
    if (_unsavedProgress.containsKey(bookId)) {
      progressLoadFailed = false;
      return _unsavedProgress[bookId];
    }
    try {
      final ratio = await repository.getReadingProgress(uid, bookId);
      if (!_isCurrent(uid, generation)) return null;
      progressLoadFailed = false;
      progressError = null;
      notifyListeners();
      return ratio;
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        progressLoadFailed = true;
        progressError = 'Reading position could not load.';
        notifyListeners();
      }
      return null;
    }
  }

  Future<bool> saveReadingProgress(String bookId, double ratio) async {
    final uid = _uid;
    if (uid == null || !ratio.isFinite) return false;
    final generation = _generation;
    final value = ratio.clamp(0.0, 1.0);
    _unsavedProgress[bookId] = value;
    final previous = _progressWrites[bookId] ?? Future<void>.value();
    final result = previous.then((_) async {
      if (!_isCurrent(uid, generation)) return false;
      try {
        await repository.saveReadingProgress(uid, bookId, value);
        if (!_isCurrent(uid, generation)) return false;
        if (_unsavedProgress[bookId] == value) _unsavedProgress.remove(bookId);
        progressLoadFailed = false;
        progressError = null;
        _recentProgress = [
          ReadingProgressEntry(
            bookId: bookId,
            ratio: value,
            updatedAt: DateTime.now(),
          ),
          ..._recentProgress.where((item) => item.bookId != bookId),
        ].take(20).toList();
        notifyListeners();
        return true;
      } catch (_) {
        if (_isCurrent(uid, generation)) {
          progressError = 'Reading position could not save. Retry.';
          notifyListeners();
        }
        return false;
      }
    });
    _progressWrites[bookId] = result.then((_) {});
    return result;
  }

  Future<void> loadRecentProgress() async {
    final uid = _uid;
    if (uid == null) return;
    final generation = _generation;
    _recentProgress = [];
    isLoadingRecentProgress = true;
    recentProgressError = null;
    notifyListeners();
    try {
      final entries = await repository.getRecentReadingProgress(uid);
      if (_isCurrent(uid, generation)) _recentProgress = entries;
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        recentProgressError = 'Continue Reading could not load.';
      }
    } finally {
      if (_isCurrent(uid, generation)) {
        isLoadingRecentProgress = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadSearchHistory() async {
    final uid = _uid;
    if (uid == null) return;
    final generation = _generation;
    _searchHistory = [];
    isLoadingSearchHistory = true;
    searchHistoryError = null;
    notifyListeners();
    try {
      final entries = await repository.getSearchHistory(uid);
      if (_isCurrent(uid, generation)) {
        _searchHistory = entries.take(10).toList();
      }
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        searchHistoryError = 'Recent searches could not load.';
      }
    } finally {
      if (_isCurrent(uid, generation)) {
        isLoadingSearchHistory = false;
        notifyListeners();
      }
    }
  }

  Future<bool> submitSearchQuery(String query) async {
    final uid = _uid;
    final value = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (uid == null ||
        value.isEmpty ||
        value.length > 100 ||
        isLoadingSearchHistory ||
        isWritingSearchHistory ||
        searchHistoryError != null) {
      return false;
    }
    final generation = _generation;
    isWritingSearchHistory = true;
    notifyListeners();
    try {
      final entry = await repository.submitSearchQuery(uid, value);
      if (!_isCurrent(uid, generation)) return false;
      _searchHistory = [
        entry,
        ..._searchHistory.where(
          (item) => item.query.toLowerCase() != value.toLowerCase(),
        ),
      ].take(10).toList();
      searchHistoryError = null;
      return true;
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        searchHistoryError = 'Search history could not save. Retry.';
      }
      return false;
    } finally {
      if (_isCurrent(uid, generation)) {
        isWritingSearchHistory = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteSearchQuery(String id) async {
    final uid = _uid;
    if (uid == null || isWritingSearchHistory) return false;
    final generation = _generation;
    isWritingSearchHistory = true;
    notifyListeners();
    try {
      await repository.deleteSearchQuery(uid, id);
      if (!_isCurrent(uid, generation)) return false;
      _searchHistory = _searchHistory.where((item) => item.id != id).toList();
      searchHistoryError = null;
      return true;
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        searchHistoryError = 'Search history could not update. Retry.';
      }
      return false;
    } finally {
      if (_isCurrent(uid, generation)) {
        isWritingSearchHistory = false;
        notifyListeners();
      }
    }
  }

  Future<bool> clearSearchHistory() async {
    final uid = _uid;
    if (uid == null || isWritingSearchHistory) return false;
    final generation = _generation;
    isWritingSearchHistory = true;
    notifyListeners();
    try {
      await repository.clearSearchHistory(uid);
      if (!_isCurrent(uid, generation)) return false;
      _searchHistory = [];
      searchHistoryError = null;
      return true;
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        searchHistoryError = 'Search history could not clear. Retry.';
      }
      return false;
    } finally {
      if (_isCurrent(uid, generation)) {
        isWritingSearchHistory = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadBookmarks() async {
    final uid = _uid;
    if (uid == null) return;
    final generation = _generation;
    _bookmarks = [];
    isLoadingBookmarks = true;
    bookmarksError = null;
    notifyListeners();
    try {
      final items = await repository.getBookmarks(uid);
      if (!_isCurrent(uid, generation)) return;
      _bookmarks = items;
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        bookmarksError = 'Bookmarks could not load.';
      }
    } finally {
      if (_isCurrent(uid, generation)) {
        isLoadingBookmarks = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createBookmark(String bookId, double ratio, String label) async {
    final uid = _uid;
    if (uid == null ||
        isLoadingBookmarks ||
        isWritingBookmark ||
        !ratio.isFinite ||
        ratio < 0 ||
        ratio > 1 ||
        label.length > 80) {
      return false;
    }
    final generation = _generation;
    isWritingBookmark = true;
    notifyListeners();
    try {
      final item = await repository.createBookmark(uid, bookId, ratio, label);
      if (!_isCurrent(uid, generation)) return false;
      _bookmarks = [..._bookmarks, item];
      bookmarksError = null;
      return true;
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        bookmarksError = 'Bookmark could not be saved. Retry.';
      }
      return false;
    } finally {
      if (_isCurrent(uid, generation)) {
        isWritingBookmark = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteBookmark(String bookmarkId) async {
    final uid = _uid;
    if (uid == null || isWritingBookmark) return false;
    final generation = _generation;
    isWritingBookmark = true;
    notifyListeners();
    try {
      await repository.deleteBookmark(uid, bookmarkId);
      if (!_isCurrent(uid, generation)) return false;
      _bookmarks = _bookmarks.where((item) => item.id != bookmarkId).toList();
      bookmarksError = null;
      return true;
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        bookmarksError = 'Bookmark could not be deleted. Retry.';
      }
      return false;
    } finally {
      if (_isCurrent(uid, generation)) {
        isWritingBookmark = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadNotes() async {
    final uid = _uid;
    if (uid == null) return;
    final generation = _generation;
    _notes = [];
    isLoadingNotes = true;
    notesError = null;
    notifyListeners();
    try {
      final items = await repository.getNotes(uid);
      if (!_isCurrent(uid, generation)) return;
      _notes = items;
    } catch (_) {
      if (_isCurrent(uid, generation)) notesError = 'Notes could not load.';
    } finally {
      if (_isCurrent(uid, generation)) {
        isLoadingNotes = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createNote(String bookId, String text) async {
    final uid = _uid;
    final value = text.trim();
    if (uid == null ||
        isLoadingNotes ||
        isWritingNote ||
        value.isEmpty ||
        value.length > 2000) {
      return false;
    }
    final generation = _generation;
    isWritingNote = true;
    notifyListeners();
    try {
      final item = await repository.createNote(uid, bookId, value);
      if (!_isCurrent(uid, generation)) return false;
      _notes = [..._notes, item];
      notesError = null;
      return true;
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        notesError = 'Note could not be saved. Retry.';
      }
      return false;
    } finally {
      if (_isCurrent(uid, generation)) {
        isWritingNote = false;
        notifyListeners();
      }
    }
  }

  Future<bool> updateNote(String noteId, String text) async {
    final uid = _uid;
    final value = text.trim();
    if (uid == null || isWritingNote || value.isEmpty || value.length > 2000) {
      return false;
    }
    final generation = _generation;
    isWritingNote = true;
    notifyListeners();
    try {
      await repository.updateNote(uid, noteId, value);
      if (!_isCurrent(uid, generation)) return false;
      _notes = _notes
          .map((item) => item.id == noteId ? item.withText(value) : item)
          .toList();
      notesError = null;
      return true;
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        notesError = 'Note could not be updated. Retry.';
      }
      return false;
    } finally {
      if (_isCurrent(uid, generation)) {
        isWritingNote = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteNote(String noteId) async {
    final uid = _uid;
    if (uid == null || isWritingNote) return false;
    final generation = _generation;
    isWritingNote = true;
    notifyListeners();
    try {
      await repository.deleteNote(uid, noteId);
      if (!_isCurrent(uid, generation)) return false;
      _notes = _notes.where((item) => item.id != noteId).toList();
      notesError = null;
      return true;
    } catch (_) {
      if (_isCurrent(uid, generation)) {
        notesError = 'Note could not be deleted. Retry.';
      }
      return false;
    } finally {
      if (_isCurrent(uid, generation)) {
        isWritingNote = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    auth.removeListener(_syncUser);
    super.dispose();
  }
}
