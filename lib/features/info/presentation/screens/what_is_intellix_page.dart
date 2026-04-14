import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/theme_controller.dart';

class WhatIsIntellixPage extends StatefulWidget {
  const WhatIsIntellixPage({super.key});

  @override
  State<WhatIsIntellixPage> createState() => _WhatIsIntellixPageState();
}

class _WhatIsIntellixPageState extends State<WhatIsIntellixPage>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController1;
  late AnimationController _backgroundController2;
  late AnimationController _backgroundController3;
  late AnimationController _glowController;

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _backgroundController1 = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundController2 = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundController3 = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController1.dispose();
    _backgroundController2.dispose();
    _backgroundController3.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = themeController.isDarkMode;

      return Scaffold(
        body: Container(
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
          child: Stack(
            children: [
              // Animated Background Gradients
              _buildAnimatedBackgrounds(isDarkMode),

              // Main Content
              Column(
                children: [
                  // App Bar
                  _buildAppBar(isDarkMode),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Why Choose Intellix Section
                          _buildWhyChooseSection(isDarkMode),
                          const SizedBox(height: 16),

                          // How It Works Section
                          Expanded(
                            child: _buildHowItWorksSection(isDarkMode),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAnimatedBackgrounds(bool isDarkMode) {
    return Stack(
      children: [
        // Background orb 1
        AnimatedBuilder(
          animation: _backgroundController1,
          builder: (context, child) {
            return Positioned(
              top: -80 + (_backgroundController1.value * 20),
              right: -80,
              child: Opacity(
                opacity: 0.3 + (_backgroundController1.value * 0.2),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDarkMode
                          ? [
                              const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                              const Color(0xFF06B6D4).withValues(alpha: 0.2),
                            ]
                          : [
                              const Color(0xFF0284C7).withValues(alpha: 0.2),
                              const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                            ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Background orb 2
        AnimatedBuilder(
          animation: _backgroundController2,
          builder: (context, child) {
            return Positioned(
              bottom: -80 + (_backgroundController2.value * 30),
              left: -80,
              child: Opacity(
                opacity: 0.2 + (_backgroundController2.value * 0.2),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDarkMode
                          ? [
                              const Color(0xFF06B6D4).withValues(alpha: 0.3),
                              const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                            ]
                          : [
                              const Color(0xFF06B6D4).withValues(alpha: 0.15),
                              const Color(0xFFBAE6FD).withValues(alpha: 0.2),
                            ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Background orb 3
        AnimatedBuilder(
          animation: _backgroundController3,
          builder: (context, child) {
            return Positioned(
              top: MediaQuery.of(context).size.height / 3 +
                  (_backgroundController3.value * -20),
              right: 40 + (_backgroundController3.value * 30),
              child: Opacity(
                opacity: 0.25 + (_backgroundController3.value * 0.15),
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDarkMode
                          ? [
                              const Color(0xFF0284C7).withValues(alpha: 0.25),
                              const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                            ]
                          : [
                              const Color(0xFFE0F2FE).withValues(alpha: 0.3),
                              const Color(0xFF0284C7).withValues(alpha: 0.15),
                            ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppBar(bool isDarkMode) {
    return Container(
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
                colors: [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF06B6D4)],
              ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? const Color(0xFF0EA5E9).withValues(alpha: 0.4)
                : const Color(0xFF0284C7).withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 40, bottom: 16, left: 24, right: 24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.psychology, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          const Text(
            'What is Intellix',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseSection(bool isDarkMode) {
    final benefits = [
      {'icon': Icons.flash_on, 'text': 'Real-time conversation analysis'},
      {'icon': Icons.shield, 'text': 'Secure and professional platform'},
      {'icon': Icons.schedule, 'text': 'Save time with automated note-taking'},
      {'icon': Icons.bar_chart, 'text': 'Data-driven decision making'},
      {'icon': Icons.people, 'text': 'Connect with verified experts'},
      {'icon': Icons.auto_awesome, 'text': 'AI-enhanced productivity'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Choose Intellix?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? const Color(0xFF0EA5E9)
                            .withValues(alpha: 0.4 + (_glowController.value * 0.2))
                        : const Color(0xFF0284C7)
                            .withValues(alpha: 0.3 + (_glowController.value * 0.15)),
                    blurRadius: 40,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF132F4C).withValues(alpha: 0.9),
                            const Color(0xFF0A1929).withValues(alpha: 0.8),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.9),
                            Colors.white.withValues(alpha: 0.7),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF1E4976).withValues(alpha: 0.5)
                        : const Color(0xFFE0F2FE).withValues(alpha: 0.8),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: benefits.length,
                  itemBuilder: (context, index) {
                    return _buildBenefitCard(
                      icon: benefits[index]['icon'] as IconData,
                      text: benefits[index]['text'] as String,
                      isDarkMode: isDarkMode,
                      delay: index * 80,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String text,
    required bool isDarkMode,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.8 + (value * 0.2), // Scale animation
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E4976).withValues(alpha: 0.2),
                            const Color(0xFF0A1929).withValues(alpha: 0.1),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFE0F2FE).withValues(alpha: 0.4),
                            Colors.white.withValues(alpha: 0.3),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF0EA5E9).withValues(alpha: 0.2)
                        : const Color(0xFF0284C7).withValues(alpha: 0.1),
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    // Gradient accent on left edge (NEW - from Figma)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDarkMode
                                ? [const Color(0xFF0EA5E9), const Color(0xFF06B6D4)]
                                : [const Color(0xFF0284C7), const Color(0xFF0EA5E9)],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    
                    // Content
                    Row(
                      children: [
                        const SizedBox(width: 8), // Space for gradient accent
                        Icon(
                          icon,
                          size: 20,
                          color: isDarkMode
                              ? const Color(0xFF0EA5E9)
                              : const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode
                                  ? const Color(0xFFD1D5DB)
                                  : const Color(0xFF374151),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHowItWorksSection(bool isDarkMode) {
    final steps = [
      {
        'step': '1',
        'title': 'Connect with Experts',
        'desc': 'Browse and book sessions with verified industry experts'
      },
      {
        'step': '2',
        'title': 'AI-Enhanced Sessions',
        'desc': 'Our AI analyzes conversations in real-time during video calls'
      },
      {
        'step': '3',
        'title': 'Get Smart Insights',
        'desc': 'Receive automated notes, summaries, and actionable insights'
      },
      {
        'step': '4',
        'title': 'Track Your Progress',
        'desc': 'Monitor your learning journey with analytics and trends'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How It Works',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? const Color(0xFF06B6D4) : const Color(0xFF0284C7),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: steps.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildStepCard(
                  step: steps[index]['step'] as String,
                  title: steps[index]['title'] as String,
                  desc: steps[index]['desc'] as String,
                  isDarkMode: isDarkMode,
                  delay: 600 + (index * 100),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String desc,
    required bool isDarkMode,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-30 * (1 - value), 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: isDarkMode
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFF132F4C).withValues(alpha: 0.6),
                          const Color(0xFF1E4976).withValues(alpha: 0.4),
                          const Color(0xFF0A1929).withValues(alpha: 0.4),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.7),
                          const Color(0xFFE0F2FE).withValues(alpha: 0.5),
                          Colors.white.withValues(alpha: 0.5),
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF1E4976).withValues(alpha: 0.4)
                      : const Color(0xFFE0F2FE).withValues(alpha: 0.7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
                        : const Color(0xFF0284C7).withValues(alpha: 0.15),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Number Badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? [
                                const Color(0xFF0EA5E9),
                                const Color(0xFF0284C7),
                                const Color(0xFF06B6D4),
                              ]
                            : [
                                const Color(0xFF0284C7),
                                const Color(0xFF0EA5E9),
                                const Color(0xFF06B6D4),
                              ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? const Color(0xFF0EA5E9).withValues(alpha: 0.4)
                              : const Color(0xFF0284C7).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        step,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF4B5563),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
