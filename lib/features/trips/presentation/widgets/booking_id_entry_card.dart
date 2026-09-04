import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

/// Empty-state card asking the driver for a Booking Order ID.
///
/// This is the entry point to the whole dashboard, so it stays forgiving:
/// input is normalised to uppercase, the submit button reflects whether there
/// is anything to submit, and a previous error clears the moment the driver
/// starts correcting it.
class BookingIdEntryCard extends StatefulWidget {
  final void Function(String bookingId) onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final String? initialValue;

  const BookingIdEntryCard({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
    this.initialValue,
  });

  @override
  State<BookingIdEntryCard> createState() => _BookingIdEntryCardState();
}

class _BookingIdEntryCardState extends State<BookingIdEntryCard> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  /// Hidden as soon as the driver edits the field, so stale errors do not sit
  /// under text that has already been corrected.
  bool _showError = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant BookingIdEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != null &&
        widget.errorMessage != oldWidget.errorMessage) {
      _showError = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;
    _focusNode.unfocus();
    HapticFeedback.selectionClick();
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final showError = widget.errorMessage != null && _showError;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.accentBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find My Shipment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Enter your Order ID to load the shipment and '
                      'start your trip.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMedium,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !widget.isLoading,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              LengthLimitingTextInputFormatter(32),
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
              _UpperCaseFormatter(),
            ],
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: 'e.g 10293845',
              hintStyle: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
              prefixIcon: const Icon(
                Icons.tag_rounded,
                color: AppColors.textMedium,
                size: 20,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    color: AppColors.textLight,
                    tooltip: 'Clear',
                    onPressed: widget.isLoading
                        ? null
                        : () {
                            _controller.clear();
                            setState(() => _showError = false);
                          },
                  );
                },
              ),
              fillColor: AppColors.inputBackground,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: showError ? AppColors.danger : AppColors.border,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: showError ? AppColors.danger : AppColors.navy,
                  width: 1.8,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            // The clear button and submit button track the controller directly;
            // this only has to retire a stale error.
            onChanged: (_) {
              if (_showError && widget.errorMessage != null) {
                setState(() => _showError = false);
              }
            },
            onSubmitted: (_) => _submit(),
          ),

          if (showError) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.danger,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final canSubmit =
                  value.text.trim().isNotEmpty && !widget.isLoading;
              return SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.navy.withValues(
                      alpha: 0.35,
                    ),
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.85,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: canSubmit ? _submit : null,
                  child: widget.isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Loading shipment…',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Get Order Info',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'The Booking Order ID is on your trip sheet or in the '
                  'assignment message from your fleet manager.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppColors.textLight.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Uppercases as the driver types, keeping the caret where they left it.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
