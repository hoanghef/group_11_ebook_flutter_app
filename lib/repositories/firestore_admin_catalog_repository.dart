import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_book.dart';
import '../models/category.dart';
import 'admin_catalog_repository.dart';

class FirestoreAdminCatalogRepository implements AdminCatalogRepository {
  FirestoreAdminCatalogRepository(this.firestore);
  final FirebaseFirestore firestore;

  static AdminBook bookFromData(String id, Map<String, dynamic> data) {
    if (data['id'] != id) throw const FormatException('Book ID mismatch');
    return AdminBook(
      id: id,
      title: data['title'] as String,
      author: data['author'] as String,
      description: data['description'] as String,
      coverRef: data['coverRef'] as String,
      categoryIds: List<String>.from(data['categoryIds'] as List),
      status: data['status'] as String,
      preview: data['preview'] as String,
      contentRef: data['contentRef'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Category categoryFromData(String id, Map<String, dynamic> data) {
    if (data['id'] != id) throw const FormatException('Category ID mismatch');
    return Category(
      id: id,
      name: data['name'] as String,
      description: data['description'] as String,
      isActive: data['active'] as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      throw AdminCatalogFailure(switch (error.code) {
        'permission-denied' => 'Admin permission was denied. Refresh access.',
        'unavailable' => 'Firestore is unavailable. Try again.',
        'already-exists' => 'This ID already exists.',
        _ => 'Catalog request failed. Try again.',
      });
    }
  }

  @override
  Future<List<AdminBook>> getAllBooks() => _guard(() async {
    final snapshot = await firestore.collection('books').get();
    return snapshot.docs
        .map((doc) => bookFromData(doc.id, doc.data()))
        .toList(growable: false);
  });

  @override
  Future<List<Category>> getAllCategories() => _guard(() async {
    final snapshot = await firestore.collection('categories').get();
    return snapshot.docs
        .map((doc) => categoryFromData(doc.id, doc.data()))
        .toList(growable: false);
  });

  @override
  Future<void> saveBook(AdminBook book, {required bool create}) =>
      _guard(() async {
        final document = firestore.collection('books').doc(book.id);
        final data = <String, dynamic>{
          'title': book.title,
          'author': book.author,
          'description': book.description,
          'coverRef': book.coverRef,
          'categoryIds': book.categoryIds,
          'status': book.status,
          'preview': book.preview,
          'contentRef': book.contentRef,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (create) {
          await document.set({
            ...data,
            'id': book.id,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await document.update(data);
        }
      });

  @override
  Future<void> saveCategory(Category category, {required bool create}) =>
      _guard(() async {
        final document = firestore.collection('categories').doc(category.id);
        final data = <String, dynamic>{
          'name': category.name,
          'description': category.description,
          'active': category.isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (create) {
          await document.set({
            ...data,
            'id': category.id,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await document.update(data);
        }
      });
}
