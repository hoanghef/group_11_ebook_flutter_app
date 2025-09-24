// data/categories.dart
import '../models/category.dart';

class SampleCategories {
  static List<Category> getAllCategories() {
    return [
      Category(
        id: 'short_stories',
        name: 'Short Stories',
        description: 'Quick reads and compelling tales',
      ),
      Category(
        id: 'science_fiction',
        name: 'Science Fiction',
        description: 'Futuristic adventures and space exploration',
      ),
      Category(
        id: 'action_adventure',
        name: 'Action & Adventure',
        description: 'Thrilling stories and exciting journeys',
      ),
      Category(
        id: 'fiction',
        name: 'Fiction',
        description: 'Literary works and imaginative stories',
      ),
      Category(
        id: 'classic',
        name: 'Classic',
        description: 'Timeless literature and masterpieces',
      ),
      Category(
        id: 'fantasy',
        name: 'Fantasy',
        description: 'Magical worlds and mythical creatures',
      ),
      Category(
        id: 'mystery',
        name: 'Mystery',
        description: 'Suspenseful tales and detective stories',
      ),
      Category(
        id: 'romance',
        name: 'Romance',
        description: 'Love stories and romantic adventures',
      ),
    ];
  }

  // Helper method để lấy books theo category
  static List<String> getCategoryNames() {
    return getAllCategories().map((category) => category.name).toList();
  }
}