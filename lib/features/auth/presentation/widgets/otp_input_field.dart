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

class OtpInputFieldState extends State<OtpInputField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  // Ancestor nodes that catch backspace bubbling up from an empty field,
  // without ever taking focus themselves.
  late final List<FocusNode> _backspaceCatcherNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.backspace ||
                  event.logicalKey == LogicalKeyboardKey.delete)) {
            if (_controllers[index].text.isEmpty && index > 0) {
              _controllers[index - 1].clear();
              _focusNodes[index - 1].requestFocus();
              _notify();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
      ),
    );
    _backspaceCatcherNodes = List.generate(
      widget.length,
      (_) => FocusNode(canRequestFocus: false, skipTraversal: true),
    );
    for (final node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final node in _backspaceCatcherNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get code => _controllers.map((c) => c.text).join();

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  void _notify() {
    final value = code;
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      FocusScope.of(context).unfocus();
      widget.onCompleted?.call(value);
    }
  }

  // Handles both single-digit typing and pasting a full code into one box.
  void _handleChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 1) {
      var target = index;
      for (final digit in digits.split('')) {
        if (target >= widget.length) break;
        _controllers[target].text = digit;
        target++;
      }
      final lastFilled = (target - 1).clamp(0, widget.length - 1);
      _controllers[lastFilled].selection = TextSelection.collapsed(
        offset: _controllers[lastFilled].text.length,
      );
      final nextEmpty = target.clamp(0, widget.length - 1);
      _focusNodes[nextEmpty].requestFocus();
      _notify();
      return;
    }

    if (digits.isEmpty) {
      _controllers[index].clear();
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      _notify();
      return;
    }

    _controllers[index].text = digits;
    _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _notify();
  }

  void _handleBackspaceOnEmpty(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      _notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        final hasFocus = _focusNodes[index].hasFocus;
        return SizedBox(
          width: 48,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFocus ? AppColors.primary : AppColors.border,
                width: hasFocus ? 2 : 1,
              ),
              boxShadow: [
                if (hasFocus)
                  BoxShadow(
                    color: AppColors.primary.withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: KeyboardListener(
              focusNode: _backspaceCatcherNodes[index],
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace) {
                  _handleBackspaceOnEmpty(index);
                }
              },
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) => _handleChanged(index, value),
                onTap: () {
                  _controllers[index].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _controllers[index].text.length,
                  );
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}
