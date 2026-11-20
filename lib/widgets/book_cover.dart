import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/book.dart';

/// Cover artwork made only from Flutter shapes, color and book metadata.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  BookCover.reference({
    super.key,
    required String coverRef,
    required String title,
    required String author,
    this.width,
    this.height,
    this.borderRadius = 8,
  }) : book = Book(
         id: '',
         title: title,
         author: author,
         coverImage: coverRef,
         description: '',
         categoryIds: const [],
         content: '',
       );

  final Book book;
  final double? width;
  final double? height;
  final double borderRadius;

  static const styles = <String>[
    'generated:midnight',
    'generated:lagoon',
    'generated:coral',
    'generated:forest',
    'generated:plum',
    'generated:sunrise',
  ];

  static bool isGeneratedStyle(String value) => styles.contains(value);

  @override
  Widget build(BuildContext context) {
    final palette = _palette(book.coverImage);
    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 150.0;
          final h = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 210.0;
          final compact = w < 90 || h < 115;
          final scale = math.min(w / 150, h / 210).clamp(0.34, 1.6);
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [palette.$1, palette.$2],
                    ),
                  ),
                ),
                Positioned(
                  top: -h * 0.16,
                  right: -w * 0.22,
                  child: Container(
                    width: w * 0.78,
                    height: w * 0.78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.$3.withValues(alpha: 0.7),
                        width: math.max(2, w * 0.025),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -w * 0.18,
                  bottom: h * 0.12,
                  child: Transform.rotate(
                    angle: -0.32,
                    child: Container(
                      width: w * 1.2,
                      height: h * 0.2,
                      color: palette.$3.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(math.max(5, w * 0.09)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: math.max(12, w * 0.22),
                        height: math.max(2, h * 0.012),
                        color: palette.$3,
                      ),
                      const Spacer(),
                      RichText(
                        maxLines: compact ? 3 : 4,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          text: book.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19 * scale,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            shadows: const [
                              Shadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: math.max(2, h * 0.025)),
                      RichText(
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          text: book.author,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Unknown legacy asset references intentionally map to a safe neutral cover.
  static (Color, Color, Color) _palette(String ref) => switch (ref) {
    'generated:midnight' => (
      const Color(0xFF121B3A),
      const Color(0xFF435887),
      const Color(0xFFFFD99A),
    ),
    'generated:lagoon' => (
      const Color(0xFF075A67),
      const Color(0xFF3EA6A0),
      const Color(0xFFBCEDE1),
    ),
    'generated:coral' => (
      const Color(0xFF893D53),
      const Color(0xFFE47B70),
      const Color(0xFFFFD4AA),
    ),
    'generated:forest' => (
      const Color(0xFF254D3A),
      const Color(0xFF6C9669),
      const Color(0xFFD5E0A2),
    ),
    'generated:plum' => (
      const Color(0xFF48204F),
      const Color(0xFF965F91),
      const Color(0xFFF1C9E2),
    ),
    'generated:sunrise' => (
      const Color(0xFF9E5228),
      const Color(0xFFDB9B45),
      const Color(0xFFFFE2A6),
    ),
    _ => (
      const Color(0xFF34404B),
      const Color(0xFF667787),
      const Color(0xFFDAE1E8),
    ),
  };
}
