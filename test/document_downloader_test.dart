import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globelink_driver/core/utils/document_downloader.dart';

/// Returns whatever bytes/status the test sets up, without touching the network.
class _StubAdapter implements HttpClientAdapter {
  final int statusCode;
  final List<int> body;

  _StubAdapter({required this.statusCode, required this.body});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(body, statusCode);
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioReturning({required int statusCode, required List<int> body}) {
  final dio = Dio();
  dio.httpClientAdapter = _StubAdapter(statusCode: statusCode, body: body);
  return dio;
}

void main() {
  group('DocumentDownloader', () {
    test('rejects an HTML page served at 200 as not a PDF', () async {
      // The staging server answers unknown storage paths with its SPA's HTML
      // at HTTP 200; without the magic-byte check that renders as a blank
      // viewer instead of a readable error.
      final html = utf8.encode('<!doctype html>\n<html lang="en">...</html>');
      final downloader = DocumentDownloader(
        _dioReturning(statusCode: 200, body: html),
      );

      await expectLater(
        downloader.download('https://example.test/a.pdf', fileName: 'a.pdf'),
        throwsA(isA<NotAPdfException>()),
      );
    });

    test('surfaces the status code for a 403', () async {
      final downloader = DocumentDownloader(
        _dioReturning(statusCode: 403, body: utf8.encode('denied')),
      );

      await expectLater(
        downloader.download('https://example.test/a.pdf', fileName: 'a.pdf'),
        throwsA(
          isA<NotAPdfException>().having(
            (e) => e.message,
            'message',
            contains('403'),
          ),
        ),
      );
    });

    test('rejects a body too short to carry the PDF magic bytes', () async {
      final downloader = DocumentDownloader(
        _dioReturning(statusCode: 200, body: const [0x25, 0x50]),
      );

      await expectLater(
        downloader.download('https://example.test/a.pdf', fileName: 'a.pdf'),
        throwsA(isA<NotAPdfException>()),
      );
    });
  });
}
