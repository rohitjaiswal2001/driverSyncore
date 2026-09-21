import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:globelink_driver/core/di/injection_container.dart' as di;
import 'package:globelink_driver/core/layout/responsive.dart';
import 'package:globelink_driver/main.dart';

/// Logical sizes the app is actually shipped against. The iPad entries are
/// the reason this file exists: `TARGETED_DEVICE_FAMILY = 1,2` means every
/// screen can be handed any of these.
const _iPhone = Size(390, 844);
const _iPadPortrait = Size(1024, 1366);
const _iPadLandscape = Size(1366, 1024);

/// Renders [child] as the whole app at [size] and hands back the tester.
Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = size * 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AdaptiveContainer', () {
    testWidgets('fills the width on a phone', (tester) async {
      await _pumpAt(
        tester,
        _iPhone,
        const AdaptiveContainer.form(child: SizedBox.expand()),
      );

      // Below the cap the wrapper must be invisible, or it would change the
      // phone layouts the screens were designed at.
      expect(tester.getSize(find.byType(SizedBox)).width, _iPhone.width);
    });

    testWidgets('caps and centres the width on a portrait iPad', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        _iPadPortrait,
        const AdaptiveContainer.form(child: SizedBox.expand()),
      );

      expect(tester.getSize(find.byType(SizedBox)).width, AppContentWidth.form);
      expect(
        tester.getCenter(find.byType(SizedBox)).dx,
        _iPadPortrait.width / 2,
      );
    });

    testWidgets('caps the width on a landscape iPad', (tester) async {
      await _pumpAt(
        tester,
        _iPadLandscape,
        const AdaptiveContainer(child: SizedBox.expand()),
      );

      expect(
        tester.getSize(find.byType(SizedBox)).width,
        AppContentWidth.content,
      );
    });

    testWidgets('padding is applied inside the cap', (tester) async {
      await _pumpAt(
        tester,
        _iPadLandscape,
        const AdaptiveContainer.form(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox.expand(),
        ),
      );

      expect(
        tester.getSize(find.byType(SizedBox)).width,
        AppContentWidth.form - 48,
      );
    });
  });

  group('adaptiveScrollPadding', () {
    testWidgets('keeps the designed gutter on a phone', (tester) async {
      late EdgeInsets padding;
      await _pumpAt(
        tester,
        _iPhone,
        Builder(
          builder: (context) {
            padding = adaptiveScrollPadding(context, horizontal: 16);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(padding.left, 16);
      expect(padding.right, 16);
    });

    testWidgets('splits the leftover width evenly on a landscape iPad', (
      tester,
    ) async {
      late EdgeInsets padding;
      await _pumpAt(
        tester,
        _iPadLandscape,
        Builder(
          builder: (context) {
            padding = adaptiveScrollPadding(context, horizontal: 16);
            return const SizedBox.shrink();
          },
        ),
      );

      // Whatever the side padding works out to, the content strip left
      // between the two sides is exactly the cap.
      expect(padding.left, padding.right);
      expect(
        _iPadLandscape.width - padding.left - padding.right,
        AppContentWidth.content,
      );
    });

    testWidgets('passes vertical padding through untouched', (tester) async {
      late EdgeInsets padding;
      await _pumpAt(
        tester,
        _iPadLandscape,
        Builder(
          builder: (context) {
            padding = adaptiveScrollPadding(
              context,
              horizontal: 16,
              top: 20,
              bottom: 24,
            );
            return const SizedBox.shrink();
          },
        ),
      );

      expect(padding.top, 20);
      expect(padding.bottom, 24);
    });
  });

  group('breakpoints', () {
    testWidgets('a landscape iPad reads as wide, a phone does not', (
      tester,
    ) async {
      late bool phoneIsWide;
      await _pumpAt(
        tester,
        _iPhone,
        Builder(
          builder: (context) {
            phoneIsWide = context.isWideLayout;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(phoneIsWide, isFalse);

      late bool padIsWide;
      late bool padIsTablet;
      await _pumpAt(
        tester,
        _iPadLandscape,
        Builder(
          builder: (context) {
            padIsWide = context.isWideLayout;
            padIsTablet = context.isTabletDevice;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(padIsWide, isTrue);
      // Shortest side is 1024, so the device reads as a tablet either way up.
      expect(padIsTablet, isTrue);
    });
  });

  group('login page on an iPad', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      try {
        await di.init();
      } catch (_) {}
    });

    testWidgets('does not stretch its fields across a landscape iPad', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize = _iPadLandscape * 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MyApp());
      await tester.pump();

      final fields = find.byType(TextFormField);
      expect(fields, findsWidgets);

      // 24pt of horizontal padding sits inside the form cap on each side.
      const maxFieldWidth = AppContentWidth.form - 48;
      for (var i = 0; i < tester.widgetList(fields).length; i++) {
        expect(
          tester.getSize(fields.at(i)).width,
          lessThanOrEqualTo(maxFieldWidth),
          reason: 'login field $i should be capped, not full-window',
        );
      }
    });
  });
}
