import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syntracore_driver/features/auth/presentation/widgets/otp_input_field.dart';

/// Backspace on a soft keyboard is not a key event: the engine simply sends
/// the new editing value. These tests drive the field the same way, so they
/// exercise the path a real iOS/Android keyboard takes rather than a
/// desktop-only key press.
void main() {
  final key = GlobalKey<OtpInputFieldState>();

  Future<void> pumpField(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpInputField(key: key, length: 6),
        ),
      ),
    );
  }

  /// What the platform reports when the user deletes the last character in a
  /// box — including the invisible marker the widget parks there.
  Future<void> backspace(WidgetTester tester) async {
    tester.testTextInput.updateEditingValue(TextEditingValue.empty);
    await tester.pump();
  }

  Future<void> typeDigit(WidgetTester tester, String digit) async {
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: digit,
        selection: TextSelection.collapsed(offset: digit.length),
      ),
    );
    await tester.pump();
  }

  testWidgets('typing digits fills the boxes in order', (tester) async {
    await pumpField(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    for (final digit in ['1', '2', '3']) {
      await typeDigit(tester, digit);
    }

    expect(key.currentState!.code, '123');
  });

  testWidgets('backspace in an empty box clears the previous one', (
    tester,
  ) async {
    await pumpField(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    for (final digit in ['1', '2', '3']) {
      await typeDigit(tester, digit);
    }

    // Focus is now on the empty fourth box. This is the case a soft keyboard
    // reports nothing for unless the box holds the marker.
    await backspace(tester);

    expect(key.currentState!.code, '12');
  });

  testWidgets('backspace on a filled box clears only that box', (tester) async {
    await pumpField(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    for (final digit in ['1', '2', '3']) {
      await typeDigit(tester, digit);
    }

    await backspace(tester); // empty 4th box -> clears the 3
    await backspace(tester); // now on the 2, which still holds a digit

    expect(key.currentState!.code, '1');
  });

  testWidgets('backspace on the first box is a no-op', (tester) async {
    await pumpField(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    await backspace(tester);
    await backspace(tester);

    expect(key.currentState!.code, '');
  });

  testWidgets('tapping an empty box then backspacing clears the code behind '
      'it', (tester) async {
    await pumpField(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    for (final digit in ['1', '2']) {
      await typeDigit(tester, digit);
    }

    // The reported bug: tap a blank box further along, then press backspace.
    await tester.tap(find.byType(TextField).at(4));
    await tester.pump();
    await backspace(tester);

    expect(key.currentState!.code, '1');
  });

  testWidgets('a pasted code fills every box', (tester) async {
    await pumpField(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    await typeDigit(tester, '123456');

    expect(key.currentState!.code, '123456');
  });

  testWidgets('clear() empties every box', (tester) async {
    await pumpField(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await typeDigit(tester, '123456');

    key.currentState!.clear();
    await tester.pump();

    expect(key.currentState!.code, '');
  });
}
