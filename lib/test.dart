// Trong main.dart hoặc file test
import 'data/sample_books.dart';
import 'data/categories.dart';

void main() {
  print('Total books: ${SampleBooks.getAllBooks().length}');
  print('Total categories: ${SampleCategories.getAllCategories().length}');
}