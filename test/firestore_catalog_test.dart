import 'package:app_ebook/repositories/firestore_catalog_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final stamp = Timestamp.fromDate(DateTime.utc(2026, 1, 1));

  test('Firestore book metadata maps without embedding full content', () {
    final book = FirestoreCatalogRepository.bookFromData('book_one', {
      'id': 'book_one',
      'title': 'A book',
      'author': 'An author',
      'description': 'Description',
      'coverRef': 'generated:midnight',
      'categoryIds': ['fiction'],
      'status': 'published',
      'preview': 'Short excerpt',
      'contentRef': 'storage/books/book_one.epub',
      'createdAt': stamp,
      'updatedAt': stamp,
    });

    expect(book.id, 'book_one');
    expect(book.categoryIds, ['fiction']);
    expect(book.content, 'Short excerpt');
    expect(book.contentRef, 'storage/books/book_one.epub');
    expect(book.isPublished, isTrue);
    expect(book.createdAt?.toUtc(), DateTime.utc(2026, 1, 1));
  });

  test('Firestore category uses stable document ID and active state', () {
    final category = FirestoreCatalogRepository.categoryFromData('fiction', {
      'id': 'fiction',
      'name': 'New display name',
      'description': 'Description',
      'active': true,
      'createdAt': stamp,
      'updatedAt': stamp,
    });
    expect(category.id, 'fiction');
    expect(category.name, 'New display name');
    expect(category.isActive, isTrue);
  });

  test('Mismatched document IDs are rejected', () {
    expect(
      () =>
          FirestoreCatalogRepository.bookFromData('book_one', {'id': 'other'}),
      throwsFormatException,
    );
    expect(
      () => FirestoreCatalogRepository.categoryFromData('fiction', {
        'id': 'other',
      }),
      throwsFormatException,
    );
  });
}
