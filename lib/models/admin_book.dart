class AdminBook {
  AdminBook({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverRef,
    required List<String> categoryIds,
    required this.status,
    required this.preview,
    required this.contentRef,
    this.createdAt,
    this.updatedAt,
  }) : categoryIds = List.unmodifiable(categoryIds);

  final String id;
  final String title;
  final String author;
  final String description;
  final String coverRef;
  final List<String> categoryIds;
  final String status;
  final String preview;
  final String contentRef;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminBook withStatus(String value) => AdminBook(
    id: id,
    title: title,
    author: author,
    description: description,
    coverRef: coverRef,
    categoryIds: categoryIds,
    status: value,
    preview: preview,
    contentRef: contentRef,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
