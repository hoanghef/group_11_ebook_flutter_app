import 'package:app_ebook/models/book.dart';
import 'package:app_ebook/widgets/book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Book coverBook(String ref) => Book(
  id: 'demo',
  title: 'The Lantern Between Towns',
  author: 'Mira Vale',
  coverImage: ref,
  description: '',
  categoryIds: const ['fiction'],
  content: 'Preview.',
);

void main() {
  testWidgets('Generated covers render metadata at card and detail sizes', (
    tester,
  ) async {
    for (final style in BookCover.styles) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                BookCover(book: coverBook(style), width: 60, height: 80),
                BookCover(book: coverBook(style), width: 200, height: 280),
              ],
            ),
          ),
        ),
      );
      expect(
        find.text('The Lantern Between Towns', findRichText: true),
        findsNWidgets(2),
      );
      expect(find.text('Mira Vale', findRichText: true), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Unknown legacy reference uses safe drawn fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookCover(
            book: coverBook('assets/images/book_covers/legacy.jpg'),
            width: 120,
            height: 160,
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(
      find.text('The Lantern Between Towns', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
