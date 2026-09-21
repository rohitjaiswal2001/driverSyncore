import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class OtpInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const OtpInputField({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
  });

  @override
  State<OtpInputField> createState() => OtpInputFieldState();
}

/// Zero-width space parked in every box so none of them is ever really empty.
///
/// A soft keyboard reports nothing at all when backspace is pressed in an
/// empty field — no key event, no edit — so a box the user tapped into but
/// never typed in cannot see the press. With this character sitting in the
/// box there is always something to delete, which turns every backspace into
/// an ordinary text change this widget can act on. It renders as nothing, and
/// [_digits] rather than the controllers is what the OTP is read from.
const String _kEmptyMarker = '​';

class OtpInputFieldState extends State<OtpInputField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  /// The digit in each box, or an empty string. Kept alongside the
  /// controllers because their text also carries [_kEmptyMarker], and because
  /// a change handler needs to know what the box held *before* the edit.
  late final List<String> _digits;

  @override
  void initState() {
    super.initState();
    _digits = List.filled(widget.length, '');
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(text: _kEmptyMarker),
    );
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    for (final controller in _controllers) {
      controller.addListener(_onVisualStateChanged);
    }
    for (final node in _focusNodes) {
      node.addListener(_onVisualStateChanged);
    }
  }

  void _onVisualStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get code => _digits.join();

  void clear() {
    for (var index = 0; index < widget.length; index++) {
      _setDigit(index, '');
    }
    _focusNodes.first.requestFocus();
  }

  /// Writes [digit] (or clears the box when it is empty) and leaves the caret
  /// after the marker, so the next backspace deletes the marker rather than
  /// landing on an empty selection.
  void _setDigit(int index, String digit) {
    _digits[index] = digit;
    final text = '$_kEmptyMarker$digit';
    _controllers[index].value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _notify() {
    final value = code;
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      FocusScope.of(context).unfocus();
      widget.onCompleted?.call(value);
    }
  }

  // Handles typing, backspace, and pasting a full code into one box.
  void _handleChanged(int index, String value) {
    // The marker is gone, so the user backspaced past it.
    if (value.isEmpty) {
      _handleBackspace(index);
      return;
    }

    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    // A paste, or a code delivered by the keyboard's SMS autofill.
    if (digits.length > 1) {
      var target = index;
      for (final digit in digits.split('')) {
        if (target >= widget.length) break;
        _setDigit(target, digit);
        target++;
      }
      final nextEmpty = target.clamp(0, widget.length - 1);
      _focusNodes[nextEmpty].requestFocus();
      _notify();
      return;
    }

    // Only the marker is left: the box's own digit was deleted. Focus stays
    // put, so a second backspace is what steps back to the previous box.
    if (digits.isEmpty) {
      _setDigit(index, '');
      _notify();
      return;
    }

    _setDigit(index, digits);
    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _notify();
  }

  /// Backspace with nothing left in this box: erase the nearest digit behind
  /// it and put the caret there.
  ///
  /// It walks back over blank boxes rather than stepping into the one
  /// immediately before, so tapping a box the user never filled and pressing
  /// backspace still deletes a digit. Stepping one box at a time would look
  /// like the key had done nothing. With no digits behind it at all, the
  /// caret just returns to the first box.
  void _handleBackspace(int index) {
    final hadDigit = _digits[index].isNotEmpty;
    _setDigit(index, '');

    if (!hadDigit) {
      final previous = _lastFilledBefore(index);
      if (previous != null) {
        _setDigit(previous, '');
        _focusNodes[previous].requestFocus();
      } else if (index > 0) {
        _focusNodes.first.requestFocus();
      }
    }
    _notify();
  }

  int? _lastFilledBefore(int index) {
    for (var i = index - 1; i >= 0; i--) {
      if (_digits[i].isNotEmpty) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Boxes shrink on narrow screens instead of overflowing the row.
        const maxBoxWidth = 48.0;
        const minGap = 8.0;
        final available = constraints.maxWidth;
        final boxWidth = available.isFinite
            ? ((available - minGap * (widget.length - 1)) / widget.length)
                  .clamp(34.0, maxBoxWidth)
            : maxBoxWidth;
        final boxHeight = boxWidth * 56 / 48;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (index) {
            final hasFocus = _focusNodes[index].hasFocus;
            final isFilled = _digits[index].isNotEmpty;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: boxWidth,
              height: boxHeight,
              decoration: BoxDecoration(
                color: hasFocus || isFilled
                    ? Colors.white
                    : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasFocus
                      ? AppColors.primary
                      : isFilled
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : AppColors.border,
                  width: hasFocus ? 1.6 : 1.2,
                ),
                boxShadow: hasFocus
                    ? [
                        // Flat focus ring, then a soft lift under it.
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.16),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              clipBehavior: Clip.antiAlias,
              // Center keeps the collapsed field's single line centered in
              // the box at every box height.
              child: Center(
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  keyboardType: TextInputType.number,
                  // The marker has to survive filtering, or the box would be
                  // empty again and backspace would go unreported.
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp('[0-9$_kEmptyMarker]'),
                    ),
                  ],
                  cursorColor: AppColors.primary,
                  cursorWidth: 2,
                  cursorHeight: 22,
                  cursorRadius: const Radius.circular(2),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    isCollapsed: true,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) => _handleChanged(index, value),
                  // Selecting the whole box means a typed digit replaces what
                  // is there instead of appending to it.
                  onTap: () {
                    _controllers[index].selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controllers[index].text.length,
                    );
                  },
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
