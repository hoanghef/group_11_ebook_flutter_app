import 'package:flutter/material.dart';
import '../models/book.dart';
import '../widgets/book_cover.dart';
import '../controllers/catalog_scope.dart';
import '../controllers/user_library_scope.dart';
import 'book_detail_screen.dart';
import 'catalog_state_view.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {});
  }

  Future<void> _submitSearch(String query) async {
    final value = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return;
    if (value.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search query must be 100 characters or fewer.'),
        ),
      );
      return;
    }
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
    final library = UserLibraryScope.of(context);
    if (library.uid == null) return;
    final uid = library.uid;
    final saved = await library.submitSearchQuery(value);
    if (!mounted || library.uid != uid) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search history could not save. Retry.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search books or authors...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
          onChanged: _performSearch,
          onSubmitted: _submitSearch,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            tooltip: 'Submit search',
            icon: const Icon(Icons.search),
            onPressed: () => _submitSearch(_searchController.text),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: CatalogStateView(
        isEmpty: CatalogScope.of(context).books.isEmpty,
        emptyMessage: 'No books available to search',
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_searchController.text.trim().isEmpty) {
      return _buildRecentSearches();
    }

    final results = CatalogScope.of(context).search(_searchController.text);
    if (results.isEmpty) {
      return _buildNoResults();
    }

    return _buildSearchResults(results);
  }

  Widget _buildRecentSearches() {
    final library = UserLibraryScope.of(context);
    if (library.uid != null) {
      if (library.isLoadingSearchHistory) {
        return const Center(child: CircularProgressIndicator());
      }
      if (library.searchHistoryError != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(library.searchHistoryError!),
              TextButton(
                onPressed: library.loadSearchHistory,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      if (library.searchHistory.isNotEmpty) {
        return ListView(
          children: [
            ListTile(
              title: const Text('Recent searches'),
              trailing: TextButton(
                onPressed: library.isWritingSearchHistory
                    ? null
                    : () => library.clearSearchHistory(),
                child: const Text('Clear history'),
              ),
            ),
            for (final entry in library.searchHistory)
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(entry.query),
                onTap: () => _submitSearch(entry.query),
                trailing: IconButton(
                  tooltip: 'Remove ${entry.query}',
                  icon: const Icon(Icons.close),
                  onPressed: library.isWritingSearchHistory
                      ? null
                      : () => library.deleteSearchQuery(entry.id),
                ),
              ),
          ],
        );
      }
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Search for books',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Find your favorite books by title or author',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Book> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${results.length} result${results.length == 1 ? '' : 's'} found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              return _buildSearchResultItem(results[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(Book book) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      },
      leading: Hero(
        tag: 'book_${book.id}_search',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BookCover(book: book, width: 50, height: 70),
        ),
      ),
      title: Text(
        book.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(book.author, style: TextStyle(color: Colors.blue[600])),
          const SizedBox(height: 4),
          Text(
            book.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
