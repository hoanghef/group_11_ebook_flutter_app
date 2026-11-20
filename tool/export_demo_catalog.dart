import 'dart:convert';
import 'dart:io';

import 'package:app_ebook/data/categories.dart';
import 'package:app_ebook/data/sample_books.dart';

const coverStyles = {
  'generated:midnight',
  'generated:lagoon',
  'generated:coral',
  'generated:forest',
  'generated:plum',
  'generated:sunrise',
};

void main() {
  final categories = SampleCategories.getAllCategories();
  final books = SampleBooks.getAllBooks();
  final categoryIds = categories.map((category) => category.id).toSet();
  final bookIds = books.map((book) => book.id).toSet();
  if (categories.length != 13 || categoryIds.length != 13) {
    throw StateError('Expected 13 distinct demo categories.');
  }
  if (books.length != 11 || bookIds.length != 11) {
    throw StateError('Expected 11 distinct demo books.');
  }
  for (final book in books) {
    if (book.createdAt == null ||
        book.categoryIds.isEmpty ||
        book.categoryIds.length > 5 ||
        !categoryIds.containsAll(book.categoryIds) ||
        !coverStyles.contains(book.coverImage) ||
        book.content.length > 2000) {
      throw StateError('Invalid demo book: ${book.id}');
    }
  }
  final result = {
    'categories': categories
        .map(
          (category) => {
            'id': category.id,
            'name': category.name,
            'description': category.description,
            'active': true,
          },
        )
        .toList(),
    'books': books
        .map(
          (book) => {
            'id': book.id,
            'title': book.title,
            'author': book.author,
            'description': book.description,
            'coverRef': book.coverImage,
            'categoryIds': book.categoryIds,
            'status': 'published',
            'preview': book.content.trim(),
            'contentRef': book.contentRef ?? '',
            'createdAt': book.createdAt!.toUtc().toIso8601String(),
          },
        )
        .toList(),
  };
  stdout.writeln(jsonEncode(result));
}
