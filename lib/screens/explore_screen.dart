import 'package:flutter/material.dart';
import '../controllers/catalog_scope.dart';
import '../models/book.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';
import 'category_books_screen.dart';
import 'catalog_state_view.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.of(context);
    final categories = catalog.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: CatalogStateView(
        isEmpty: !categories
            .take(3)
            .any((category) => catalog.inCategory(category.id).isNotEmpty),
        emptyMessage: 'No categories or books available',
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Categories Section
              ...categories.take(3).map((category) {
                // Lọc sách theo category
                final categoryBooks = catalog
                    .inCategory(category.id)
                    .take(3)
                    .toList();

                if (categoryBooks.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryBooksScreen(
                                    categoryId: category.id,
                                  ),
                                ),
                              );
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categoryBooks.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(
                            categoryBooks[index],
                            context,
                            category.id,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(Book book, BuildContext context, String categoryId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'book_${book.id}_explore_$categoryId',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BookCover(book: book, width: 120, height: 160),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              book.author,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
