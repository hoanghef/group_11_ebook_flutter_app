import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_scope.dart';
import '../controllers/catalog_scope.dart';
import '../models/book.dart';
import '../widgets/book_cover.dart';
import '../controllers/user_library_scope.dart';
import 'book_reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool showFullDescription = false;

  @override
  Widget build(BuildContext context) {
    final signedIn = AuthScope.of(context).status == AuthStatus.signedIn;
    final library = UserLibraryScope.of(context);
    final isFavorite = library.isFavorite(widget.book.id);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (signedIn && library.favoritesError != null)
            IconButton(
              tooltip: 'Retry favorites',
              icon: const Icon(Icons.refresh),
              onPressed: library.loadFavorites,
            ),
          IconButton(
            tooltip: signedIn ? 'Favorite' : 'Sign in to save favorites',
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.black,
            ),
            onPressed:
                !signedIn ||
                    library.isLoadingFavorites ||
                    library.favoritesError != null ||
                    library.isWritingFavorite(widget.book.id)
                ? null
                : () async {
                    final uid = library.uid;
                    final saved = await library.setFavorite(
                      widget.book.id,
                      !isFavorite,
                    );
                    if (!context.mounted || library.uid != uid) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          saved
                              ? (library.isFavorite(widget.book.id)
                                    ? 'Added to favorites'
                                    : 'Removed from favorites')
                              : 'Favorite could not be saved. Retry from Favorites.',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
          ),
          IconButton(
            tooltip: 'Copy book details',
            icon: const Icon(Icons.copy, color: Colors.black),
            onPressed: () async {
              final description = widget.book.description.trim();
              final summary = description.length <= 180
                  ? description
                  : '${description.substring(0, 180)}…';
              await Clipboard.setData(
                ClipboardData(
                  text:
                      '${widget.book.title} — ${widget.book.author}\n$summary',
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Public book details copied.')),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image and Basic Info
            _buildHeroSection(),

            // Book Information
            _buildBookInfo(),

            // Action Buttons
            _buildActionButtons(),

            // Book Description
            _buildDescriptionSection(),

            // More from Author
            _buildMoreFromAuthor(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[100]!, Colors.white],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60), // Space for AppBar
          Hero(
            tag: 'book_${widget.book.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BookCover(book: widget.book, width: 200, height: 280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.book.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.book.author,
            style: TextStyle(
              fontSize: 18,
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Categories
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.book.categoryIds.map((categoryId) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  CatalogScope.of(context).categoryName(categoryId),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Read Book Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookReaderScreen(book: widget.book),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Read Preview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Book Description',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            showFullDescription
                ? widget.book.description
                : widget.book.description.length > 200
                ? '${widget.book.description.substring(0, 200)}...'
                : widget.book.description,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
          if (widget.book.description.length > 200) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  showFullDescription = !showFullDescription;
                });
              },
              child: Text(
                showFullDescription ? 'show less' : 'show more',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoreFromAuthor() {
    final related = CatalogScope.of(context).moreFromAuthor(widget.book);
    if (related.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'More from Author',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          for (final book in related)
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: Text(book.title),
              subtitle: Text(book.author),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
              ),
            ),
        ],
      ),
    );
  }
}
