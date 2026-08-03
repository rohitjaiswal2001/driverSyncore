import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Shared confirmation dialog for destructive or irreversible actions.
///
/// Resolves to `true` only when the user taps the confirm button; dismissing
/// the dialog (barrier tap, back gesture, cancel) resolves to `false`.
///
/// If [onConfirmAsync] is provided, a loading spinner will be shown on the
/// confirm button while the async task runs before closing the dialog.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Confirm',
  Color accentColor = AppColors.primary,
  Color accentBackground = AppColors.primaryLight,
  Future<void> Function()? onConfirmAsync,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) {
      return _AppConfirmDialogWidget(
        icon: icon,
        title: title,
        message: message,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        accentColor: accentColor,
        accentBackground: accentBackground,
        onConfirmAsync: onConfirmAsync,
      );
    },
  );

  return result ?? false;
}

class _AppConfirmDialogWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final Color accentColor;
  final Color accentBackground;
  final Future<void> Function()? onConfirmAsync;

  const _AppConfirmDialogWidget({
    required this.icon,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.accentColor,
    required this.accentBackground,
    this.onConfirmAsync,
  });

  @override
  State<_AppConfirmDialogWidget> createState() =>
      _AppConfirmDialogWidgetState();
}

class _AppConfirmDialogWidgetState extends State<_AppConfirmDialogWidget> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    HapticFeedback.mediumImpact();
    if (widget.onConfirmAsync != null) {
      setState(() => _isLoading = true);
      try {
        await widget.onConfirmAsync!();
      } catch (_) {}
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.accentBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context, false),
                      child: Text(
                        widget.cancelLabel,
                        style: const TextStyle(
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleConfirm,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              widget.confirmLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
