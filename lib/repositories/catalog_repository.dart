import '../models/book.dart';
import '../models/category.dart';

abstract class CatalogRepository {
  Future<List<Book>> getBooks();
  Future<List<Category>> getCategories();
}
