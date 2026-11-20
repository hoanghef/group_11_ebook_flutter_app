import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_scope.dart';
import '../controllers/catalog_scope.dart';
import '../controllers/user_library_scope.dart';
import '../models/book.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = UserLibraryScope.of(context);
    if (AuthScope.of(context).status != AuthStatus.signedIn) {
      return const Scaffold(
        body: Center(child: Text('Sign in to use favorites')),
      );
    }
    final books = CatalogScope.of(
      context,
    ).books.where((book) => library.isFavorite(book.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          if (books.isNotEmpty &&
              !library.isLoadingFavorites &&
              !library.isWritingFavorites)
            TextButton(
              onPressed: () => _showClearAllDialog(context),
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: library.isLoadingFavorites
          ? const Center(child: CircularProgressIndicator())
          : library.favoritesError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(library.favoritesError!),
                  TextButton(
                    onPressed: library.loadFavorites,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : books.isEmpty
          ? const Center(child: Text('No favorites yet'))
          : ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) =>
                  _buildFavoriteItem(context, books[index]),
            ),
    );
  }

  Widget _buildFavoriteItem(BuildContext context, Book book) {
    final library = UserLibraryScope.of(context);
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
      ),
      leading: BookCover(book: book, width: 60, height: 80),
      title: Text(book.title),
      subtitle: Text(book.author),
      trailing: IconButton(
        icon: const Icon(Icons.favorite, color: Colors.red),
        onPressed: library.isWritingFavorite(book.id)
            ? null
            : () async {
                final uid = library.uid;
                final saved = await library.setFavorite(book.id, false);
                if (!context.mounted || library.uid != uid) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      saved
                          ? 'Removed from favorites'
                          : 'Favorite could not be removed. Retry.',
                    ),
                  ),
                );
              },
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text(
          'Are you sure you want to remove all books from favorites?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final library = UserLibraryScope.of(dialogContext);
              final uid = library.uid;
              final cleared = await library.clearFavorites();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!context.mounted || library.uid != uid) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    cleared
                        ? 'All favorites cleared'
                        : 'Favorites could not be cleared. Retry.',
                  ),
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
