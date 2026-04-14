import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/theme_controller.dart';

class CameraPermissionDialog extends StatefulWidget {
  final VoidCallback onAllow;
  final VoidCallback onDemoMode;
  final VoidCallback onCancel;

  const CameraPermissionDialog({
    super.key,
    required this.onAllow,
    required this.onDemoMode,
    required this.onCancel,
  });

  @override
  State<CameraPermissionDialog> createState() => _CameraPermissionDialogState();
}

class _CameraPermissionDialogState extends State<CameraPermissionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = themeController.isDarkMode;

      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            color: (isDarkMode ? const Color(0xFF0A1929) : Colors.black)
                .withValues(alpha: 0.5 * _opacityAnimation.value),
            child: BackdropFilter(
              filter: const ColorFilter.mode(
                Colors.transparent,
                BlendMode.srcOver,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: _buildDialog(isDarkMode),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildDialog(bool isDarkMode) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF132F4C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF5B9FF3), Color(0xFF7DB6F7)],
                    ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Camera & Microphone Access',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Choose how you'd like to join this video session",
                  style: TextStyle(fontSize: 13, color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                _buildFeatureCard(
                  icon: Icons.videocam,
                  title: 'Camera',
                  subtitle: 'For video communication with the expert',
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 8),
                _buildFeatureCard(
                  icon: Icons.mic,
                  title: 'Microphone',
                  subtitle: 'To speak and ask questions during the session',
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  '💡 No camera? Use Demo Mode to explore the interface',
                  isDarkMode ? const Color(0xFF06B6D4) : const Color(0xFF0E7490),
                  isDarkMode ? const Color(0xFF06B6D4) : const Color(0xFFCFFAFE),
                  isDarkMode,
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  '🔒 We never record or store your video without permission.',
                  isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                  isDarkMode ? const Color(0xFFF59E0B) : const Color(0xFFFEF3C7),
                  isDarkMode,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onAllow,
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: isDarkMode
                            ? const LinearGradient(colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)])
                            : const LinearGradient(colors: [Color(0xFF5B9FF3), Color(0xFF7DB6F7)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        alignment: Alignment.center,
                        child: const Text('Allow Access & Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: widget.onDemoMode,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: BorderSide(color: isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFD1D5DB), width: 2),
                      backgroundColor: isDarkMode ? const Color(0xFF0A1929) : const Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Continue in Demo Mode',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF374151)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: widget.onCancel,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4)),
                  child: Text('Cancel', style: TextStyle(fontSize: 13, color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String subtitle, required bool isDarkMode}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0EA5E9).withValues(alpha: 0.1) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? const Color(0xFF0EA5E9).withValues(alpha: 0.2) : const Color(0xFFDEEAFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF5B9FF3)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : const Color(0xFF1F2937))),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text, Color textColor, Color bgColor, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? bgColor.withValues(alpha: 0.1) : bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? bgColor.withValues(alpha: 0.3) : bgColor.withValues(alpha: 1.0)),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: textColor), textAlign: TextAlign.center),
    );
  }
}

Future<void> showCameraPermissionDialog({
  required BuildContext context,
  required VoidCallback onAllow,
  required VoidCallback onDemoMode,
  required VoidCallback onCancel,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => CameraPermissionDialog(
      onAllow: () {
        Navigator.of(context).pop();
        onAllow();
      },
      onDemoMode: () {
        Navigator.of(context).pop();
        onDemoMode();
      },
      onCancel: () {
        Navigator.of(context).pop();
        onCancel();
      },
    ),
  );
}
