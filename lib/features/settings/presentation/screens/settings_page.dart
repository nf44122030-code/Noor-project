import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_controller.dart';

import '../../../../core/widgets/reauth_dialog.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final themeController    = Get.find<ThemeController>();
  final settingsController = Get.find<SettingsController>();
  final firebaseService    = FirebaseService();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = themeController.isDarkMode;
      final iconColor = isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7);
      final cardBg = isDarkMode ? const Color(0xFF132F4C) : Colors.white;
      final cardBorder = isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD);
      final borderColor = isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFE0F2FE);

      return Scaffold(
        backgroundColor: isDarkMode
            ? const Color(0xFF0A1929)
            : const Color(0xFFF0F9FF),
        body: Stack(
          children: [
            Column(
              children: [
                // ===== CURVED APP BAR =====
                Container(
                  decoration: BoxDecoration(
                    gradient: isDarkMode
                        ? const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
                          )
                        : const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF0284C7),
                              Color(0xFF0EA5E9),
                              Color(0xFF06B6D4),
                            ],
                          ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(
                    top: 40,
                    bottom: 96,
                    left: 24,
                    right: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Text(
                        'SETTINGS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4.8,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // ===== SCROLLABLE CONTENT =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: 80,
                      left: 24,
                      right: 24,
                      bottom: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===== ACCOUNT SECTION =====
                        _buildSectionHeader('ACCOUNT', isDarkMode),
                        const SizedBox(height: 12),
                        _buildCard(
                          isDarkMode: isDarkMode,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          borderColor: borderColor,
                          children: [
                            _buildSettingsItem(
                              icon: Icons.person,
                              label: 'Edit Profile',
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: true,
                              borderColor: borderColor,
                              onTap: () {},
                            ),
                            _buildSettingsItem(
                              icon: Icons.email,
                              label: 'Change Email',
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: true,
                              borderColor: borderColor,
                              onTap: () async {
                                final ok = await showReauthDialog(context, isDark: isDarkMode);
                                if (ok && context.mounted) {
                                  // Navigate to change email screen
                                }
                              },
                            ),
                            _buildSettingsItem(
                              icon: Icons.lock,
                              label: 'Change Password',
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: false,
                              borderColor: borderColor,
                              onTap: () async {
                                final ok = await showReauthDialog(context, isDark: isDarkMode);
                                if (ok && context.mounted) {
                                  // Navigate to change password screen
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ===== ACCESS MANAGEMENT =====
                        _buildSectionHeader('ACCESS MANAGEMENT', isDarkMode),
                        const SizedBox(height: 12),
                        _buildCard(
                          isDarkMode: isDarkMode,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          borderColor: borderColor,
                          children: [
                            _buildSettingsItem(
                              icon: Icons.manage_accounts_rounded,
                              label: 'Assistants & Admins',
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: false,
                              borderColor: borderColor,
                              onTap: () => _showAssistantsDialog(context, isDarkMode),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ===== NOTIFICATIONS SECTION =====
                        _buildSectionHeader('NOTIFICATIONS', isDarkMode),
                        const SizedBox(height: 12),
                        _buildCard(
                          isDarkMode: isDarkMode,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          borderColor: borderColor,
                          children: [
                            _buildToggleItem(
                              icon: Icons.notifications,
                              label: 'All Notifications',
                              value: settingsController.notificationsEnabled.value,
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: true,
                              borderColor: borderColor,
                              onChanged: settingsController.setNotificationsEnabled,
                            ),
                            _buildToggleItem(
                              icon: Icons.email,
                              label: 'Email Notifications',
                              value: settingsController.emailNotifications.value,
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: true,
                              borderColor: borderColor,
                              onChanged: settingsController.setEmailNotifications,
                            ),
                            _buildToggleItem(
                              icon: Icons.phone_android,
                              label: 'Push Notifications',
                              value: settingsController.pushNotifications.value,
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: false,
                              borderColor: borderColor,
                              onChanged: settingsController.setPushNotifications,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ===== APPEARANCE SECTION =====
                        _buildSectionHeader('APPEARANCE', isDarkMode),
                        const SizedBox(height: 12),
                        _buildCard(
                          isDarkMode: isDarkMode,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          borderColor: borderColor,
                          children: [
                            _buildToggleItem(
                              icon: isDarkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                              label: 'Dark Mode',
                              value: isDarkMode,
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: true,
                              borderColor: borderColor,
                              onChanged: (value) {
                                themeController.toggleTheme();
                              },
                            ),
                            _buildSelectItem(
                              icon: Icons.language,
                              label: 'language'.tr,
                              value: settingsController.currentLanguage.value == 'ar'
                                  ? 'arabic'.tr
                                  : settingsController.currentLanguage.value == 'ckb'
                                      ? 'kurdish'.tr
                                      : 'english'.tr,
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: false,
                              borderColor: borderColor,
                              onTap: () {
                                _showLanguagePicker(context, isDarkMode);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ===== PREFERENCES SECTION =====
                        _buildSectionHeader('PREFERENCES', isDarkMode),
                        const SizedBox(height: 12),
                        _buildCard(
                          isDarkMode: isDarkMode,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          borderColor: borderColor,
                          children: [
                            _buildToggleItem(
                              icon: Icons.download,
                              label: 'Auto-Save Data',
                              value: settingsController.autoSave.value,
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: false,
                              borderColor: borderColor,
                              onChanged: settingsController.setAutoSave,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ===== PRIVACY SECTION =====
                        _buildSectionHeader('PRIVACY', isDarkMode),
                        const SizedBox(height: 12),
                        _buildCard(
                          isDarkMode: isDarkMode,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          borderColor: borderColor,
                          children: [
                            _buildSettingsItem(
                              icon: Icons.shield,
                              label: 'Privacy Policy',
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: true,
                              borderColor: borderColor,
                              onTap: () {},
                            ),
                            _buildSettingsItem(
                              icon: Icons.description,
                              label: 'Terms & Conditions',
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: false,
                              borderColor: borderColor,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ===== SUPPORT SECTION =====
                        _buildSectionHeader('SUPPORT', isDarkMode),
                        const SizedBox(height: 12),
                        _buildCard(
                          isDarkMode: isDarkMode,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          borderColor: borderColor,
                          children: [
                            _buildSettingsItem(
                              icon: Icons.help_outline,
                              label: 'Help Center',
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: true,
                              borderColor: borderColor,
                              onTap: () {},
                            ),
                            _buildSettingsItem(
                              icon: Icons.email,
                              label: 'Contact Support',
                              iconColor: iconColor,
                              isDarkMode: isDarkMode,
                              showBorder: false,
                              borderColor: borderColor,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ===== DANGER ZONE =====
                        _buildSectionHeader('DANGER ZONE', isDarkMode),
                        const SizedBox(height: 12),
                        _buildCard(
                          isDarkMode: isDarkMode,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          borderColor: borderColor,
                          children: [
                            InkWell(
                              onTap: () {
                                _showDeleteAccountDialog(context, isDarkMode);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Delete Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.red[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ===== APP VERSION FOOTER =====
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Intellix v1.0.0',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '© 2025 All rights reserved',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ===== ICON OVERLAY =====
            Positioned(
              top: 120,
              left: MediaQuery.of(context).size.width / 2 - 64,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.settings,
                  size: 64,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard({
    required bool isDarkMode,
    required Color cardBg,
    required Color cardBorder,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required bool isDarkMode,
    required bool showBorder,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(bottom: BorderSide(color: borderColor))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDarkMode
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String label,
    required bool value,
    required Color iconColor,
    required bool isDarkMode,
    required bool showBorder,
    required Color borderColor,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(bottom: BorderSide(color: borderColor))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF374151),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: value
                    ? (isDarkMode
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFF0284C7))
                    : (isDarkMode
                        ? const Color(0xFF1E4976)
                        : const Color(0xFFBAE6FD)),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required bool isDarkMode,
    required bool showBorder,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(bottom: BorderSide(color: borderColor))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDarkMode
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF132F4C) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Account?',
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This action is permanent and cannot be undone. All your data will be permanently deleted.',
          style: TextStyle(
            color: isDarkMode
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authController = Get.find<AuthController>();
              await authController.deleteAccount();
              await authController.logout();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  void _showAssistantsDialog(BuildContext context, bool isDarkMode) {
    final emailController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF132F4C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.manage_accounts, color: isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7)),
                const SizedBox(width: 12),
                Text(
                  'Assistants & Admins',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Invite an assistant to manage your account. They will be able to inheritedly view your chats, bookings, and explore data.',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: emailController,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'assistant@example.com',
                      hintStyle: TextStyle(color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.trim().isNotEmpty) {
                      try {
                        await firebaseService.addAssistant(emailController.text.trim());
                        emailController.clear();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding assistant: $e')));
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    backgroundColor: const Color(0xFF0EA5E9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Invite', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: firebaseService.getAssistantsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final assistants = snapshot.data ?? [];
                  if (assistants.isEmpty) {
                    return Center(
                      child: Text(
                        'No assistants invited yet.',
                        style: TextStyle(color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: assistants.length,
                    itemBuilder: (context, index) {
                      final assistant = assistants[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF0EA5E9),
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            assistant['email'],
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text('Delegated Access', style: TextStyle(color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF), fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => firebaseService.removeAssistant(assistant['email']),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF132F4C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'language_selection'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Obx(() => _buildLanguageOption(context, 'English', 'en', isDarkMode)),
            Obx(() => _buildLanguageOption(context, 'العربية (Arabic)', 'ar', isDarkMode)),
            Obx(() => _buildLanguageOption(context, 'کوردی (Kurdish)', 'ckb', isDarkMode)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String label, String langCode, bool isDarkMode) {
    final bool isSelected = settingsController.currentLanguage.value == langCode;
    return InkWell(
      onTap: () {
        settingsController.changeLanguage(langCode);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFE0F2FE))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7)),
          ],
        ),
      ),
    );
  }
}
