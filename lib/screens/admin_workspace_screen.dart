import 'package:flutter/material.dart';

import '../controllers/admin_access_scope.dart';
import '../controllers/admin_catalog_scope.dart';
import '../models/admin_book.dart';
import '../models/category.dart';
import 'admin_book_form_screen.dart';
import 'admin_category_form_screen.dart';

class AdminWorkspaceScreen extends StatelessWidget {
  const AdminWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final access = AdminAccessScope.of(context);
    if (access.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!access.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin workspace')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(access.error ?? 'Admin access required.'),
              if (access.uid != null)
                TextButton(
                  onPressed: () => access.refresh(forceRefresh: true),
                  child: const Text('Retry access'),
                ),
            ],
          ),
        ),
      );
    }
    final catalog = AdminCatalogScope.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin workspace'),
          actions: [
            IconButton(
              tooltip: 'Refresh admin access',
              onPressed: () => access.refresh(forceRefresh: true),
              icon: const Icon(Icons.verified_user_outlined),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Books'),
              Tab(text: 'Categories'),
            ],
          ),
        ),
        body: catalog.isLoading
            ? const Center(child: CircularProgressIndicator())
            : catalog.error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(catalog.error!),
                    TextButton(
                      onPressed: catalog.load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : TabBarView(
                children: [_booksTab(context), _categoriesTab(context)],
              ),
      ),
    );
  }

  Widget _booksTab(BuildContext context) {
    final catalog = AdminCatalogScope.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: catalog.isSaving
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminBookFormScreen(),
                    ),
                  ),
            icon: const Icon(Icons.add),
            label: const Text('Add book'),
          ),
        ),
        Expanded(
          child: catalog.books.isEmpty
              ? const Center(child: Text('No catalog books'))
              : ListView.builder(
                  itemCount: catalog.books.length,
                  itemBuilder: (context, index) =>
                      _bookItem(context, catalog.books[index]),
                ),
        ),
      ],
    );
  }

  Widget _bookItem(BuildContext context, AdminBook book) {
    final catalog = AdminCatalogScope.of(context);
    return ListTile(
      title: Text(book.title),
      subtitle: Text('${book.id} · ${book.status}'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminBookFormScreen(original: book)),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Change book status',
        enabled: !catalog.isSaving,
        onSelected: (status) async {
          if (status == book.status) return;
          final confirmed = await _confirm(
            context,
            'Change ${book.title} to $status?',
          );
          if (!confirmed || !context.mounted) return;
          final result = await catalog.saveBook(
            book.withStatus(status),
            original: book,
          );
          if (!context.mounted) return;
          _message(context, result ?? 'Book status updated.');
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'draft', child: Text('Draft')),
          PopupMenuItem(value: 'published', child: Text('Published')),
          PopupMenuItem(value: 'archived', child: Text('Archived')),
        ],
      ),
    );
  }

  Widget _categoriesTab(BuildContext context) {
    final catalog = AdminCatalogScope.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: catalog.isSaving
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminCategoryFormScreen(),
                    ),
                  ),
            icon: const Icon(Icons.add),
            label: const Text('Add category'),
          ),
        ),
        Expanded(
          child: catalog.categories.isEmpty
              ? const Center(child: Text('No categories'))
              : ListView.builder(
                  itemCount: catalog.categories.length,
                  itemBuilder: (context, index) =>
                      _categoryItem(context, catalog.categories[index]),
                ),
        ),
      ],
    );
  }

  Widget _categoryItem(BuildContext context, Category category) {
    final catalog = AdminCatalogScope.of(context);
    return ListTile(
      title: Text(category.name),
      subtitle: Text(
        '${category.id} · ${category.isActive ? 'Active' : 'Inactive'}',
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminCategoryFormScreen(original: category),
        ),
      ),
      trailing: Switch(
        value: category.isActive,
        onChanged: catalog.isSaving
            ? null
            : (active) async {
                final confirmed = await _confirm(
                  context,
                  '${active ? 'Activate' : 'Deactivate'} ${category.name}?',
                );
                if (!confirmed || !context.mounted) return;
                final changed = Category(
                  id: category.id,
                  name: category.name,
                  description: category.description,
                  isActive: active,
                  createdAt: category.createdAt,
                  updatedAt: category.updatedAt,
                );
                final result = await catalog.saveCategory(
                  changed,
                  original: category,
                );
                if (!context.mounted) return;
                _message(context, result ?? 'Category status updated.');
              },
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String question) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm change'),
          content: Text(question),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;

  void _message(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
