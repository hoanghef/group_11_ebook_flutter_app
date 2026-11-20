import 'package:app_ebook/repositories/unavailable_user_library_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Demo repository never writes personal library data', () async {
    final repository = UnavailableUserLibraryRepository();
    await expectLater(
      repository.setFavorite('demo', 'book_one', true),
      throwsStateError,
    );
    await expectLater(
      repository.saveReadingProgress('demo', 'book_one', 0.5),
      throwsStateError,
    );
  });
}
