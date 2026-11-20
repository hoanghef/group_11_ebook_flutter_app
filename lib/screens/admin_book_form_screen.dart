import 'package:flutter/material.dart';

import '../controllers/admin_access_scope.dart';
import '../controllers/admin_catalog_scope.dart';
import '../controllers/admin_catalog_validator.dart';
import '../models/admin_book.dart';
import '../widgets/book_cover.dart';

class AdminBookFormScreen extends StatefulWidget {
  const AdminBookFormScreen({super.key, this.original});
  final AdminBook? original;

  @override
  State<AdminBookFormScreen> createState() => _AdminBookFormScreenState();
}

class _AdminBookFormScreenState extends State<AdminBookFormScreen> {
  late final TextEditingController _id;
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _description;
  late final TextEditingController _preview;
  late final TextEditingController _contentRef;
  late String _coverRef;
  late String _status;
  late List<String> _categoryIds;
  String? _error;

  @override
  void initState() {
    super.initState();
    final book = widget.original;
    _id = TextEditingController(text: book?.id ?? '');
    _title = TextEditingController(text: book?.title ?? '');
    _author = TextEditingController(text: book?.author ?? '');
    _description = TextEditingController(text: book?.description ?? '');
    _preview = TextEditingController(text: book?.preview ?? '');
    _contentRef = TextEditingController(text: book?.contentRef ?? '');
    _coverRef = book?.coverRef ?? AdminCatalogValidator.coverStyles.first;
    _status = book?.status ?? 'draft';
    _categoryIds = [...?book?.categoryIds];
  }

  @override
  void dispose() {
    for (final controller in [
      _id,
      _title,
      _author,
      _description,
      _preview,
      _contentRef,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = AdminAccessScope.of(context);
    if (!access.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Admin access required.')),
      );
    }
    final catalog = AdminCatalogScope.of(context);
    final covers = [
      ...AdminCatalogValidator.coverStyles,
      if (!AdminCatalogValidator.coverStyles.contains(_coverRef)) _coverRef,
    ];
    final active = catalog.categories
        .where((category) => category.isActive)
        .toList();
    final inactiveSelected = _categoryIds.where(
      (id) => !active.any((category) => category.id == id),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.original == null ? 'Add book' : 'Edit book'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(
            'Book ID',
            _id,
            key: const Key('admin_book_id'),
            readOnly: widget.original != null,
            maxLength: 80,
          ),
          if (widget.original?.createdAt != null)
            Text('Created: ${widget.original!.createdAt} (read only)'),
          _field(
            'Title',
            _title,
            key: const Key('admin_book_title'),
            maxLength: 200,
          ),
          _field(
            'Author',
            _author,
            key: const Key('admin_book_author'),
            maxLength: 200,
          ),
          _field('Description', _description, maxLength: 2000, maxLines: 3),
          DropdownButtonFormField<String>(
            initialValue: _coverRef,
            decoration: const InputDecoration(labelText: 'Cover style'),
            items: covers
                .map(
                  (ref) => DropdownMenuItem(
                    value: ref,
                    child: Text(
                      AdminCatalogValidator.coverStyles.contains(ref)
                          ? ref.substring('generated:'.length)
                          : 'Legacy cover (choose a new style)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _coverRef = value!),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: BookCover.reference(
              coverRef: _coverRef,
              title: _title.text.trim().isEmpty ? 'Book preview' : _title.text,
              author: _author.text.trim().isEmpty ? 'Author' : _author.text,
              width: 100,
              height: 140,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Categories (choose 1–5 active categories)'),
          Wrap(
            spacing: 8,
            children: [
              for (final category in active)
                FilterChip(
                  label: Text(category.name),
                  selected: _categoryIds.contains(category.id),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _categoryIds.add(category.id);
                    } else {
                      _categoryIds.remove(category.id);
                    }
                  }),
                ),
            ],
          ),
          for (final id in inactiveSelected)
            InputChip(
              label: Text('Inactive or missing category: $id (retained)'),
              onDeleted: () => setState(() => _categoryIds.remove(id)),
            ),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: AdminCatalogValidator.statuses
                .map(
                  (status) =>
                      DropdownMenuItem(value: status, child: Text(status)),
                )
                .toList(),
            onChanged: (value) => setState(() => _status = value!),
          ),
          _field(
            'Preview (sample content)',
            _preview,
            key: const Key('admin_book_preview'),
            maxLength: 2000,
            maxLines: 4,
          ),
          _field(
            'Content reference (not ebook content)',
            _contentRef,
            maxLength: 500,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: catalog.isSaving ? null : _save,
            child: const Text('Save book'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    Key? key,
    bool readOnly = false,
    int? maxLength,
    int maxLines = 1,
  }) => TextFormField(
    key: key,
    controller: controller,
    readOnly: readOnly,
    maxLength: maxLength,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label),
  );

  Future<void> _save() async {
    final catalog = AdminCatalogScope.of(context);
    final original = widget.original;
    final book = AdminBook(
      id: _id.text.trim(),
      title: _title.text.trim(),
      author: _author.text.trim(),
      description: _description.text,
      coverRef: _coverRef,
      categoryIds: _categoryIds,
      status: _status,
      preview: _preview.text,
      contentRef: _contentRef.text.trim(),
      createdAt: original?.createdAt,
      updatedAt: original?.updatedAt,
    );
    final validation = AdminCatalogValidator.bookError(
      book,
      catalog.categories,
      original: original,
    );
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    if (original != null && original.status != book.status) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm status change'),
          content: Text('Change ${book.title} to ${book.status}?'),
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
      );
      if (confirmed != true || !mounted) return;
    }
    final uid = AdminAccessScope.of(context).uid;
    final result = await catalog.saveBook(book, original: original);
    if (!mounted || AdminAccessScope.of(context).uid != uid) return;
    if (result != null) {
      setState(() => _error = result);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Book saved.')));
  }
}
