import '../models/admin_book.dart';
import '../models/category.dart';
import 'admin_catalog_repository.dart';

class UnavailableAdminCatalogRepository implements AdminCatalogRepository {
  Never _fail() =>
      throw const AdminCatalogFailure('Firebase is not configured.');
  @override
  Future<List<AdminBook>> getAllBooks() async => _fail();
  @override
  Future<List<Category>> getAllCategories() async => _fail();
  @override
  Future<void> saveBook(AdminBook book, {required bool create}) async =>
      _fail();
  @override
  Future<void> saveCategory(Category category, {required bool create}) async =>
      _fail();
}
