class BookNote {
  const BookNote({
    required this.id,
    required this.bookId,
    required this.text,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookId;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BookNote withText(String value) => BookNote(
    id: id,
    bookId: bookId,
    text: value,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
