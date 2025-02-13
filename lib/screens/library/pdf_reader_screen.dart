import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/book.dart';
import '../../services/book_service.dart';

class PdfReaderScreen extends StatefulWidget {
  final Book book;

  const PdfReaderScreen({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final BookService _bookService = BookService();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  late Future<Map<String, int>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _bookService.getReadingProgress(widget.book.id);
  }

  void _saveProgress(int pageNumber) {
    _bookService.updateReadingProgress(widget.book.id, pageNumber);
  }

  void _loadInitialPage(int page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pdfViewerController.pageCount >= page) {
        _pdfViewerController.jumpToPage(page);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              final currentPage = _pdfViewerController.pageNumber;
              _saveProgress(currentPage);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Saved progress at page $currentPage'),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final initialPage = snapshot.data?['currentPage'] ?? 1;
          _loadInitialPage(initialPage);

          return SfPdfViewer.network(
            widget.book.pdfUrl,
            controller: _pdfViewerController,
            onPageChanged: (PdfPageChangedDetails details) {
              _saveProgress(details.newPageNumber);
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }
}
