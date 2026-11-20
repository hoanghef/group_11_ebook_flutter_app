import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/admin_book.dart';
import '../models/category.dart';
import '../repositories/admin_catalog_repository.dart';
import 'admin_access_controller.dart';
import 'admin_catalog_validator.dart';

class AdminCatalogController extends ChangeNotifier {
  AdminCatalogController(this.access, this.repository) {
    access.addListener(_syncAccess);
    _syncAccess();
  }

  final AdminAccessController access;
  final AdminCatalogRepository repository;
  String? _uid;
  bool _active = false;
  bool _disposed = false;
  int _generation = 0;
  List<AdminBook> _books = [];
  List<Category> _categories = [];

  List<AdminBook> get books => List.unmodifiable(_books);
  List<Category> get categories => List.unmodifiable(_categories);
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  bool _current(String uid, int generation) =>
      !_disposed &&
      _active &&
      _uid == uid &&
      _generation == generation &&
      access.isAdmin;

  void _syncAccess() {
    final nextActive = access.isAdmin && !access.isLoading;
    final nextUid = access.uid;
    if (nextActive == _active && nextUid == _uid) return;
    _uid = nextUid;
    _active = nextActive;
    _generation++;
    _books = [];
    _categories = [];
    isLoading = false;
    isSaving = false;
    error = null;
    notifyListeners();
    if (_active) unawaited(load());
  }

  Future<void> load() async {
    final uid = _uid;
    if (uid == null || !_active) return;
    final generation = _generation;
    isLoading = true;
    error = null;
    _books = [];
    _categories = [];
    notifyListeners();
    try {
      final books = await repository.getAllBooks();
      final categories = await repository.getAllCategories();
      if (!_current(uid, generation)) return;
      _books = books;
      _categories = categories;
    } catch (cause) {
      if (_current(uid, generation)) {
        error = _message(cause, 'Catalog could not load.');
      }
    } finally {
      if (_current(uid, generation)) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<String?> saveBook(AdminBook book, {AdminBook? original}) async {
    final uid = _uid;
    if (uid == null || !_active || !access.isAdmin) {
      return 'Admin access required.';
    }
    if (isSaving || isLoading) return 'Please wait for the current request.';
    final validation = AdminCatalogValidator.bookError(
      book,
      _categories,
      original: original,
    );
    if (validation != null) return validation;
    if (original == null && _books.any((item) => item.id == book.id)) {
      return 'Book ID already exists.';
    }
    final generation = _generation;
    isSaving = true;
    notifyListeners();
    try {
      await repository.saveBook(book, create: original == null);
      if (!_current(uid, generation)) return 'Admin session changed.';
      await load();
      return null;
    } catch (cause) {
      return _message(cause, 'Book could not be saved. Try again.');
    } finally {
      if (_current(uid, generation)) {
        isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<String?> saveCategory(Category category, {Category? original}) async {
    final uid = _uid;
    if (uid == null || !_active || !access.isAdmin) {
      return 'Admin access required.';
    }
    if (isSaving || isLoading) return 'Please wait for the current request.';
    final validation = AdminCatalogValidator.categoryError(
      category,
      original: original,
    );
    if (validation != null) return validation;
    if (original == null && _categories.any((item) => item.id == category.id)) {
      return 'Category ID already exists.';
    }
    final generation = _generation;
    isSaving = true;
    notifyListeners();
    try {
      await repository.saveCategory(category, create: original == null);
      if (!_current(uid, generation)) return 'Admin session changed.';
      await load();
      return null;
    } catch (cause) {
      return _message(cause, 'Category could not be saved. Try again.');
    } finally {
      if (_current(uid, generation)) {
        isSaving = false;
        notifyListeners();
      }
    }
  }

  String _message(Object cause, String fallback) =>
      cause is AdminCatalogFailure ? cause.message : fallback;

  @override
  void dispose() {
    _disposed = true;
    access.removeListener(_syncAccess);
    super.dispose();
  }
}
