import 'dart:async';

import 'package:app_ebook/models/admin_book.dart';
import 'package:app_ebook/models/category.dart';
import 'package:app_ebook/repositories/admin_access_repository.dart';
import 'package:app_ebook/repositories/admin_catalog_repository.dart';

class FakeAdminAccessRepository implements AdminAccessRepository {
  FakeAdminAccessRepository({this.claim = false});
  final _changes = StreamController<void>.broadcast();
  bool claim;
  bool fail = false;
  Completer<bool>? pending;
  int checks = 0;
  bool lastForce = false;

  @override
  Stream<void> get tokenChanges => _changes.stream;

  void emitToken() => _changes.add(null);

  @override
  Future<bool> hasAdminClaim({bool forceRefresh = false}) async {
    checks++;
    lastForce = forceRefresh;
    if (pending != null) return pending!.future;
    if (fail) throw StateError('Token unavailable');
    return claim;
  }

  Future<void> dispose() => _changes.close();
}

class FakeAdminCatalogRepository implements AdminCatalogRepository {
  final books = <AdminBook>[
    AdminBook(
      id: 'draft_book',
      title: 'Draft Book',
      author: 'Writer',
      description: '',
      coverRef: 'generated:midnight',
      categoryIds: ['fiction'],
      status: 'draft',
      preview: '',
      contentRef: '',
    ),
    AdminBook(
      id: 'archived_book',
      title: 'Archived Book',
      author: 'Writer',
      description: '',
      coverRef: 'generated:lagoon',
      categoryIds: ['hidden'],
      status: 'archived',
      preview: '',
      contentRef: '',
    ),
  ];
  final categories = <Category>[
    Category(id: 'fiction', name: 'Fiction', description: ''),
    Category(id: 'hidden', name: 'Hidden', description: '', isActive: false),
  ];
  bool failLoad = false;
  bool failSave = false;
  Completer<List<AdminBook>>? pendingBooks;
  int bookSaves = 0;
  int categorySaves = 0;

  @override
  Future<List<AdminBook>> getAllBooks() async {
    if (pendingBooks != null) return pendingBooks!.future;
    if (failLoad) {
      throw const AdminCatalogFailure('Catalog unavailable. Retry.');
    }
    return List.of(books);
  }

  @override
  Future<List<Category>> getAllCategories() async {
    if (failLoad) {
      throw const AdminCatalogFailure('Catalog unavailable. Retry.');
    }
    return List.of(categories);
  }

  @override
  Future<void> saveBook(AdminBook book, {required bool create}) async {
    bookSaves++;
    if (failSave) throw const AdminCatalogFailure('Save failed. Retry.');
    if (create) {
      books.add(book);
    } else {
      final index = books.indexWhere((item) => item.id == book.id);
      if (index < 0) throw StateError('Missing book');
      books[index] = book;
    }
  }

  @override
  Future<void> saveCategory(Category category, {required bool create}) async {
    categorySaves++;
    if (failSave) throw const AdminCatalogFailure('Save failed. Retry.');
    if (create) {
      categories.add(category);
    } else {
      final index = categories.indexWhere((item) => item.id == category.id);
      if (index < 0) throw StateError('Missing category');
      categories[index] = category;
    }
  }
}
