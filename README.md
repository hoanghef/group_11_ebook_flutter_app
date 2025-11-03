# 📚 Flutter Ebook App

A beautiful and functional ebook reader application built with Flutter. Browse, search, read, and manage your favorite books all in one place.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Material Design](https://img.shields.io/badge/Material%20Design-757575?style=for-the-badge&logo=material-design&logoColor=white)

## ✨ Features

### 🔐 Authentication
- User registration with validation
- Secure login system
- Session management
- User profile display

### 📖 Browse & Explore
- Featured books carousel
- Browse books by categories
- Horizontal scrolling book lists
- Category-based filtering
- Recently added books section

### 🔍 Search
- Real-time search functionality
- Search by book title or author
- Instant results display
- Search history

### 📕 Reading Experience
- Immersive book reader
- Reading progress tracking
- Customizable font size (12-24px)
- Dark/Light mode toggle
- Settings panel overlay

### ❤️ Favorites Management
- Add/remove books to favorites
- Favorites list view
- Swipe to delete
- Clear all favorites option
- Real-time sync across screens

### 🎨 UI/UX
- Material Design 3
- Smooth hero animations
- Bottom navigation
- Responsive layouts
- Empty states and loading indicators
- Clean and modern interface

## 📱 Screenshots


| Home | Explore | Book Detail | Reader |
|------|---------|-------------|--------|
| <img width="727" height="1600" alt="image" src="https://github.com/user-attachments/assets/b1b2ddaa-2161-40bc-8306-e905572ce005" />| <img width="728" height="1603" alt="image" src="https://github.com/user-attachments/assets/a2f8f280-e7cc-4ecd-8fce-550dbb0c48a5" />| <img width="728" height="1601" alt="image" src="https://github.com/user-attachments/assets/42080d2d-67dc-40d6-9357-f9d2c8882614" />| <img width="727" height="1603" alt="image" src="https://github.com/user-attachments/assets/54d4d708-5227-4376-8461-db247dbb8d4b" />|

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: StatefulWidget
- **Storage**: In-memory (can be upgraded to SharedPreferences/Firebase)
- **UI Design**: Material Design 3
- **Icons**: Material Icons

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── book.dart
│   ├── category.dart
│   └── user.dart
├── screens/                     # UI screens
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── home_tab_screen.dart
│   ├── explore_screen.dart
│   ├── favorites_screen.dart
│   ├── settings_screen.dart
│   ├── book_detail_screen.dart
│   ├── category_books_screen.dart
│   ├── book_reader_screen.dart
│   └── search_screen.dart
├── services/                    # Business logic
│   ├── auth_service.dart
│   └── storage_service.dart
└── data/                        # Sample data
    ├── sample_books.dart
    └── categories.dart
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code
- Android/iOS Emulator or Physical Device

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/flutter-ebook-app.git
cd flutter-ebook-app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Add your book cover images**
- Place book cover images in `assets/images/book_covers/`
- Update paths in `data/sample_books.dart`

4. **Run the app**
```bash
flutter run
```

## 📖 Usage

1. **Launch the app** - Start with the login screen
2. **Register/Login** - Create an account or skip for now
3. **Browse books** - Explore featured books and categories
4. **Search** - Find books by title or author
5. **Read** - Tap "Read Book" to start reading with customizable settings
6. **Favorites** - Add books to your favorites list
7. **Customize** - Adjust font size and theme in the reader

## 🎯 Key Screens

### Login & Register
- Email/password authentication
- Form validation
- Loading states
- Error handling

### Home
- Featured books slider
- Category chips
- Recently added books
- Search button

### Explore
- Books organized by categories
- Horizontal scrolling lists
- "See All" navigation

### Book Detail
- Cover image with hero animation
- Book information
- Category tags
- Favorite toggle
- Read button

### Book Reader
- Full-screen immersive mode
- Progress bar
- Font size controls
- Dark/Light mode
- Settings overlay

## 🔧 Configuration

### Adding Books

Edit `lib/data/sample_books.dart`:

```dart
Book(
  id: 'unique_id',
  title: 'Book Title',
  author: 'Author Name',
  coverImage: 'assets/images/book_covers/your_image.jpg',
  description: 'Book description...',
  categories: ['Fiction', 'Drama'],
  content: '''Your book content here...''',
  isFavorite: false,
)
```

### Adding Categories

Edit `lib/data/categories.dart`:

```dart
Category(
  id: 'category_id',
  name: 'Category Name',
  description: 'Category description',
)
```

## 🔮 Future Enhancements

### Phase 1: Persistence
- [ ] SharedPreferences integration
- [ ] Persistent authentication
- [ ] Save reading progress
- [ ] Cache downloaded books

### Phase 2: Backend
- [ ] Firebase Authentication
- [ ] Cloud Firestore database
- [ ] Real-time synchronization
- [ ] User cloud storage

### Phase 3: Advanced Features
- [ ] Reading statistics
- [ ] Book recommendations
- [ ] Social features (reviews, ratings)
- [ ] Offline reading mode
- [ ] Note-taking functionality
- [ ] Bookmark system
- [ ] Text-to-speech
- [ ] Multiple language support

### Phase 4: Polish
- [ ] Push notifications
- [ ] App analytics
- [ ] Crash reporting
- [ ] Performance optimization
- [ ] Accessibility improvements

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **hoanghef** - [GitHub Profile](https://github.com/hoanghef)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design for UI guidelines
- Open source community for inspiration

## 📧 Contact

- Email: hoanghant220305@gmail.com
- GitHub: [hoanghef](https://github.com/hoanghef)

---

⭐ If you found this project helpful, please give it a star!

Made with ❤️ and Flutter
