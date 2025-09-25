import 'package:flutter/material.dart';
import '../models/book.dart';
import '../data/sample_books.dart';
import '../services/storage_service.dart';
import 'book_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Book> favoriteBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      isLoading = true;
    });

    final favoriteIds = await StorageService.getFavorites();
    final allBooks = SampleBooks.getAllBooks();

    final favorites = allBooks.where((book) =>
        favoriteIds.contains(book.id)).toList();

    setState(() {
      favoriteBooks = favorites;
      isLoading = false;
    });
  }

  Future<void> _removeFavorite(String bookId) async {
    await StorageService.removeFavorite(bookId);
    await _loadFavorites(); // Reload danh sách

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (favoriteBooks.isNotEmpty)
            TextButton(
              onPressed: () {
                _showClearAllDialog();
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteBooks.isEmpty
          ? _buildEmptyState()
          : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 100,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Books you favorite will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${favoriteBooks.length} book${favoriteBooks.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: favoriteBooks.length,
            itemBuilder: (context, index) {
              return _buildFavoriteItem(favoriteBooks[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteItem(Book book) {
    return Dismissible(
      key: Key('favorite_${book.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeFavorite(book.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          ).then((_) {
            // Reload favorites khi quay lại từ detail screen
            _loadFavorites();
          });
        },
        leading: Hero(
          tag: 'book_${book.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              book.coverImage,
              width: 60,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
        title: Text(
          book.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.author,
              style: TextStyle(
                color: Colors.blue[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              book.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.favorite,
            color: Colors.red,
          ),
          onPressed: () {
            _removeFavorite(book.id);
          },
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Favorites'),
          content: const Text('Are you sure you want to remove all books from favorites?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await StorageService.clearAllFavorites();
                Navigator.of(context).pop();
                await _loadFavorites();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All favorites cleared'),
                    ),
                  );
                }
              },
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}