import 'package:flutter/material.dart';

import '../controllers/catalog_scope.dart';

class CatalogStateView extends StatelessWidget {
  const CatalogStateView({
    super.key,
    required this.isEmpty,
    required this.emptyMessage,
    required this.child,
  });

  final bool isEmpty;
  final String emptyMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.of(context);
    if (catalog.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (catalog.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Catalog could not load.'),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: catalog.load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (isEmpty) return Center(child: Text(emptyMessage));
    return child;
  }
}
