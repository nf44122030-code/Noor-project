import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class IntroScreens extends StatefulWidget {
  const IntroScreens({super.key});

  @override
  State<IntroScreens> createState() => _IntroScreensState();
}

class _IntroScreensState extends State<IntroScreens> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroPageData> _pages = [
    IntroPageData(
      title: 'intro_title_1',
      subtitle: 'intro_subtitle_1',
      type: PageType.imageGrid,
      images: [
        'https://images.unsplash.com/photo-1573164713988-8665fc963095?w=400', // Tech Professional
        'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400', // Data/Network
        'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=400', // Team collaboration
        'https://images.unsplash.com/photo-1551434678-e076c223a692?w=400', // Tech Team
        'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=400', // Business Leaders
        'https://images.unsplash.com/photo-1504384545340-562a0ea2af6b?w=400', // Modern Work
        'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400', // AI Network
        'https://images.unsplash.com/photo-1553877522-435f956f1ce7?w=400', // Collaboration
      ],
    ),
    IntroPageData(
      title: 'intro_title_2',
      subtitle: 'intro_subtitle_2',
      type: PageType.promptInterface,
    ),
    IntroPageData(
      title: 'intro_title_3',
      subtitle: 'intro_subtitle_3',
      type: PageType.avatarGrid,
      images: [
        'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400', // Corporate Man
        'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400', // Professional Woman
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400', // Business Leader
        'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400', // Woman Smiling
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400', // Professional Male
        'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=400', // Tech Executive
        'https://images.unsplash.com/photo-1557862921-37829c790f19?w=400', // Startup Leader
        'https://images.unsplash.com/photo-1564564321837-a57b7070ac4f?w=400', // Confident Businessman
      ],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to home screen (which will securely redirect to Login if unauthenticated)
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Page content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),

          // Skip Button
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 16),
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'skip'.tr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom content (dots + button)
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Column(
              children: [
                // Page indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 8 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),

                // Continue button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: _nextPage,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary, // Themed Blue
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'continue_btn'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(IntroPageData pageData) {
    switch (pageData.type) {
      case PageType.imageGrid:
        return ImageGridPage(pageData: pageData);
      case PageType.promptInterface:
        return PromptInterfacePage(pageData: pageData);
      case PageType.avatarGrid:
        return AvatarGridPage(pageData: pageData);
    }
  }
}

// Page 1: Image Grid with scrolling animation
class ImageGridPage extends StatefulWidget {
  final IntroPageData pageData;

  const ImageGridPage({super.key, required this.pageData});

  @override
  State<ImageGridPage> createState() => _ImageGridPageState();
}

class _ImageGridPageState extends State<ImageGridPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: -1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Animated image grid
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Scrolling grid
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_animation.value * 100, 0),
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _buildImageCard(widget.pageData.images![0], 0.8),
                              _buildImageCard(widget.pageData.images![1], 1.0),
                              _buildImageCard(widget.pageData.images![2], 0.9),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              _buildImageCard(widget.pageData.images![3], 1.0),
                              _buildImageCard(widget.pageData.images![4], 0.85),
                              _buildImageCard(widget.pageData.images![5], 0.95),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              _buildImageCard(widget.pageData.images![6], 0.9),
                              _buildImageCard(widget.pageData.images![7], 0.8),
                              _buildImageCard(widget.pageData.images![0], 1.0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Gradient overlay at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 200,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0.5),
                            Colors.black.withValues(alpha: 0.9),
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              flex: 2,
              child: SizedBox.shrink(), // Reserve lower screen space
            ),
          ],
        ),

        // Text content properly anchored
        SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.pageData.title.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.pageData.subtitle.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 140), // Exact matching spacing to Screen 2
                  ],
                ),
              ),
            ],
          ),
          ), // Closes SizedBox
        ),
      ],
    );
  }

  Widget _buildImageCard(String imageUrl, double scale) {
    return Expanded(
      child: Transform.scale(
        scale: scale,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

// Page 2: Prompt Interface with blue glowing background
class PromptInterfacePage extends StatelessWidget {
  final IntroPageData pageData;

  const PromptInterfacePage({super.key, required this.pageData});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blue glowing background
        Positioned(
          top: -100,
          left: -100,
          right: -100,
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.3, -0.5),
                radius: 1.2,
                colors: [
                  AppColors.primaryDeep.withValues(alpha: 0.8),
                  AppColors.primaryDark.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Content
        SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
              const SizedBox(height: 20),

              // Prompt interface mockup
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prompt label
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Prompt',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                          Icon(
                            Icons.close,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Text input area
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.topLeft,
                        child: TypewriterText(
                          text: 'Type your question or topic here\nOur AI will synthesize the ideal response',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),

                      // Mic icon
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.mic,
                          color: Colors.white.withValues(alpha: 0.4),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Style and Model selectors
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Role',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.add,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Optional',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Inception AI',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Intelligence Engine',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Ratio toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Class',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Text content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      pageData.title.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pageData.subtitle.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 140), // Space for dots and button
                  ],
                ),
              ),
            ],
          ),
          ), // Closes SizedBox
        ),
      ],
    );
  }
}

// Page 3: Avatar Grid with scrolling animation
class AvatarGridPage extends StatefulWidget {
  final IntroPageData pageData;

  const AvatarGridPage({super.key, required this.pageData});

  @override
  State<AvatarGridPage> createState() => _AvatarGridPageState();
}

class _AvatarGridPageState extends State<AvatarGridPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: -50).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Animated avatar grid
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Scrolling grid
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _animation.value),
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        physics: const NeverScrollableScrollPhysics(),
                        children: widget.pageData.images!.map((url) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Gradient overlay at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 250,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0.5),
                            Colors.black.withValues(alpha: 0.8),
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              flex: 2,
              child: SizedBox.shrink(), // Reserve lower screen space
            ),
          ],
        ),

        // Text content properly anchored
        SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.pageData.title.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.pageData.subtitle.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 140), // Exact matching spacing to Screen 2
                  ],
                ),
              ),
            ],
          ),
          ), // Closes SizedBox
        ),
      ],
    );
  }
}

// Data model
enum PageType { imageGrid, promptInterface, avatarGrid }

class IntroPageData {
  final String title;
  final String subtitle;
  final PageType type;
  final List<String>? images;

  IntroPageData({
    required this.title,
    required this.subtitle,
    required this.type,
    this.images,
  });
}

// Custom Typewriter Effect Widget for the Prompt Interface
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    // Calculate duration based on text length (approx 40ms per character)
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.text.length * 40),
      vsync: this,
    );
    
    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    
    // Start typing after a short 500ms delay when the page opens
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        String visibleString = widget.text.substring(0, _characterCount.value);
        // Add a pulsing text cursor while typing
        if (_controller.isAnimating) {
          visibleString += '|';
        }
        return Text(
          visibleString,
          style: widget.style,
        );
      },
    );
  }
}
