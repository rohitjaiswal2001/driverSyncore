import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Raised when a document URL resolves to something that isn't a PDF.
class NotAPdfException implements Exception {
  final String message;
  const NotAPdfException(this.message);

  @override
  String toString() => message;
}

/// Downloads booking PDFs to a cache file so the native PDF view can render
/// them with full pinch/pan/page gestures.
///
/// The response is validated to actually start with the `%PDF-` magic bytes:
/// the staging server currently answers unknown storage paths with its SPA's
/// HTML at HTTP 200, which would otherwise render as a blank viewer instead of
/// a clear error.
class DocumentDownloader {
  final Dio _dio;

  const DocumentDownloader(this._dio);

  Future<File> download(String url, {required String fileName}) async {
    final Response<List<int>> response;
    try {
      response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          // Handle any status ourselves so a 403/404 becomes a readable
          // message instead of a raw Dio stack trace.
          validateStatus: (_) => true,
          headers: const {'Accept': 'application/pdf'},
        ),
      );
    } on DioException catch (e) {
      throw Exception(
        'Could not reach the document server. ${e.message ?? ''}'.trim(),
      );
    }

    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw NotAPdfException(
        'The server returned $status for this document. It may not have been '
        'published yet.',
      );
    }

    final bytes = response.data ?? const <int>[];
    if (!_looksLikePdf(bytes)) {
      throw const NotAPdfException(
        'This document is not available on the server yet. Ask your fleet '
        'manager to re-publish the booking PDF.',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Every valid PDF starts with the bytes `%PDF-`.
  static bool _looksLikePdf(List<int> bytes) {
    if (bytes.length < 5) return false;
    const magic = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }
}
