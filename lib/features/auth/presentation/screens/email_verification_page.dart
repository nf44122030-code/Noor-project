import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/theme_controller.dart';
import '../providers/auth_controller.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage>
    with TickerProviderStateMixin {
  final authController  = Get.find<AuthController>();
  final themeController = Get.find<ThemeController>();

  // Resend cooldown (60 s)
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  // Auto-check every 4 s
  Timer? _autoCheckTimer;

  bool _isChecking  = false;
  bool _isResending = false;

  late final AnimationController _pulseController;
  late final AnimationController _bounceController;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnim  = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _bounceAnim = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Auto-poll Firebase every 4 s
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final verified = await authController.checkEmailVerification();
      if (verified && mounted) {
        _autoCheckTimer?.cancel();
        // Router will handle navigation automatically via routerRefreshListenable
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _autoCheckTimer?.cancel();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  // ── Resend ──────────────────────────────────────────────────────────────────
  Future<void> _handleResend() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() => _isResending = true);
    final ok = await authController.resendVerificationEmail();
    setState(() => _isResending = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('verification_sent'.tr),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      setState(() => _resendCooldown = 60);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_resendCooldown <= 0) {
          t.cancel();
        } else {
          setState(() => _resendCooldown--);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.lastErrorMessage ?? 'failed_resend_email'.tr),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Manual check ────────────────────────────────────────────────────────────
  Future<void> _handleCheckVerification() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    final verified = await authController.checkEmailVerification();
    setState(() => _isChecking = false);

    if (!mounted) return;
    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('email_not_verified'.tr),
          backgroundColor: const Color(0xFFB45309),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    // If verified, the router redirect fires automatically
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode;
      final email  = authController.userEmail;

      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1929), Color(0xFF0A1929)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  ),
          ),
          child: Column(
            children: [
              // ── Gradient header ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                    colors: isDark
                        ? const [Color(0xFF0369A1), Color(0xFF0EA5E9)]
                        : const [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                  ),
                ),
                padding: const EdgeInsets.only(top: 40, bottom: 80, left: 24, right: 24),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'INTELLIX',
                      style: TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold,
                        color: Colors.white, letterSpacing: 14.4,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ──────────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0A1929) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40), topRight: Radius.circular(40),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -40, 0),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                    child: Column(
                      children: [
                        // ── Animated envelope ───────────────────────────────
                        AnimatedBuilder(
                          animation: Listenable.merge([_pulseController, _bounceController]),
                          builder: (_, __) => Transform.translate(
                            offset: Offset(0, _bounceAnim.value),
                            child: Transform.scale(
                              scale: _pulseAnim.value,
                              child: Container(
                                width: 120, height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? const [Color(0xFF0369A1), Color(0xFF0EA5E9)]
                                        : const [Color(0xFF0284C7), Color(0xFF06B6D4)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                                      blurRadius: 30, spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.mark_email_unread_rounded,
                                    size: 60, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Title ────────────────────────────────────────────
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF0EA5E9), Color(0xFF06B6D4)]
                                : const [Color(0xFF0369A1), Color(0xFF0EA5E9)],
                          ).createShader(bounds),
                          child: Text(
                            'verify_email'.tr,
                            style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Subtitle ─────────────────────────────────────────
                        Text(
                          'We\'ve sent a verification link to:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ── Email badge ──────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF0369A1).withValues(alpha: 0.3), const Color(0xFF0EA5E9).withValues(alpha: 0.3)]
                                  : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.email_rounded,
                                  size: 18,
                                  color: isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Info card ────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF132F4C)
                                : const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildStep(isDark, '1', 'Check your email inbox (and spam folder)'),
                              const SizedBox(height: 10),
                              _buildStep(isDark, '2', 'Click the verification link in the email'),
                              const SizedBox(height: 10),
                              _buildStep(isDark, '3', 'Return here and tap "I\'ve Verified"'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Check Verification button ────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isChecking ? null : _handleCheckVerification,
                            icon: _isChecking
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.verified_user_rounded, color: Colors.white),
                            label: Text(
                              _isChecking ? 'Checking...' : 'I\'ve Verified My Email',
                              style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ).copyWith(
                              backgroundColor: WidgetStateProperty.resolveWith((_) => Colors.transparent),
                            ),
                          ).buildFallback(isDark),
                        ),
                        const SizedBox(height: 14),

                        // ── Resend button ─────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: (_resendCooldown > 0 || _isResending) ? null : _handleResend,
                            icon: _isResending
                                ? SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7),
                                    ),
                                  )
                                : Icon(Icons.send_rounded,
                                    color: _resendCooldown > 0
                                        ? (isDark ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF))
                                        : (isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7))),
                            label: Text(
                              _isResending
                                  ? 'Sending...'
                                  : _resendCooldown > 0
                                      ? 'Resend in ${_resendCooldown}s'
                                      : 'resend_email'.tr,
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600,
                                color: _resendCooldown > 0
                                    ? (isDark ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF))
                                    : (isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7)),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _resendCooldown > 0
                                    ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD1D5DB))
                                    : (isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7)),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Sign out ──────────────────────────────────────────
                        TextButton.icon(
                          onPressed: () => authController.logout(),
                          icon: Icon(Icons.logout, size: 18,
                              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                          label: Text(
                            'Sign in with a different account',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStep(bool isDark, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF0369A1), Color(0xFF0EA5E9)]
                  : const [Color(0xFF0284C7), Color(0xFF06B6D4)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}

// Helper extension to wrap the button in a gradient container
extension on ElevatedButton {
  Widget buildFallback(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0369A1), Color(0xFF0EA5E9)]
              : const [Color(0xFF0284C7), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: this,
    );
  }
}
