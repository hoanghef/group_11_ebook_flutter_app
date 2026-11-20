import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book.dart';
import '../models/category.dart';
import 'catalog_repository.dart';

class FirestoreCatalogRepository implements CatalogRepository {
  FirestoreCatalogRepository(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Future<List<Book>> getBooks() async {
    final snapshot = await firestore
        .collection('books')
        .where('status', isEqualTo: 'published')
        .get();
    return snapshot.docs
        .map((doc) => bookFromData(doc.id, doc.data()))
        .toList(growable: false);
  }

  @override
  Future<List<Category>> getCategories() async {
    final snapshot = await firestore
        .collection('categories')
        .where('active', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => categoryFromData(doc.id, doc.data()))
        .toList(growable: false);
  }

  static Book bookFromData(String documentId, Map<String, dynamic> data) {
    if (data['id'] != documentId) {
      throw FormatException(
        'Book ID does not match its document ID: $documentId',
      );
    }
    return Book(
      id: documentId,
      title: data['title'] as String,
      author: data['author'] as String,
      description: data['description'] as String,
      coverImage: data['coverRef'] as String,
      categoryIds: List<String>.from(data['categoryIds'] as List),
      content: data['preview'] as String? ?? '',
      contentRef: data['contentRef'] as String?,
      isPublished: data['status'] == 'published',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Category categoryFromData(
    String documentId,
    Map<String, dynamic> data,
  ) {
    if (data['id'] != documentId) {
      throw FormatException(
        'Category ID does not match its document ID: $documentId',
      );
    }
    return Category(
      id: documentId,
      name: data['name'] as String,
      description: data['description'] as String,
      isActive: data['active'] as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
