import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syntracore_driver/core/di/injection_container.dart' as di;
import 'package:syntracore_driver/features/trips/presentation/pages/driver_main_shell.dart';
import 'package:syntracore_driver/features/trips/presentation/bloc/trips_bloc.dart';
import 'package:syntracore_driver/features/trips/presentation/pages/driver_dashboard_page.dart';
import 'package:syntracore_driver/features/auth/presentation/bloc/auth_bloc.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return Future.value(_MockHttpClientRequest(url));
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('get', url);

  @override
  void noSuchMethod(Invocation invocation) {}
}

class _MockHttpClientRequest implements HttpClientRequest {
  final Uri url;

  _MockHttpClientRequest(this.url);

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  String get method => 'GET';

  @override
  Uri get uri => url;

  @override
  Future<HttpClientResponse> close() {
    return Future.value(_MockHttpClientResponse(url));
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  ContentType? get contentType => ContentType.json;

  @override
  List<String>? operator [](String name) {
    if (name.toLowerCase() == 'content-type') {
      return ['application/json; charset=utf-8'];
    }
    return null;
  }

  @override
  String? value(String name) {
    if (name.toLowerCase() == 'content-type') {
      return 'application/json; charset=utf-8';
    }
    return null;
  }

  @override
  void forEach(void Function(String name, List<String> values) f) {
    f('content-type', ['application/json; charset=utf-8']);
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}

class _MockHttpClientResponse implements HttpClientResponse {
  final Uri url;

  _MockHttpClientResponse(this.url);

  final Uint8List _imageData = Uint8List.fromList([
    0x47,
    0x49,
    0x46,
    0x38,
    0x39,
    0x61,
    0x01,
    0x00,
    0x01,
    0x00,
    0x80,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xff,
    0xff,
    0xff,
    0x21,
    0xf9,
    0x04,
    0x01,
    0x00,
    0x00,
    0x00,
    0x00,
    0x2c,
    0x00,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x01,
    0x00,
    0x00,
    0x02,
    0x02,
    0x44,
    0x01,
    0x00,
    0x3b,
  ]);

  List<int> get _responseBytes {
    if (url.path.contains('/profile')) {
      return utf8.encode(jsonEncode({
        "success": true,
        "data": {
          "id": "43",
          "first_name": "Ramesh",
          "last_name": "Kumar",
          "email": "ramesh@yopmail.com",
          "phone": "88902",
          "role": "driver",
          "company_name": "Syntracore",
          "is_verified": true,
          "token": "mock_token",
          "profile_image": null
        }
      }));
    }
    return _imageData;
  }

  @override
  Stream<S> cast<S>() {
    return Stream<Uint8List>.fromIterable([Uint8List.fromList(_responseBytes)]).cast<S>();
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<Uint8List>.fromIterable([Uint8List.fromList(_responseBytes)]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _responseBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  String get reasonPhrase => 'OK';

  @override
  void noSuchMethod(Invocation invocation) {}
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    try {
      await di.init();
    } catch (_) {}
  });

  testWidgets('DriverDashboardPage renders successfully with pump', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TripsBloc>(create: (_) => di.sl<TripsBloc>()),
          BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()),
        ],
        child: MaterialApp(
          home: DriverDashboardPage(
            username: 'BK-2026-10025',
            onNavigateToProfile: () {},
            onNavigateToTracking: () {},
            onNavigateToOrders: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DriverDashboardPage), findsOneWidget);
  });

  testWidgets('DriverMainShell renders successfully with pump', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TripsBloc>(create: (_) => di.sl<TripsBloc>()),
          BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()),
        ],
        child: MaterialApp(home: DriverMainShell(username: 'BK-2026-10025')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DriverMainShell), findsOneWidget);
  });
}
