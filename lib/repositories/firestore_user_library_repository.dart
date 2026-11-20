import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book_note.dart';
import '../models/bookmark.dart';
import '../models/reading_progress_entry.dart';
import '../models/search_history_entry.dart';
import 'user_library_repository.dart';

class FirestoreUserLibraryRepository implements UserLibraryRepository {
  FirestoreUserLibraryRepository(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _favorites(String uid) =>
      firestore.collection('users').doc(uid).collection('favorites');

  DocumentReference<Map<String, dynamic>> _progress(
    String uid,
    String bookId,
  ) => firestore
      .collection('users')
      .doc(uid)
      .collection('readingProgress')
      .doc(bookId);

  CollectionReference<Map<String, dynamic>> _bookmarks(String uid) =>
      firestore.collection('users').doc(uid).collection('bookmarks');

  CollectionReference<Map<String, dynamic>> _notes(String uid) =>
      firestore.collection('users').doc(uid).collection('notes');

  CollectionReference<Map<String, dynamic>> _readingProgress(String uid) =>
      firestore.collection('users').doc(uid).collection('readingProgress');

  CollectionReference<Map<String, dynamic>> _searchHistory(String uid) =>
      firestore.collection('users').doc(uid).collection('searchHistory');

  static Bookmark bookmarkFromData(String id, Map<String, dynamic> data) =>
      Bookmark(
        id: id,
        bookId: data['bookId'] as String,
        ratio: (data['ratio'] as num).toDouble(),
        label: data['label'] as String,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );

  static BookNote noteFromData(String id, Map<String, dynamic> data) =>
      BookNote(
        id: id,
        bookId: data['bookId'] as String,
        text: data['text'] as String,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );

  @override
  Future<Set<String>> getFavorites(String uid) async {
    final snapshot = await _favorites(uid).get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  @override
  Future<void> setFavorite(String uid, String bookId, bool favorite) async {
    final document = _favorites(uid).doc(bookId);
    if (favorite) {
      await document.set({
        'bookId': bookId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await document.delete();
    }
  }

  @override
  Future<void> clearFavorites(String uid) async {
    final snapshot = await _favorites(uid).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<double?> getReadingProgress(String uid, String bookId) async {
    final snapshot = await _progress(uid, bookId).get();
    final ratio = snapshot.data()?['ratio'];
    if (ratio is! num) return null;
    return ratio.toDouble().clamp(0.0, 1.0);
  }

  @override
  Future<void> saveReadingProgress(String uid, String bookId, double ratio) =>
      _progress(uid, bookId).set({
        'bookId': bookId,
        'ratio': ratio.clamp(0.0, 1.0),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<List<ReadingProgressEntry>> getRecentReadingProgress(
    String uid,
  ) async {
    final snapshot = await _readingProgress(
      uid,
    ).orderBy('updatedAt', descending: true).limit(20).get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return ReadingProgressEntry(
            bookId: doc.id,
            ratio: (data['ratio'] as num).toDouble().clamp(0.0, 1.0),
            updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<SearchHistoryEntry>> getSearchHistory(String uid) async {
    final snapshot = await _searchHistory(
      uid,
    ).orderBy('submittedAt', descending: true).limit(10).get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return SearchHistoryEntry(
            id: doc.id,
            query: data['query'] as String,
            submittedAt: (data['submittedAt'] as Timestamp).toDate(),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<SearchHistoryEntry> submitSearchQuery(String uid, String query) async {
    final collection = _searchHistory(uid);
    final snapshot = await collection
        .orderBy('submittedAt', descending: true)
        .get();
    final existing = snapshot.docs.where(
      (doc) =>
          (doc.data()['query'] as String).toLowerCase() == query.toLowerCase(),
    );
    final reference = existing.isEmpty
        ? collection.doc()
        : existing.first.reference;
    final batch = firestore.batch();
    batch.set(reference, {
      'query': query,
      'submittedAt': FieldValue.serverTimestamp(),
    });
    final remaining = snapshot.docs
        .where((doc) => doc.id != reference.id)
        .toList();
    for (final old in remaining.skip(9)) {
      batch.delete(old.reference);
    }
    await batch.commit();
    return SearchHistoryEntry(
      id: reference.id,
      query: query,
      submittedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteSearchQuery(String uid, String id) =>
      _searchHistory(uid).doc(id).delete();

  @override
  Future<void> clearSearchHistory(String uid) async {
    final snapshot = await _searchHistory(uid).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<List<Bookmark>> getBookmarks(String uid) async {
    final snapshot = await _bookmarks(uid).get();
    return snapshot.docs
        .map((doc) => bookmarkFromData(doc.id, doc.data()))
        .toList(growable: false);
  }

  @override
  Future<Bookmark> createBookmark(
    String uid,
    String bookId,
    double ratio,
    String label,
  ) async {
    final document = _bookmarks(uid).doc();
    final now = DateTime.now();
    await document.set({
      'bookId': bookId,
      'ratio': ratio,
      'label': label,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return Bookmark(
      id: document.id,
      bookId: bookId,
      ratio: ratio,
      label: label,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> deleteBookmark(String uid, String bookmarkId) =>
      _bookmarks(uid).doc(bookmarkId).delete();

  @override
  Future<List<BookNote>> getNotes(String uid) async {
    final snapshot = await _notes(uid).get();
    return snapshot.docs
        .map((doc) => noteFromData(doc.id, doc.data()))
        .toList(growable: false);
  }

  @override
  Future<BookNote> createNote(String uid, String bookId, String text) async {
    final document = _notes(uid).doc();
    final now = DateTime.now();
    await document.set({
      'bookId': bookId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return BookNote(
      id: document.id,
      bookId: bookId,
      text: text,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> updateNote(String uid, String noteId, String text) => _notes(uid)
      .doc(noteId)
      .update({'text': text, 'updatedAt': FieldValue.serverTimestamp()});

  @override
  Future<void> deleteNote(String uid, String noteId) =>
      _notes(uid).doc(noteId).delete();
}
