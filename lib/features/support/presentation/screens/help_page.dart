import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FAQ Data Model
// ─────────────────────────────────────────────────────────────────────────────
class FAQCategory {
  final String category;
  final List<FAQItem> questions;
  FAQCategory({required this.category, required this.questions});
}

class FAQItem {
  final String question;
  final String answer;
  FAQItem({required this.question, required this.answer});
}

// ─────────────────────────────────────────────────────────────────────────────
// FAQ Data  (Features + Getting Started removed; password reset → Account & Privacy)
// ─────────────────────────────────────────────────────────────────────────────
final List<FAQCategory> faqData = [
  FAQCategory(
    category: 'AI Assistant',
    questions: [
      FAQItem(
        question: 'How do I use the AI Assistant?',
        answer:
            'Navigate to the AI Chat tab and type your question. The AI will provide intelligent responses based on your business data.',
      ),
      FAQItem(
        question: 'What can I ask the AI?',
        answer:
            'You can ask about business metrics, trends, forecasts, data analysis, and get recommendations for improving your business.',
      ),
      FAQItem(
        question: 'Is my data secure with AI?',
        answer:
            'Yes, all conversations are encrypted and your data is processed securely. We never share your information with third parties.',
      ),
    ],
  ),
  FAQCategory(
    category: 'Account & Privacy',
    questions: [
      FAQItem(
        question: 'How do I reset my password?',
        answer:
            'Tap "Forgot Password" on the login screen. Enter your email address and follow the instructions sent to your inbox to create a new password.',
      ),
      FAQItem(
        question: 'How do I delete my account?',
        answer:
            'Go to Settings › Danger Zone › Delete Account. Note that this action is permanent and cannot be undone.',
      ),
      FAQItem(
        question: 'How is my data protected?',
        answer:
            'We use industry-standard encryption and security measures to protect your data. Read our Privacy Policy for more details.',
      ),
      FAQItem(
        question: 'Can I change my email address?',
        answer:
            'Yes, go to Settings › Account › Change Email and follow the verification process.',
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Quick Access Topics  (Live Chat + Release Notes removed; only User Guide & Videos)
// ─────────────────────────────────────────────────────────────────────────────
class QuickHelpTopic {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route; // internal route identifier

  QuickHelpTopic({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

final List<QuickHelpTopic> quickHelpTopics = [
  QuickHelpTopic(
    icon: Icons.menu_book_rounded,
    title: 'User Guide',
    subtitle: 'Complete documentation',
    route: 'user_guide',
  ),
  QuickHelpTopic(
    icon: Icons.play_circle_rounded,
    title: 'Video Tutorials',
    subtitle: 'Step-by-step guides',
    route: 'video_tutorials',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder video tutorial model (admin can add more)
// ─────────────────────────────────────────────────────────────────────────────
class VideoTutorial {
  final String title;
  final String duration;
  final IconData icon;

  const VideoTutorial({
    required this.title,
    required this.duration,
    required this.icon,
  });
}

// Admin-editable list — add new VideoTutorial entries here
final List<VideoTutorial> videoTutorials = [
  const VideoTutorial(
    title: 'Getting Started with Intellix',
    duration: '3:24',
    icon: Icons.rocket_launch_rounded,
  ),
  const VideoTutorial(
    title: 'Using the AI Business Advisor',
    duration: '5:10',
    icon: Icons.auto_awesome_rounded,
  ),
  const VideoTutorial(
    title: 'Booking an Expert Session',
    duration: '4:02',
    icon: Icons.calendar_today_rounded,
  ),
  const VideoTutorial(
    title: 'Exploring Trends & Insights',
    duration: '6:45',
    icon: Icons.trending_up_rounded,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// HelpPage
// ─────────────────────────────────────────────────────────────────────────────
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String? _expandedQuestion;
  bool _showUserGuide       = false;
  bool _showVideoTutorials  = false;

  final themeController = Get.find<ThemeController>();

  // ── Email launcher ──────────────────────────────────────────────────────────
  static const _supportEmail = 'noorfayyad25122@gmail.com';

  Future<void> _openEmailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'Intellix Support Request',
        'body':
            'Hi Intellix Support,\n\nI need help with:\n\n',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open email app. Please email us at $_supportEmail',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        );
      }
    }
  }

  // ── Quick access tap handler ────────────────────────────────────────────────
  void _handleQuickAccess(String route) {
    setState(() {
      if (route == 'user_guide') {
        _showUserGuide      = !_showUserGuide;
        _showVideoTutorials = false;
      } else if (route == 'video_tutorials') {
        _showVideoTutorials = !_showVideoTutorials;
        _showUserGuide      = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark    = themeController.isDarkMode;
      final iconColor = isDark ? AppColors.accent : AppColors.primary;

      return Scaffold(
        backgroundColor:
            isDark ? AppColors.bgDark : AppColors.bgLight,
        body: Stack(
          children: [
            Column(
              children: [
                // ── AppBar ────────────────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.gradientAppBar),
                    borderRadius: BorderRadius.only(
                      bottomLeft:  Radius.circular(36),
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
                  padding: const EdgeInsets.only(
                    top: 40, bottom: 88, left: 4, right: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'help_center_title'.tr,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 5,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // ── Scrollable content ────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: 72, left: 20, right: 20, bottom: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── QUICK ACCESS ────────────────────────────────────
                        _buildSectionHeader('QUICK ACCESS', isDark),
                        const SizedBox(height: 12),
                        Row(
                          children: quickHelpTopics.map((topic) {
                            final isActive =
                                (topic.route == 'user_guide' && _showUserGuide) ||
                                (topic.route == 'video_tutorials' && _showVideoTutorials);
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: topic == quickHelpTopics.last ? 0 : 10,
                                ),
                                child: _buildQuickHelpCard(
                                  topic:    topic,
                                  iconColor: iconColor,
                                  isDark:    isDark,
                                  isActive:  isActive,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // ── User Guide inline panel ─────────────────────────
                        if (_showUserGuide) ...[
                          const SizedBox(height: 12),
                          _buildUserGuidePanel(isDark),
                        ],

                        // ── Video Tutorials inline panel ────────────────────
                        if (_showVideoTutorials) ...[
                          const SizedBox(height: 12),
                          _buildVideoTutorialsPanel(isDark, iconColor),
                        ],

                        const SizedBox(height: 28),

                        // ── FAQ ─────────────────────────────────────────────
                        _buildSectionHeader('faq_title'.tr, isDark),
                        const SizedBox(height: 12),

                        ...faqData.map((category) {
                          if (category.questions.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  category.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.card),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                  ),
                                  boxShadow: isDark
                                      ? []
                                      : AppColors.cardShadow(),
                                ),
                                child: Column(
                                  children: category.questions
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final idx  = entry.key;
                                    final item = entry.value;
                                    final qId  = '${category.category}-$idx';
                                    final isExp = _expandedQuestion == qId;
                                    final isLast = idx == category.questions.length - 1;

                                    return _buildFAQItem(
                                      question:   item.question,
                                      answer:     item.answer,
                                      isExpanded: isExp,
                                      onTap: () => setState(() {
                                        _expandedQuestion = isExp ? null : qId;
                                      }),
                                      showBorder: !isLast,
                                      isDark:     isDark,
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }),

                        const SizedBox(height: 8),

                        // ── CONTACT SUPPORT (email only) ────────────────────
                        _buildSectionHeader('CONTACT SUPPORT', isDark),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                            boxShadow: isDark ? [] : AppColors.cardShadow(),
                          ),
                          child: _buildEmailContactItem(
                            isDark:    isDark,
                            iconColor: iconColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Still need help card ────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end:   Alignment.centerRight,
                              colors: AppColors.gradientAppBar,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            boxShadow: AppColors.glowShadow(),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.support_agent_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'still_need_help'.tr,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Our support team is ready to assist you with any questions or issues.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _openEmailSupport,
                                icon: const Icon(Icons.email_rounded, size: 16),
                                label: Text(
                                  'email_support'.tr,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryDark,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 12,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── App info footer ─────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Intellix v1.0.0',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textHintDark
                                      : AppColors.textHintLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last updated: December 2025',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textHintDark
                                      : AppColors.textHintLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Help icon overlay ───────────────────────────────────────────
            Positioned(
              top: 116,
              left: MediaQuery.of(context).size.width / 2 - 52,
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 52,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Section header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  // ── Quick access card ───────────────────────────────────────────────────────
  Widget _buildQuickHelpCard({
    required QuickHelpTopic topic,
    required Color iconColor,
    required bool isDark,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => _handleQuickAccess(topic.route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.10)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? AppColors.glowShadow(intensity: 0.12)
              : (isDark ? [] : AppColors.cardShadow()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : (isDark
                        ? AppColors.surfaceDim
                        : const Color(0xFFF0F9FF)),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(topic.icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              topic.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              topic.subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── User Guide panel ────────────────────────────────────────────────────────
  Widget _buildUserGuidePanel(bool isDark) {
    final sections = [
      ('🚀', 'getting_started'.tr, 'Create your account, set up your profile, and explore the dashboard.'),
      ('🤖', 'AI Assistant', 'Learn how to ask business questions and interpret AI responses.'),
      ('📅', 'Expert Sessions', 'Book, manage, and review your expert consultation sessions.'),
      ('📊', 'Explore & Trends', 'Navigate topics, articles, and business insight categories.'),
      ('🔒', 'Account & Security', 'Manage your profile, privacy settings, and subscription.'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark ? [] : AppColors.cardShadow(),
      ),
      child: Column(
        children: sections.asMap().entries.map((e) {
          final isLast = e.key == sections.length - 1;
          final section = e.value;
          return Container(
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(section.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.$2,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        section.$3,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.textHintDark
                      : AppColors.textHintLight,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Video Tutorials panel ───────────────────────────────────────────────────
  Widget _buildVideoTutorialsPanel(bool isDark, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark ? [] : AppColors.cardShadow(),
      ),
      child: Column(
        children: videoTutorials.asMap().entries.map((e) {
          final isLast = e.key == videoTutorials.length - 1;
          final video  = e.value;
          return Container(
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: AppColors.gradientPrimary),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppColors.glowShadow(intensity: 0.18),
                  ),
                  child: Icon(video.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            video.duration,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── FAQ item ────────────────────────────────────────────────────────────────
  Widget _buildFAQItem({
    required String question,
    required String answer,
    required bool isExpanded,
    required VoidCallback onTap,
    required bool showBorder,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              )
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.6,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Email contact item (only contact option) ────────────────────────────────
  Widget _buildEmailContactItem({
    required bool isDark,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: _openEmailSupport,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.email_rounded, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'email_support'.tr,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _supportEmail,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: AppColors.gradientPrimary),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                'Send',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
