import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/auth_scope.dart';
import '../controllers/catalog_scope.dart';
import '../controllers/user_library_scope.dart';
import '../models/book.dart';
import '../models/book_note.dart';
import '../models/bookmark.dart';
import 'book_reader_screen.dart';

class PersonalLibraryScreen extends StatelessWidget {
  const PersonalLibraryScreen({super.key});

  Book? _book(BuildContext context, String id) {
    for (final book in CatalogScope.of(context).books) {
      if (book.id == id) return book;
    }
    return null;
  }

  void _message(BuildContext context, String text) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AuthScope.of(context).status != AuthStatus.signedIn) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view bookmarks and notes.')),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookmarks & Notes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bookmarks'),
              Tab(text: 'Notes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_bookmarksTab(context), _notesTab(context)],
        ),
      ),
    );
  }

  Widget _bookmarksTab(BuildContext context) {
    final library = UserLibraryScope.of(context);
    if (library.isLoadingBookmarks) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        if (library.bookmarksError != null)
          _errorRow(library.bookmarksError!, library.loadBookmarks),
        Expanded(
          child: library.bookmarks.isEmpty
              ? const Center(child: Text('No bookmarks yet'))
              : ListView.builder(
                  itemCount: library.bookmarks.length,
                  itemBuilder: (context, index) =>
                      _bookmarkItem(context, library.bookmarks[index]),
                ),
        ),
      ],
    );
  }

  Widget _bookmarkItem(BuildContext context, Bookmark item) {
    final library = UserLibraryScope.of(context);
    final book = _book(context, item.bookId);
    return ListTile(
      title: Text(
        item.label.isEmpty
            ? 'Bookmark at ${(item.ratio * 100).round()}%'
            : item.label,
      ),
      subtitle: Text(book?.title ?? 'Book unavailable (ID: ${item.bookId})'),
      onTap: book == null
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BookReaderScreen(book: book, initialRatio: item.ratio),
              ),
            ),
      trailing: IconButton(
        tooltip: 'Delete bookmark',
        icon: const Icon(Icons.delete_outline),
        onPressed: library.isWritingBookmark
            ? null
            : () async {
                final uid = library.uid;
                final saved = await library.deleteBookmark(item.id);
                if (!context.mounted || library.uid != uid) return;
                _message(
                  context,
                  saved
                      ? 'Bookmark deleted.'
                      : 'Bookmark could not be deleted. Retry.',
                );
              },
      ),
    );
  }

  Widget _notesTab(BuildContext context) {
    final library = UserLibraryScope.of(context);
    if (library.isLoadingNotes) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        if (library.notesError != null)
          _errorRow(library.notesError!, library.loadNotes),
        Expanded(
          child: library.notes.isEmpty
              ? const Center(
                  child: Text('No notes yet. Open a book to add one.'),
                )
              : ListView.builder(
                  itemCount: library.notes.length,
                  itemBuilder: (context, index) =>
                      _noteItem(context, library.notes[index]),
                ),
        ),
      ],
    );
  }

  Widget _noteItem(BuildContext context, BookNote item) {
    final library = UserLibraryScope.of(context);
    final book = _book(context, item.bookId);
    return ListTile(
      title: Text(item.text, maxLines: 3, overflow: TextOverflow.ellipsis),
      subtitle: Text(book?.title ?? 'Book unavailable (ID: ${item.bookId})'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Edit note',
            icon: const Icon(Icons.edit_outlined),
            onPressed: library.isWritingNote
                ? null
                : () => _editNote(context, item),
          ),
          IconButton(
            tooltip: 'Delete note',
            icon: const Icon(Icons.delete_outline),
            onPressed: library.isWritingNote
                ? null
                : () async {
                    final uid = library.uid;
                    final saved = await library.deleteNote(item.id);
                    if (!context.mounted || library.uid != uid) return;
                    _message(
                      context,
                      saved
                          ? 'Note deleted.'
                          : 'Note could not be deleted. Retry.',
                    );
                  },
          ),
        ],
      ),
    );
  }

  void _editNote(BuildContext context, BookNote note) {
    final library = UserLibraryScope.of(context);
    final uid = library.uid;
    var value = note.text;
    var busy = false;
    String? error;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => AlertDialog(
          title: const Text('Edit note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: note.text,
                maxLength: 2000,
                maxLines: 4,
                onChanged: (text) => value = text,
              ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (value.trim().isEmpty) {
                        updateDialog(() => error = 'Enter a note.');
                        return;
                      }
                      updateDialog(() {
                        busy = true;
                        error = null;
                      });
                      final saved = await library.updateNote(note.id, value);
                      if (!dialogContext.mounted || library.uid != uid) return;
                      if (saved) {
                        Navigator.pop(dialogContext);
                        _message(context, 'Note updated.');
                      } else {
                        updateDialog(() {
                          busy = false;
                          error = 'Note could not be updated. Retry.';
                        });
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorRow(String message, Future<void> Function() retry) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Expanded(child: Text(message)),
        TextButton(onPressed: retry, child: const Text('Retry')),
      ],
    ),
  );
}
