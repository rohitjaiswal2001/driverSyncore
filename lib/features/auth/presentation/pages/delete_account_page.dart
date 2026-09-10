import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// The account deletion request form.
///
/// Confirming here schedules the account for deletion in 7 days. The driver
/// gives a written reason (sent as `deletion_reason`) and confirms once more in
/// a dialog; the page also tells them to contact the admin if they change their
/// mind inside that window.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// The button stays disabled until a reason is typed, so the confirm dialog
  /// is never the first place the driver learns something is missing.
  bool get _canSubmit => _reasonController.text.trim().isNotEmpty;

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final confirmed = await showAppConfirmDialog(
      context,
      icon: Icons.delete_forever_rounded,
      title: 'Delete your account?',
      message:
          'You will be signed out and will not be able to log in again. Your '
          'account is deleted after 7 days - contact the admin before then if '
          'this is a mistake.',
      confirmLabel: 'Delete',
      accentColor: AppColors.danger,
      accentBackground: AppColors.dangerBg,
    );

    if (confirmed && mounted) {
      context.read<AuthBloc>().add(
        DeleteAccountRequested(deletionReason: _reasonController.text.trim()),
      );
    }
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AccountDeleted) {
      TopSnackBar.show(
        context,
        message: state.message,
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
        duration: const Duration(seconds: 6),
      );
    } else if (state is AccountDeleteFailure) {
      TopSnackBar.show(
        context,
        message: state.errorMessage,
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: _onAuthStateChanged,
      builder: (context, state) {
        final isDeleting = state is AccountDeleting;
        final isDeleted = state is AccountDeleted;

        return PopScope(
          // Nothing may interrupt an in-flight deletion, and once the account
          // is gone the driver leaves by choosing where to go - never by
          // backing out onto a page holding a cleared session.
          canPop: !isDeleting && !isDeleted,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              centerTitle: false,
              automaticallyImplyLeading: false,
              leading: isDeleted
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.navy,
                      ),
                      tooltip: 'Back',
                      onPressed: isDeleting
                          ? null
                          : () => Navigator.maybePop(context),
                    ),
              title: Text(
                isDeleted ? 'Account Deleted' : 'Delete Account',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            body: LoadingOverlay(
              isLoading: isDeleting,
              spinnerColor: AppColors.danger,
              child: isDeleted ? _buildDeletedState() : _buildForm(isDeleting),
            ),
          ),
        );
      },
    );
  }

  /// Shown once the account is gone, in place of the form.
  ///
  /// Deliberately a screen rather than a dialog, and it does not time out or
  /// dismiss itself: the driver reads it at their own pace and leaves only by
  /// picking one of the two ways forward.
  Widget _buildDeletedState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              28 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: AppColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Account deleted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your account has been scheduled for deletion and you have '
                  'been signed out.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 22),
                _adminNotice(),
                const SizedBox(height: 28),
                const Text(
                  'You can sign in with a different account, or create a new '
                  'one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _leaveDeletedScreen(),
                    icon: const Icon(Icons.login_rounded, size: 19),
                    label: const Text(
                      'Go to login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _leaveDeletedScreen(openRegister: true),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 19),
                    label: const Text(
                      'Create new account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The only way off the deleted screen. Clears the toast first so it cannot
  /// trail the driver onto the next page.
  void _leaveDeletedScreen({bool openRegister = false}) {
    TopSnackBar.dismiss();
    context.read<AuthBloc>().add(
      AccountDeletionAcknowledged(openRegister: openRegister),
    );
  }

  Widget _buildForm(bool isDeleting) {
    return AbsorbPointer(
      absorbing: isDeleting,
      child: Form(
        key: _formKey,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            28 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            _buildWarningCard(),
            const SizedBox(height: 24),

            LabeledFormField(
              bottomSpacing: 12,
              label: 'Why are you deleting your account?',
              child: TextFormField(
                controller: _reasonController,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                decoration: const InputDecoration(
                  hintText: 'Tell us why you are leaving',
                  alignLabelWithHint: true,
                ),
                // Keeps the delete button's enabled state in step with what
                // has actually been typed.
                onChanged: (_) => setState(() {}),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please tell us why you are leaving'
                    : null,
              ),
            ),

            const SizedBox(height: 16),

            _buildDeleteButton(),
            const SizedBox(height: 12),

            SizedBox(
              height: 50,
              child: TextButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.maybePop(context),
                child: const Text(
                  'Keep my account',
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dangerTint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Your account will be deleted after 7 days',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Once the 7 days are up, we permanently remove:',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 10),
          _bullet('Your profile, photo and contact details'),
          _bullet('Your trip and shipment history'),
          _bullet('Any documents uploaded to your account'),
          const SizedBox(height: 12),
          const Text(
            'You will be signed out immediately and will not be able to log '
            'in again.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 12),
          _adminNotice(),
        ],
      ),
    );
  }

  /// The 7-day window is only useful if the driver knows who to reach, so the
  /// route back is spelled out rather than left implied.
  Widget _adminNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dangerTint),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.info,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Deleted by mistake? Contact the admin before the 7 days are up '
              'and your account can be restored.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5, right: 10),
            child: Icon(Icons.circle, size: 5, color: AppColors.danger),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    final enabled = _canSubmit;

    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.dangerTint,
          disabledForegroundColor: AppColors.danger.withValues(alpha: 0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: enabled ? _handleSubmit : null,
        icon: const Icon(Icons.delete_forever_rounded, size: 20),
        label: const Text(
          'Delete my account',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
