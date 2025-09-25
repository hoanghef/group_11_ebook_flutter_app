class StorageService {
  static List<String> _favorites = []; // In-memory storage

  // Lưu danh sách favorites
  static Future<void> saveFavorites(List<String> bookIds) async {
    _favorites = List.from(bookIds);
  }

  // Lấy danh sách favorites
  static Future<List<String>> getFavorites() async {
    return List.from(_favorites);
  }

  // Thêm sách vào favorites
  static Future<void> addFavorite(String bookId) async {
    if (!_favorites.contains(bookId)) {
      _favorites.add(bookId);
    }
  }

  // Xóa sách khỏi favorites
  static Future<void> removeFavorite(String bookId) async {
    _favorites.remove(bookId);
  }

  // Kiểm tra sách có trong favorites không
  static Future<bool> isFavorite(String bookId) async {
    return _favorites.contains(bookId);
  }

  // Toggle favorite status
  static Future<bool> toggleFavorite(String bookId) async {
    if (_favorites.contains(bookId)) {
      _favorites.remove(bookId);
      return false;
    } else {
      _favorites.add(bookId);
      return true;
    }
  }

  // Lấy số lượng favorites
  static Future<int> getFavoritesCount() async {
    return _favorites.length;
  }

  // Clear all favorites (for testing)
  static Future<void> clearAllFavorites() async {
    _favorites.clear();
  }
}