// Trong main.dart hoặc file test
import 'package:flutter/foundation.dart';
import 'repositories/sample_catalog_repository.dart';

Future<void> main() async {
  final catalog = SampleCatalogRepository();
  debugPrint('Total books: ${(await catalog.getBooks()).length}');
  debugPrint('Total categories: ${(await catalog.getCategories()).length}');
}
