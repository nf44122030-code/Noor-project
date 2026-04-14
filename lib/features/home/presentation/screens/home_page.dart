import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';
import '../../../../features/ai/presentation/screens/ai_assistant_page.dart';
import '../../../../features/notification/presentation/screens/notification_page.dart';
import '../../../../features/explore/presentation/screens/explore_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String _currentPage = 'home';
  String? _initialAIMessage;
  final TextEditingController _chatController = TextEditingController();
  bool _hasText = false;
  late AnimationController _navAnimController;

  final authController = Get.find<AuthController>();
  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _chatController.addListener(() {
      final has = _chatController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _navAnimController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _initialAIMessage = null;
      _selectedIndex = index;
      switch (index) {
        case 0:
          _currentPage = 'home';
          break;
        case 1:
          _currentPage = 'explore';
          break;
        case 2:
          _showQuickActionsDialog();
          break;
        case 3:
          _currentPage = 'ai';
          break;
        case 4:
          context.push('/pricing');
          break;
      }
    });
  }

  void _showQuickActionsDialog() {
    final isDark = themeController.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickAction(
              icon: Icons.video_call_rounded,
              title: 'Book Expert Session',
              subtitle: 'Schedule a video call with an expert',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push('/expert-session');
              },
            ),
            _buildQuickAction(
              icon: Icons.auto_awesome_rounded,
              title: 'Session AI Notes',
              subtitle: 'View your AI-generated session notes',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push('/notes-history');
              },
            ),
            _buildQuickAction(
              icon: Icons.videocam_rounded,
              title: 'Start Video Session',
              subtitle: 'Join a live consultation now',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push('/video-session');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        tileColor: isDark ? AppColors.surfaceDim : const Color(0xFFF8FAFC),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.gradientPrimary),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode;

      Widget currentWidget;
      switch (_currentPage) {
        case 'ai':
          currentWidget = AIAssistantPage(
            initialMessage: _initialAIMessage,
          );
          break;
        case 'explore':
          currentWidget = const ExplorePage();
          break;
        case 'notifications':
          currentWidget = NotificationPage(
            onBack: () => setState(() => _currentPage = 'home'),
          );
          break;
        default:
          currentWidget = _buildHomeContent(isDark);
      }

      return Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(isDark),
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: Stack(
          children: [
            Column(
              children: [
                if (_currentPage != 'notifications' && _currentPage != 'ai')
                  _buildAppBar(isDark),
                Expanded(child: currentWidget),
              ],
            ),
            if (_currentPage == 'home')
              _buildFloatingChatInput(isDark, key: const ValueKey('home_chat_input')),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(isDark),
      );
    });
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: AppColors.gradientAppBar,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x220EA5E9),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 52, bottom: 18, left: 12, right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Text(
            _currentPage == 'explore' ? 'EXPLORE' : 'INTELLIX',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 5,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
            onPressed: () => setState(() => _currentPage = 'notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(bool isDark) {
    final userName = authController.userName;
    return Stack(
      children: [
        // Background gradient orbs for depth
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: isDark ? 0.06 : 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: isDark ? 0.04 : 0.06),
            ),
          ),
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                ).createShader(bounds),
                child: Text(
                  'Welcome back,',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: GoogleFonts.inter(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your intelligent business advisor is ready.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 36),

              // Quick stats row
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.smart_toy_rounded,
                    label: 'AI Sessions',
                    value: 'Mercury-2',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.explore_rounded,
                    label: 'Status',
                    value: 'Online',
                    isDark: isDark,
                    valueColor: AppColors.accent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingChatInput(bool isDark, {Key? key}) {
    return Positioned(
      key: key,
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: _hasText ? 0.18 : 0.06),
                  blurRadius: _hasText ? 20 : 8,
                  spreadRadius: _hasText ? 1 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask about your business...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        final text = value.trim();
                        _chatController.clear();
                        setState(() {
                          _selectedIndex = 3;
                          _currentPage = 'ai';
                          _initialAIMessage = text;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    width: _hasText ? 44 : 40,
                    height: _hasText ? 44 : 40,
                    decoration: BoxDecoration(
                      gradient: _hasText
                          ? const LinearGradient(colors: AppColors.gradientPrimary)
                          : null,
                      color: _hasText
                          ? null
                          : (isDark ? AppColors.surfaceDim : const Color(0xFFEFF6FF)),
                      shape: BoxShape.circle,
                      boxShadow: _hasText
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: _hasText
                            ? Colors.white
                            : (isDark ? AppColors.textHintDark : AppColors.textHintLight),
                      ),
                      onPressed: _hasText
                          ? () {
                              final text = _chatController.text.trim();
                              if (text.isNotEmpty) {
                                _chatController.clear();
                                setState(() {
                                  _selectedIndex = 3;
                                  _currentPage = 'ai';
                                  _initialAIMessage = text;
                                });
                              }
                            }
                          : null,
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


  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: isDark ? [] : AppColors.cardShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool isDark) {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0, isDark: isDark),
                _buildNavItem(icon: Icons.explore_rounded, label: 'Explore', index: 1, isDark: isDark),
                // Center + button
                GestureDetector(
                  onTap: () => _onItemTapped(2),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: AppColors.gradientPrimary),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x440EA5E9),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                  ),
                ),
                _buildNavItem(icon: Icons.smart_toy_rounded, label: 'AI Chat', index: 3, isDark: isDark),
                _buildNavItem(icon: Icons.workspace_premium_rounded, label: 'Pricing', index: 4, isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.primary : (isDark ? AppColors.textDimDark : AppColors.textHintLight),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : (isDark ? AppColors.textDimDark : AppColors.textHintLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
      child: Column(
        children: [
          Obx(() {
            final userName  = authController.userName;
            final userEmail = authController.userEmail;
            final photoUrl  = authController.profileImage;
            return Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.gradientPrimary),
              ),
              padding: const EdgeInsets.only(top: 64, bottom: 32, left: 24, right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2.5),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white24,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? const Icon(Icons.person_rounded, size: 38, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    userName,
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            );
          }),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                // Theme toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          isDark ? 'Dark Mode' : 'Light Mode',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: !isDark,
                          onChanged: (_) => themeController.toggleTheme(),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(icon: Icons.person_rounded, title: 'Profile', isDark: isDark, onTap: () => context.push('/profile')),
                _buildDrawerItem(icon: Icons.settings_rounded, title: 'Settings', isDark: isDark, onTap: () => context.push('/settings')),
                _buildDrawerItem(icon: Icons.help_outline_rounded, title: 'Help & Support', isDark: isDark, onTap: () => context.push('/help')),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  isDark: isDark,
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    authController.logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        leading: Icon(icon, color: itemColor, size: 22),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}
