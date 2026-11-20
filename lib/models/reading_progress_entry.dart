class ReadingProgressEntry {
  const ReadingProgressEntry({
    required this.bookId,
    required this.ratio,
    required this.updatedAt,
  });

  final String bookId;
  final double ratio;
  final DateTime updatedAt;
}
