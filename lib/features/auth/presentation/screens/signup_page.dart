import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final authController = Get.find<AuthController>();
  final themeController = Get.find<ThemeController>();

  int _passwordStrength = 0; // 0=empty, 1=weak, 2=fair, 3=strong, 4=very strong

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _passwordStrength = _getPasswordStrength(_passwordController.text));
    });
  }

  int _getPasswordStrength(String p) {
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('passwords_mismatch'.tr)),
      );
      return;
    }

    final success = await authController.signUp(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('signup_success'.tr)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.lastErrorMessage ?? 'registration_failed'.tr),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = themeController.isDarkMode;
      final isLoading = authController.isLoading;

      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1929), Color(0xFF0A1929)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  ),
          ),
          child: Column(
            children: [
              // Top Gradient Header
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: AppColors.gradientAppBar,
                  ),
                ),
                padding: const EdgeInsets.only(top: 52, bottom: 80, left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'INTELLIX',
                      style: GoogleFonts.inter(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.bgDark : AppColors.surfaceLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -32, 0),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: AppColors.gradientAccent,
                          ).createShader(bounds),
                          child: Text(
                            'create_account'.tr,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'join_get_started'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign Up Form
                        Column(
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              hintText: 'full_name'.tr,
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: _emailController,
                              hintText: 'email'.tr,
                              keyboardType: TextInputType.emailAddress,
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: _usernameController,
                              hintText: 'username'.tr,
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: _passwordController,
                              hintText: 'password'.tr,
                              isPassword: true,
                              isDarkMode: isDarkMode,
                            ),
                            // Password strength meter
                            if (_passwordStrength > 0) ...[  
                              const SizedBox(height: 8),
                              _buildPasswordStrengthMeter(isDarkMode),
                            ],
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              hintText: 'confirm_password'.tr,
                              isPassword: true,
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 16),

                            // Create Account Button
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                boxShadow: AppColors.glowShadow(intensity: 0.3),
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleSignUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: const StadiumBorder(),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'create_account'.tr,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: isDarkMode ? AppColors.borderDark : AppColors.borderLight,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'or_continue_with'.tr,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDarkMode ? AppColors.textHintDark : AppColors.textHintLight,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: isDarkMode ? AppColors.borderDark : AppColors.borderLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ─── Google Sign Up ────────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: isLoading ? null : () async {
                                  final success = await authController.signInWithGoogle();
                                  if (success && context.mounted) {
                                    context.go('/home');
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDarkMode ? AppColors.borderDark : AppColors.borderLight,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Custom Google "G" icon
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'G',
                                        style: GoogleFonts.poppins(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Google',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${'have_account'.tr} ',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.pop(),
                                  child: Text(
                                    'sign_in'.tr,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildPasswordStrengthMeter(bool isDark) {
    final labels = ['', 'Weak', 'Fair', 'Strong', 'Very Strong'];
    final colors = [
      Colors.transparent,
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.yellow.shade700,
      Colors.green.shade500,
    ];
    final label = labels[_passwordStrength];
    final color = colors[_passwordStrength];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final active = i < _passwordStrength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: active ? color : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            label,
            key: ValueKey(label),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool isDarkMode,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: isDarkMode ? AppColors.textHintDark : AppColors.textHintLight,
        ),
        filled: true,
        fillColor: isDarkMode ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(color: isDarkMode ? AppColors.borderDark : AppColors.borderLight, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(color: isDarkMode ? AppColors.borderDark : AppColors.borderLight, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
