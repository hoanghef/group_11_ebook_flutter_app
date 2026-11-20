import 'package:flutter/material.dart';
import '../controllers/catalog_scope.dart';
import '../controllers/user_library_scope.dart';
import '../models/book.dart';
import '../widgets/book_cover.dart';
import '../models/category.dart';
import 'book_detail_screen.dart';
import 'search_screen.dart';
import 'catalog_state_view.dart';
import 'category_books_screen.dart';
import 'book_reader_screen.dart';

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flutter Ebook App',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: CatalogStateView(
        isEmpty: catalog.books.isEmpty,
        emptyMessage: 'No books available',
        child: ListView(
          children: [
            // Featured Books Slider
            _buildFeaturedBooksSection(catalog.featuredBooks),

            const SizedBox(height: 20),

            // Categories chips
            _buildCategoriesSection(context, catalog.categories),

            const SizedBox(height: 20),

            _buildContinueReading(context),

            // Recently Added section
            _buildRecentlyAddedSection(context, catalog.recentlyAddedBooks),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedBooksSection(List<Book> books) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.take(5).length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Container(
                width: 110,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(book: book),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'book_${book.id}_featured',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: BookCover(book: book, width: 110, height: 140),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    List<Category> categories,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map(
                    (category) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CategoryBooksScreen(categoryId: category.id),
                          ),
                        ),
                        label: Text(
                          category.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueReading(BuildContext context) {
    final library = UserLibraryScope.of(context);
    if (library.uid == null) return const SizedBox.shrink();
    final books = {
      for (final book in CatalogScope.of(context).books) book.id: book,
    };
    final available = library.recentProgress
        .where((entry) => books.containsKey(entry.bookId))
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Continue Reading',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (library.isLoadingRecentProgress)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            )
          else if (library.recentProgressError != null)
            Row(
              children: [
                Expanded(child: Text(library.recentProgressError!)),
                TextButton(
                  onPressed: library.loadRecentProgress,
                  child: const Text('Retry'),
                ),
              ],
            )
          else if (available.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No reading progress in the available catalog.'),
            )
          else
            SizedBox(
              height: 92,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final entry = available[index];
                  final book = books[entry.bookId]!;
                  return SizedBox(
                    width: 170,
                    child: Card(
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookReaderScreen(
                              book: book,
                              initialRatio: entry.ratio,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${(entry.ratio * 100).round()}% of preview',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentlyAddedSection(BuildContext context, List<Book> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Recently Added',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        for (final book in books) _buildBookListItem(book, context),
      ],
    );
  }

  Widget _buildBookListItem(Book book, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Hero(
              tag: 'book_${book.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BookCover(book: book, width: 60, height: 80),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: const TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
