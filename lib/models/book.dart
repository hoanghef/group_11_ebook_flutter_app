class Book {
  final String id;
  final String title;
  final String author;
  final String coverImage;
  final String description;
  final List<String> categoryIds;
  final String content;
  final String? contentRef;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverImage,
    required this.description,
    required List<String> categoryIds,
    required this.content,
    this.contentRef,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  }) : categoryIds = List.unmodifiable(categoryIds);
}
