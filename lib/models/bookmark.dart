class Bookmark {
  const Bookmark({
    required this.id,
    required this.bookId,
    required this.ratio,
    required this.label,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookId;
  final double ratio;
  final String label;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
