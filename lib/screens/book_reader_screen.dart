import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';

class BookReaderScreen extends StatefulWidget {
  final Book book;

  const BookReaderScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  ScrollController scrollController = ScrollController();
  double scrollProgress = 0.0;
  double fontSize = 16.0;
  bool isDarkMode = false;
  bool showSettings = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_updateScrollProgress);
    // Hide status bar for immersive reading
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    scrollController.removeListener(_updateScrollProgress);
    scrollController.dispose();
    // Restore status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _updateScrollProgress() {
    if (scrollController.hasClients) {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.offset;
      setState(() {
        scrollProgress = maxScroll > 0 ? (currentScroll / maxScroll) : 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${(scrollProgress * 100).toInt()}% complete',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(showSettings ? Icons.close : Icons.settings),
            onPressed: () {
              setState(() {
                showSettings = !showSettings;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: LinearProgressIndicator(
            value: scrollProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? Colors.white : Colors.blue,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book title and author
                Text(
                  widget.book.title,
                  style: TextStyle(
                    fontSize: fontSize + 6,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'by ${widget.book.author}',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 30),

                // Book content
                Text(
                  widget.book.content,
                  style: TextStyle(
                    fontSize: fontSize,
                    height: 1.6,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),

                // Add some bottom padding for better reading experience
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Settings panel
          if (showSettings) _buildSettingsPanel(),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        width: 250,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reading Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              // Font size
              Text(
                'Font Size',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: fontSize > 12 ? () {
                      setState(() {
                        fontSize -= 2;
                      });
                    } : null,
                    icon: const Icon(Icons.text_decrease),
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  Text(
                    '${fontSize.toInt()}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: fontSize < 24 ? () {
                      setState(() {
                        fontSize += 2;
                      });
                    } : null,
                    icon: const Icon(Icons.text_increase),
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Dark mode toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        isDarkMode = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Reading progress
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: scrollProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 4),
              Text(
                '${(scrollProgress * 100).toInt()}% completed',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}