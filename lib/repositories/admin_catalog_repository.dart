import '../models/admin_book.dart';
import '../models/category.dart';

class AdminCatalogFailure implements Exception {
  const AdminCatalogFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AdminCatalogRepository {
  Future<List<AdminBook>> getAllBooks();
  Future<List<Category>> getAllCategories();
  Future<void> saveBook(AdminBook book, {required bool create});
  Future<void> saveCategory(Category category, {required bool create});
}
