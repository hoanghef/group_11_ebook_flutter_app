class Book {
  final String id;
  final String title;
  final String author;
  final String coverImage;
  final String description;
  final List<String> categories;
  final String content;
  bool isFavorite;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverImage,
    required this.description,
    required this.categories,
    required this.content,
    this.isFavorite = false,
  });
}