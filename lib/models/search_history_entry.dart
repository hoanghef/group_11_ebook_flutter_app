class SearchHistoryEntry {
  const SearchHistoryEntry({
    required this.id,
    required this.query,
    required this.submittedAt,
  });

  final String id;
  final String query;
  final DateTime submittedAt;
}
