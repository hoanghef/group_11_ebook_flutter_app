import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/user_library_controller.dart';
import '../controllers/user_library_scope.dart';
import '../models/book.dart';

class BookReaderScreen extends StatefulWidget {
  final Book book;
  final double? initialRatio;

  const BookReaderScreen({super.key, required this.book, this.initialRatio});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  ScrollController scrollController = ScrollController();
  Timer? _saveTimer;
  String? _readerUid;
  UserLibraryController? _library;
  bool _loadingProgress = false;
  bool _progressLoadFailed = false;
  bool _readyToSave = false;
  bool _saveAttempted = false;
  bool _restoring = false;
  double? _pendingRestoreRatio;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final library = UserLibraryScope.of(context);
    _library = library;
    if (library.uid == _readerUid) return;
    _saveTimer?.cancel();
    _readerUid = library.uid;
    _readyToSave = false;
    _saveAttempted = false;
    _loadingProgress = _readerUid != null;
    _progressLoadFailed = false;
    _pendingRestoreRatio = null;
    scrollProgress = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      _restoring = true;
      scrollController.jumpTo(0);
      _restoring = false;
    });
    if (_readerUid != null) unawaited(_restoreProgress(library, _readerUid!));
  }

  Future<void> _restoreProgress(
    UserLibraryController library,
    String uid,
  ) async {
    final ratio =
        widget.initialRatio ??
        await library.loadReadingProgress(widget.book.id);
    if (!mounted || _readerUid != uid || library.uid != uid) return;
    final failed = widget.initialRatio == null && library.progressLoadFailed;
    setState(() {
      _loadingProgress = false;
      _progressLoadFailed = failed;
      if (ratio != null) {
        scrollProgress = ratio.clamp(0.0, 1.0);
        _pendingRestoreRatio = scrollProgress;
      }
    });
    if (failed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _readerUid != uid || library.uid != uid) return;
      _applyPendingRestore();
      _readyToSave = true;
    });
  }

  void _applyPendingRestore() {
    final ratio = _pendingRestoreRatio;
    if (ratio == null || !scrollController.hasClients) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    _restoring = true;
    scrollController.jumpTo((ratio * maxScroll).clamp(0.0, maxScroll));
    _restoring = false;
    _pendingRestoreRatio = null;
  }

  bool get _hasScrollableContent =>
      scrollController.hasClients &&
      scrollController.position.maxScrollExtent > 0;

  @override
  void dispose() {
    _saveTimer?.cancel();
    final library = _library;
    if (_readyToSave &&
        _hasScrollableContent &&
        _pendingRestoreRatio == null &&
        library != null &&
        library.uid == _readerUid &&
        _readerUid != null) {
      unawaited(library.saveReadingProgress(widget.book.id, _currentRatio()));
    }
    scrollController.removeListener(_updateScrollProgress);
    scrollController.dispose();
    // Restore status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _updateScrollProgress() {
    if (scrollController.hasClients) {
      if (_pendingRestoreRatio == null || _hasScrollableContent) {
        setState(() {
          scrollProgress = _currentRatio();
        });
      }
      if (_readyToSave &&
          !_restoring &&
          _pendingRestoreRatio == null &&
          _hasScrollableContent &&
          _readerUid != null) {
        _saveTimer?.cancel();
        _saveTimer = Timer(const Duration(milliseconds: 600), _saveProgress);
      }
    }
  }

  double _currentRatio() {
    if (!scrollController.hasClients) return scrollProgress;
    final maxScroll = scrollController.position.maxScrollExtent;
    return maxScroll > 0
        ? (scrollController.offset / maxScroll).clamp(0.0, 1.0)
        : _pendingRestoreRatio ?? scrollProgress;
  }

  Future<void> _saveProgress() async {
    final library = _library;
    final uid = _readerUid;
    if (!_readyToSave ||
        !_hasScrollableContent ||
        _pendingRestoreRatio != null ||
        library == null ||
        uid == null ||
        library.uid != uid) {
      return;
    }
    _saveAttempted = true;
    final saved = await library.saveReadingProgress(
      widget.book.id,
      _currentRatio(),
    );
    if (!saved && mounted && _readerUid == uid && library.uid == uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reading position could not save.'),
          action: SnackBarAction(label: 'Retry', onPressed: _saveProgress),
        ),
      );
    }
  }

  void _retryProgress() {
    final library = _library;
    final uid = _readerUid;
    if (library == null || uid == null || library.uid != uid) return;
    if (_progressLoadFailed) {
      setState(() => _loadingProgress = true);
      unawaited(_restoreProgress(library, uid));
    } else {
      unawaited(_saveProgress());
    }
  }

  void _showPersonalPrompt({required bool bookmark}) {
    final library = _library;
    final uid = _readerUid;
    if (library == null || uid == null || library.uid != uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save bookmarks and notes.')),
      );
      return;
    }
    if (bookmark && !_readyToSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for reading position to load.')),
      );
      return;
    }
    if ((bookmark && library.isLoadingBookmarks) ||
        (!bookmark && library.isLoadingNotes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for your library to load.')),
      );
      return;
    }
    var value = '';
    var busy = false;
    String? error;
    final ratio = _currentRatio();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => AlertDialog(
          title: Text(bookmark ? 'Save bookmark' : 'Add note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                maxLength: bookmark ? 80 : 2000,
                maxLines: bookmark ? 1 : 4,
                decoration: InputDecoration(
                  hintText: bookmark ? 'Optional label' : 'Your note',
                ),
                onChanged: (text) => value = text,
              ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!bookmark && value.trim().isEmpty) {
                        updateDialog(() => error = 'Enter a note.');
                        return;
                      }
                      updateDialog(() {
                        busy = true;
                        error = null;
                      });
                      final saved = bookmark
                          ? await library.createBookmark(
                              widget.book.id,
                              ratio,
                              value.trim(),
                            )
                          : await library.createNote(widget.book.id, value);
                      if (!dialogContext.mounted || library.uid != uid) return;
                      if (saved) {
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              bookmark ? 'Bookmark saved.' : 'Note saved.',
                            ),
                          ),
                        );
                      } else {
                        updateDialog(() {
                          busy = false;
                          error = bookmark
                              ? 'Bookmark could not be saved. Retry.'
                              : 'Note could not be saved. Retry.';
                        });
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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
              '${(scrollProgress * 100).toInt()}% of preview',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _readerUid == null
                ? 'Sign in to save bookmarks'
                : 'Save bookmark',
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () => _showPersonalPrompt(bookmark: true),
          ),
          IconButton(
            tooltip: _readerUid == null ? 'Sign in to save notes' : 'Add note',
            icon: const Icon(Icons.note_add_outlined),
            onPressed: () => _showPersonalPrompt(bookmark: false),
          ),
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
          if (_loadingProgress)
            const Center(child: CircularProgressIndicator())
          else
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

          if (!_loadingProgress &&
              _readerUid != null &&
              (_progressLoadFailed || _saveAttempted) &&
              _library?.progressError != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(child: Text(_library!.progressError!)),
                    TextButton(
                      onPressed: _retryProgress,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
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
              color: Colors.black.withValues(alpha: 0.2),
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
                    onPressed: fontSize > 12
                        ? () {
                            setState(() {
                              fontSize -= 2;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _applyPendingRestore();
                            });
                          }
                        : null,
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
                    onPressed: fontSize < 24
                        ? () {
                            setState(() {
                              fontSize += 2;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _applyPendingRestore();
                            });
                          }
                        : null,
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
                    activeThumbColor: Colors.blue,
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
                '${(scrollProgress * 100).toInt()}% of preview',
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
