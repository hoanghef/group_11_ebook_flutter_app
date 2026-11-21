# Flutter Ebook App

A clean Flutter ebook reader application featuring Firebase Authentication, Cloud Firestore, procedural geometric cover rendering, ratio-based reading progress, and a role-based Admin workspace.

Built with a modular repository architecture designed for testability and clear separation of concerns.

---

## 📱 Screenshots

> [!NOTE]
> Screenshots will be added by the repository owner from physical devices or running emulators. Place actual screenshots in `docs/screenshots/` and update the links below.

| Home & Discover | Book Details | Reader View | Personal Library | Admin Workspace |
|:---:|:---:|:---:|:---:|:---:|
| *(Add `home.png`)* | *(Add `details.png`)* | *(Add `reader.png`)* | *(Add `library.png`)* | *(Add `admin.png`)* |

---

## ✨ Features

### 📖 Catalog & Discovery
- **Fictional Demo Catalog**: 11 original fictional books across 13 curated categories.
- **Procedural Geometric Covers**: Dynamic covers generated directly using Flutter Canvas and color palettes—no bundled copyrighted JPG assets or external image dependencies.
- **Search & Filter**: Real-time title and author search with case-insensitive matching; category browsing and recent query history (persisted for signed-in users).
- **Public Query Isolation**: Public clients only query published books (`status == 'published'`) and active categories (`active == true`).

### 📕 Reading Experience
- **Ratio-Based Scroll Tracking**: Progress is saved as a fractional ratio (`offset / maxScrollExtent`), ensuring consistent position restoration across different screen sizes, orientations, and font sizes.
- **Short Preview Protection**: Non-scrollable short previews (`maxScrollExtent == 0`) preserve the existing saved progress and never overwrite it to 0%.
- **Debounced Cloud Writes**: Automatic saving debounced at 600 ms during reading and synced upon leaving the screen.
- **Customizable Environment**: Adjustable font sizing (12–24 px) and Light/Dark reader themes active for the current reading session (font size and theme are held in-memory per session).
- **Bookmarks & Notes**: Create ratio-linked bookmarks and custom notes with full edit/delete capabilities.

### 🔐 Authentication & Personal Library
- **Firebase Auth**: Email and password registration, login, session persistence, and secure logout.
- **UID Data Isolation**: Favorites, reading progress, bookmarks, notes, and search history are strictly stored under `users/{uid}/*` subcollections in Firestore.
- **Guest Access**: Seamless browsing and preview reading for guests; personal library actions gracefully prompt for sign-in without writing dummy data to the backend.

### 🛠️ Role-Based Admin Workspace
- **Custom Claim Verification**: Admin access requires Firebase Auth ID token custom claim `admin: true`.
- **Catalog Management**: View published, draft, and archived books; create, edit, archive books and activate/deactivate categories.
- **Strict Firestore Rules**: All writes enforce server-side validation rules. Document deletion is disallowed in favor of archiving. Client-side `role` fields cannot bypass security rules.

---

## 🏗️ Architecture & Project Structure

The project implements the **Repository Pattern** with an **InheritedNotifier Controller Scope** for reactive UI updates and complete test isolation.

```
lib/
├── controllers/          # State management (UserLibraryController, Scope)
├── data/                 # Sample fallback data and category constants
├── models/               # Immutable data models (Book, Category, User, Bookmark, Note, Admin)
├── repositories/         # Abstract & concrete repositories (Auth, Catalog, UserLibrary)
├── screens/              # UI screens (Home, Explore, Reader, Detail, Admin, Settings)
├── services/             # Storage service & local fallback handlers
└── widgets/              # Reusable UI widgets (BookCover, AppBottomNav, CatalogStateView)
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.24.x or newer, tested on Flutter 3.38.4 / Dart 3.10.3)
- Android SDK & Java JDK 21 (for Firestore Emulator & Android builds)
- Node.js 22+ (for Admin tools and security rules tests)

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/hoanghef/group_11_ebook_flutter_app.git
   cd group_11_ebook_flutter_app
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Run the app (Android / Emulator):**
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Quality Assurance

All features, widgets, rules, and admin tools are covered by comprehensive automated tests:

### 1. Flutter Unit & Widget Tests
```bash
flutter test
```
- **76/76 tests passing**, covering auth flows, catalog browsing, search history, reader ratio restoration, short preview safety, bookmarks, notes, and admin UI.

### 2. Code Analysis & Formatting
```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
```
- Formatter: 0 changed files.
- Analyzer: 0 issues found.

### 3. Node Administration Tool Tests
```bash
npm run test:tools
```
- **4/4 tests passing**, validating JSON catalog exports, category references, cover style schemas, and development project ID guards.

### 4. Firestore Security Rules Tests (Emulator)
```bash
npm run test:rules
```
- **15/15 tests passing** in local Firestore Emulator with Java 21, validating guest read constraints, admin custom claims, draft/archive invisibility, and UID subcollection boundaries.

---

## ☁️ Firebase Development Status

- **Development Project**: `ebook-dev-20261119-a7b3` (Firestore Native, Bangkok `asia-southeast3`).
- **Seeded Catalog**: 13 categories and 11 original fictional books seeded in development Firestore.
- **Verified on Live Firebase**:
  - Email/Password sign-up, login, logout, and token refresh.
  - Multi-UID data isolation across favorites, bookmarks, notes, and search queries.
  - Guest browsing: reads 11 published books and 13 active categories.
  - Admin probe: draft book created during probe verified hidden from public queries (`where('status', '==', 'published')`).
  - Admin claim revocation: revoked via Admin SDK and verified (`admin_after: false`).
- **Unverified on Live Firebase / Verified via Emulator & Unit Tests Only**:
  - Archived book behavior in live catalog (verified in Rules Emulator tests).
  - Catalog write rejection after claim revocation on physical client (verified via Rules Emulator and Admin SDK).
  - Reading progress restore after app kill on physical device (verified in widget tests).
  - Live network disconnection / recovery on physical device.
- For complete operational procedures and verification logs, see [docs/FIREBASE_DEVELOPMENT.md](docs/FIREBASE_DEVELOPMENT.md).

---

## ⚖️ Content Provenance & Git History Notice

- **Current Repository**: Contains 100% original fictional book metadata and previews written for this project. All covers are rendered procedurally by Flutter Canvas (`generated:*` styles). No copyrighted cover images or book texts are bundled.
- **Git History (Cleaned)**: Lịch sử commit trong nhánh này đã được làm sạch bằng `git-filter-repo`. Toàn bộ 11 tệp ảnh bìa cũ tại `assets/images/book_covers/` và các nội dung văn bản mẫu cũ chưa xác minh nguồn trong `lib/data/sample_books.dart` đã được loại bỏ hoàn toàn khỏi toàn bộ các commit trong lịch sử. Xem chi tiết kiểm kê tại [docs/CONTENT_CREDITS.md](docs/CONTENT_CREDITS.md).
