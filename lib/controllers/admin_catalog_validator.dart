import '../models/admin_book.dart';
import '../models/category.dart';
import '../widgets/book_cover.dart';

class AdminCatalogValidator {
  static const coverStyles = BookCover.styles;

  static final _id = RegExp(r'^[a-z0-9_-]{1,80}$');
  static const statuses = ['draft', 'published', 'archived'];

  static String? bookError(
    AdminBook book,
    List<Category> categories, {
    AdminBook? original,
  }) {
    if (!_id.hasMatch(book.id)) {
      return 'Use 1–80 lowercase letters, digits, _ or - for ID.';
    }
    if (original != null && book.id != original.id) {
      return 'Book ID cannot change.';
    }
    if (book.title.trim().isEmpty || book.title.length > 200) {
      return 'Title must have 1–200 characters.';
    }
    if (book.author.trim().isEmpty || book.author.length > 200) {
      return 'Author must have 1–200 characters.';
    }
    if (book.description.length > 2000) {
      return 'Description is too long (max 2,000).';
    }
    if (book.preview.length > 2000) return 'Preview is too long (max 2,000).';
    if (book.contentRef.length > 500) return 'Content reference is too long.';
    if (!statuses.contains(book.status)) return 'Choose a valid status.';
    if (book.coverRef.length > 500 ||
        (!coverStyles.contains(book.coverRef) &&
            (original == null || book.coverRef != original.coverRef))) {
      return 'Choose a generated cover style.';
    }
    final ids = book.categoryIds;
    if (ids.isEmpty || ids.length > 5 || ids.toSet().length != ids.length) {
      return 'Select 1–5 distinct categories.';
    }
    final active = categories
        .where((category) => category.isActive)
        .map((category) => category.id)
        .toSet();
    for (final id in ids) {
      if (!_id.hasMatch(id)) return 'Category ID is invalid.';
      if (!active.contains(id) &&
          (original == null || !original.categoryIds.contains(id))) {
        return 'New categories must be active.';
      }
    }
    return null;
  }

  static String? categoryError(Category category, {Category? original}) {
    if (!_id.hasMatch(category.id)) {
      return 'Use 1–80 lowercase letters, digits, _ or - for ID.';
    }
    if (original != null && category.id != original.id) {
      return 'Category ID cannot change.';
    }
    if (category.name.trim().isEmpty || category.name.length > 100) {
      return 'Name must have 1–100 characters.';
    }
    if (category.description.length > 500) {
      return 'Description is too long (max 500).';
    }
    return null;
  }
}
