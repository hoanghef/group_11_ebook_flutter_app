// data/categories.dart
import '../models/category.dart';

class SampleCategories {
  static List<Category> getAllCategories() {
    return [
      Category(
        id: 'short_stories',
        name: 'Short Stories',
        description: 'Brief stories for a short reading break.',
      ),
      Category(
        id: 'science_fiction',
        name: 'Science Fiction',
        description: 'Imagined tools, futures, and discoveries.',
      ),
      Category(
        id: 'action_adventure',
        name: 'Action & Adventure',
        description: 'Journeys driven by movement and risk.',
      ),
      Category(
        id: 'fiction',
        name: 'Fiction',
        description: 'Invented people, places, and choices.',
      ),
      Category(
        id: 'classic',
        name: 'Classic',
        description: 'Stories with themes that invite revisiting.',
      ),
      Category(
        id: 'fantasy',
        name: 'Fantasy',
        description: 'Worlds with rules beyond the everyday.',
      ),
      Category(
        id: 'mystery',
        name: 'Mystery',
        description: 'Clues and unanswered questions.',
      ),
      Category(
        id: 'romance',
        name: 'Romance',
        description: 'Stories about growing affection.',
      ),
      Category(
        id: 'drama',
        name: 'Drama',
        description: 'Choices with emotional stakes.',
      ),
      Category(
        id: 'children',
        name: 'Children',
        description: 'Gentle adventures for younger readers.',
      ),
      Category(
        id: 'thriller',
        name: 'Thriller',
        description: 'Tense moments and uncertain outcomes.',
      ),
      Category(
        id: 'historical_fiction',
        name: 'Historical Fiction',
        description: 'Invented stories in imagined past settings.',
      ),
      Category(
        id: 'psychology',
        name: 'Psychology',
        description: 'Stories shaped by thought and memory.',
      ),
    ];
  }

  // Helper method để lấy books theo category
  static List<String> getCategoryNames() {
    return getAllCategories().map((category) => category.name).toList();
  }
}
