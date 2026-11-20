import '../data/categories.dart';
import '../data/sample_books.dart';
import '../models/book.dart';
import '../models/category.dart';
import 'catalog_repository.dart';

class SampleCatalogRepository implements CatalogRepository {
  @override
  Future<List<Book>> getBooks() async => SampleBooks.getAllBooks();

  @override
  Future<List<Category>> getCategories() async =>
      SampleCategories.getAllCategories();
}
