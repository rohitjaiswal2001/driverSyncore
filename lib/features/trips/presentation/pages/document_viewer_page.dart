import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/document_downloader.dart';

/// Full-screen in-app PDF reader with native pinch-zoom, pan and page swipe.
class DocumentViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const DocumentViewerPage({super.key, required this.url, required this.title});

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  File? _file;
  String? _error;
  bool _isLoading = true;

  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final file = await di.sl<DocumentDownloader>().download(
        widget.url,
        fileName: 'booking-doc-${widget.url.hashCode}.pdf',
      );
      if (!mounted) return;
      setState(() {
        _file = file;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            if (_totalPages > 0)
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Open outside the app',
            icon: const Icon(
              Icons.open_in_new_rounded,
              color: AppColors.textDark,
            ),
            onPressed: _openExternally,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading document…',
              style: TextStyle(color: AppColors.textMedium, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final error = _error;
    if (error != null) return _buildError(error);

    final file = _file;
    if (file == null) return _buildError('Document could not be opened.');

    // PDFView provides pinch-to-zoom, double-tap zoom, pan and swipe natively.
    return PDFView(
      filePath: file.path,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: false,
      fitPolicy: FitPolicy.WIDTH,
      onRender: (pages) => setState(() => _totalPages = pages ?? 0),
      onPageChanged: (page, _) => setState(() => _currentPage = page ?? 0),
      onError: (e) => setState(() => _error = e.toString()),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.danger,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Can't open this document",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try again'),
                  ),
                ),
                SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _openExternally,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open in browser'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
