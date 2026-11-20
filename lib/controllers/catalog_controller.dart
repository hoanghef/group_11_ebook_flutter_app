import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/book.dart';
import '../models/category.dart';
import '../repositories/catalog_repository.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this.repository);

  final CatalogRepository repository;
  List<Book> _books = const [];
  List<Category> _categories = const [];
  bool _disposed = false;
  bool isLoading = false;
  Object? error;

  List<Book> get books => _books;
  List<Category> get categories => _categories;
  Category? categoryById(String id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  String categoryName(String id) => categoryById(id)?.name ?? id;
  List<Book> get featuredBooks => _books.take(5).toList(growable: false);
  List<Book> get recentlyAddedBooks => List.of(_books)
    ..sort((a, b) {
      final dates = switch ((a.createdAt, b.createdAt)) {
        (final DateTime aDate, final DateTime bDate) => bDate.compareTo(aDate),
        (DateTime(), null) => -1,
        (null, DateTime()) => 1,
        _ => 0,
      };
      return dates != 0 ? dates : a.id.compareTo(b.id);
    });

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final books = await repository.getBooks();
      final categories = await repository.getCategories();
      if (_disposed) return;
      _books = List.unmodifiable(books.where((book) => book.isPublished));
      _categories = List.unmodifiable(
        categories.where((category) => category.isActive),
      );
    } catch (cause) {
      if (!_disposed) error = cause;
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  List<Book> search(String query) {
    final normalized = query
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
    if (normalized.isEmpty) return const [];
    return _books
        .where(
          (book) =>
              book.title.toLowerCase().contains(normalized) ||
              book.author.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  List<Book> inCategory(String categoryId) => _books
      .where((book) => book.categoryIds.contains(categoryId))
      .toList(growable: false);

  List<Book> moreFromAuthor(Book book) => _books
      .where(
        (candidate) =>
            candidate.id != book.id &&
            candidate.author.trim().toLowerCase() ==
                book.author.trim().toLowerCase(),
      )
      .toList(growable: false);
}
