import 'package:flutter/material.dart';

import '../controllers/admin_access_scope.dart';
import '../controllers/admin_catalog_scope.dart';
import '../controllers/admin_catalog_validator.dart';
import '../models/category.dart';

class AdminCategoryFormScreen extends StatefulWidget {
  const AdminCategoryFormScreen({super.key, this.original});
  final Category? original;

  @override
  State<AdminCategoryFormScreen> createState() =>
      _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  late final TextEditingController _id;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late bool _active;
  String? _error;

  @override
  void initState() {
    super.initState();
    _id = TextEditingController(text: widget.original?.id ?? '');
    _name = TextEditingController(text: widget.original?.name ?? '');
    _description = TextEditingController(
      text: widget.original?.description ?? '',
    );
    _active = widget.original?.isActive ?? true;
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdminAccessScope.of(context).isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Admin access required.')),
      );
    }
    final catalog = AdminCatalogScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.original == null ? 'Add category' : 'Edit category'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            key: const Key('admin_category_id'),
            controller: _id,
            readOnly: widget.original != null,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Category ID'),
          ),
          if (widget.original?.createdAt != null)
            Text('Created: ${widget.original!.createdAt} (read only)'),
          TextFormField(
            key: const Key('admin_category_name'),
            controller: _name,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          TextFormField(
            controller: _description,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          SwitchListTile(
            title: const Text('Active'),
            subtitle: const Text(
              'Inactive categories cannot be chosen for new books.',
            ),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: catalog.isSaving ? null : _save,
            child: const Text('Save category'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final catalog = AdminCatalogScope.of(context);
    final original = widget.original;
    final category = Category(
      id: _id.text.trim(),
      name: _name.text.trim(),
      description: _description.text,
      isActive: _active,
      createdAt: original?.createdAt,
      updatedAt: original?.updatedAt,
    );
    final validation = AdminCatalogValidator.categoryError(
      category,
      original: original,
    );
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    if (original != null && original.isActive != category.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm status change'),
          content: Text(
            '${category.isActive ? 'Activate' : 'Deactivate'} ${category.name}?',
          ),
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
    final result = await catalog.saveCategory(category, original: original);
    if (!mounted || AdminAccessScope.of(context).uid != uid) return;
    if (result != null) {
      setState(() => _error = result);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Category saved.')));
  }
}
