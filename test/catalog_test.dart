import 'package:app_ebook/controllers/catalog_controller.dart';
import 'package:app_ebook/models/book.dart';
import 'package:app_ebook/models/category.dart';
import 'package:app_ebook/repositories/catalog_repository.dart';
import 'package:app_ebook/repositories/sample_catalog_repository.dart';
import 'package:app_ebook/widgets/book_cover.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCatalogRepository implements CatalogRepository {
  final books = [
    Book(
      id: 'one',
      title: 'Moonlight Stories',
      author: 'Alice Writer',
      coverImage: 'generated:midnight',
      description: 'A sample description',
      categoryIds: ['short'],
      content: 'Sample content',
    ),
    Book(
      id: 'two',
      title: 'Ocean Tales',
      author: 'Bob Author',
      coverImage: 'missing.jpg',
      description: 'Another description',
      categoryIds: ['fiction'],
      content: 'More content',
    ),
  ];

  final categories = [
    Category(id: 'short', name: 'Short Stories', description: 'Short reads'),
    Category(id: 'fiction', name: 'Fiction', description: 'Fiction books'),
  ];

  @override
  Future<List<Book>> getBooks() async => books;

  @override
  Future<List<Category>> getCategories() async => categories;
}

void main() {
  test('Book and Category expose immutable catalog fields', () {
    final input = ['short'];
    final book = Book(
      id: 'one',
      title: 'Title',
      author: 'Author',
      coverImage: 'cover.jpg',
      description: 'Description',
      categoryIds: input,
      content: 'Content',
    );
    final category = Category(
      id: 'short',
      name: 'Short Stories',
      description: 'Short reads',
    );

    input.add('Fiction');
    expect(book.categoryIds, ['short']);
    expect(() => book.categoryIds.add('Fiction'), throwsUnsupportedError);
    expect(category.name, 'Short Stories');
  });

  test('Sample repository supplies the existing catalog', () async {
    final repository = SampleCatalogRepository();
    final books = await repository.getBooks();
    final categories = await repository.getCategories();

    expect(books, hasLength(11));
    expect(categories, hasLength(13));
    expect(books.first.title, 'The Lantern Between Towns');
    expect(categories.first.name, 'Short Stories');
    expect(books.map((book) => book.id).toSet(), {
      for (var id = 1; id <= 11; id++) '$id',
    });
    final categoryIds = categories.map((category) => category.id).toSet();
    for (final book in books) {
      expect(book.description.trim(), isNotEmpty, reason: book.id);
      expect(book.content.trim(), isNotEmpty, reason: book.id);
      expect(book.content.length, lessThanOrEqualTo(2000), reason: book.id);
      expect(
        BookCover.isGeneratedStyle(book.coverImage),
        isTrue,
        reason: book.id,
      );
      expect(book.createdAt, isNotNull, reason: book.id);
      expect(
        book.categoryIds.every(categoryIds.contains),
        isTrue,
        reason: '${book.id} has an unknown category ID',
      );
    }
    final controller = CatalogController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    expect(
      controller.moreFromAuthor(books.first).map((book) => book.id),
      contains('4'),
    );
    expect(controller.recentlyAddedBooks.first.id, '1');
  });

  test('Controller loads, searches, and filters one shared catalog', () async {
    final controller = CatalogController(FakeCatalogRepository());
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.books, hasLength(2));
    expect(controller.categories, hasLength(2));
    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
    expect(() => controller.books.clear(), throwsUnsupportedError);
    expect(controller.search('MOONLIGHT').single.id, 'one');
    expect(controller.search('alice writer').single.id, 'one');
    expect(controller.search('  ALICE   WRITER  ').single.id, 'one');
    expect(controller.search('  OCEAN  ').single.id, 'two');
    expect(controller.search('  '), isEmpty);
    expect(controller.search('missing'), isEmpty);
    expect(controller.inCategory('short').single.id, 'one');
    expect(controller.inCategory('Unknown'), isEmpty);
    expect(controller.categoryName('short'), 'Short Stories');
  });

  test('Renaming a category keeps book relationships intact', () async {
    final repository = FakeCatalogRepository();
    repository.categories[0] = Category(
      id: 'short',
      name: 'Quick Reads',
      description: 'Short reads',
    );
    final controller = CatalogController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.categoryName('short'), 'Quick Reads');
    expect(controller.inCategory('short').single.title, 'Moonlight Stories');
  });
}
