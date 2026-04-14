import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Shows a re-authentication dialog prompting the user to confirm
/// their current password before performing a sensitive action.
/// Returns `true` if re-authentication succeeded.
Future<bool> showReauthDialog(BuildContext context, {bool isDark = false}) async {
  final passwordController = TextEditingController();
  bool obscure = true;
  String? errorMessage;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Confirm Identity',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please enter your current password to continue.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: obscure,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: 'Current password',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                ),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDim : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                errorText: errorMessage,
                errorStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 18,
                    color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                  ),
                  onPressed: () => setState(() => obscure = !obscure),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.isEmpty) {
                setState(() => errorMessage = 'Password cannot be empty');
                return;
              }
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null || user.email == null) {
                  Navigator.pop(ctx, false);
                  return;
                }
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: password,
                );
                await user.reauthenticateWithCredential(credential);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } on FirebaseAuthException catch (e) {
                setState(() {
                  errorMessage = e.code == 'wrong-password' || e.code == 'invalid-credential'
                      ? 'Incorrect password. Please try again.'
                      : e.message ?? 'Authentication failed.';
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  passwordController.dispose();
  return result ?? false;
}
