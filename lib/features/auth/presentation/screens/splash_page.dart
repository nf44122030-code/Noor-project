import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  
  late Animation<double> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _layersAnimation;
  late Animation<double> _depthAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    
    // Pulse controller for glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    
    // Shimmer controller for progress bar
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Slide animation - comes from left side
    _slideAnimation = Tween<double>(begin: -400, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // 3D rotation animation
    _rotationAnimation = Tween<double>(begin: -math.pi * 0.7, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // Scale animation with bounce
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.9, curve: Curves.easeOut),
      ),
    );

    // Opacity animation
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // Layers spread animation
    _layersAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.8, curve: Curves.easeOutBack),
      ),
    );
    
    // Depth animation for 3D effect
    _depthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
      ),
    );

    // Progress bar animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _mainController.forward();

    _mainController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          context.go('/intro');
        }
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Animated 3D I Logo
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _mainController,
                    _pulseController,
                  ]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_slideAnimation.value, 0),
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002)
                            ..rotateY(_rotationAnimation.value)
                            ..rotateX(_depthAnimation.value * 0.1),
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: CustomPaint(
                              size: const Size(200, 280),
                              painter: LayeredILogoPainter(
                                layersSpread: _layersAnimation.value,
                                pulseValue: _pulseController.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 30),
                
                // By Noor Fayyad text
                AnimatedBuilder(
                  animation: _opacityAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: const Text(
                        'By Noor Fayyad',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 3,
                        ),
                      ),
                    );
                  },
                ),
                
                const Spacer(flex: 3),
              ],
            ),
          ),
          
          // Bottom section
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Column(
              children: [

                // Progress Bar with shimmer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _progressAnimation,
                      _shimmerController,
                    ]),
                    builder: (context, child) {
                      return Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderDimDark,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Stack(
                          children: [
                            // Progress fill
                            FractionallySizedBox(
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(
                                      -1 + _shimmerController.value * 2,
                                      0,
                                    ),
                                    end: Alignment(
                                      1 + _shimmerController.value * 2,
                                      0,
                                    ),
                                    colors: const [
                                      AppColors.primaryDeep,
                                      AppColors.primary,
                                      AppColors.accent,
                                      AppColors.primary,
                                      AppColors.primaryDeep,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.6),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Glow at the end
                            Positioned(
                              left: (_progressAnimation.value * 
                                  (MediaQuery.of(context).size.width - 160)) - 6,
                              top: -4,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.8),
                                      blurRadius: 15,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced 3D layered I logo painter
class LayeredILogoPainter extends CustomPainter {
  final double layersSpread;
  final double pulseValue;

  LayeredILogoPainter({
    required this.layersSpread,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Layer configurations with gradient colors
    final List<List<Color>> layerGradients = [
      [AppColors.borderDark, AppColors.borderDimDark], // Back
      [AppColors.primaryDeep.withValues(alpha: 0.5), AppColors.primaryDeep],
      [AppColors.primaryDark, AppColors.primaryDeep],
      [AppColors.primary, AppColors.primaryDark],
      [AppColors.accent, AppColors.primary], // Front
    ];
    
    // Draw shadow/glow first
    _drawAmbientGlow(canvas, center, size);
    
    // Draw each layer from back to front
    for (int i = 0; i < layerGradients.length; i++) {
      final offset = (layerGradients.length - 1 - i) * 10 * layersSpread;
      final depthOffset = i * 3 * layersSpread;
      _drawILayer(
        canvas,
        center,
        size,
        layerGradients[i],
        offset,
        depthOffset,
        i == layerGradients.length - 1, // Is front layer
      );
    }
  }

  void _drawAmbientGlow(Canvas canvas, Offset center, Size size) {
    // Outer glow
    final outerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.25 * pulseValue),
          AppColors.primaryDeep.withValues(alpha: 0.1 * pulseValue),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCenter(center: center, width: 250, height: 320),
      );
    canvas.drawCircle(center, 140, outerGlow);
    
    // Inner intense glow
    final innerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withValues(alpha: 0.4 * pulseValue),
          AppColors.primary.withValues(alpha: 0.15 * pulseValue),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCenter(center: center, width: 180, height: 240),
      );
    canvas.drawCircle(center, 90, innerGlow);
  }

  void _drawILayer(
    Canvas canvas,
    Offset center,
    Size size,
    List<Color> gradientColors,
    double offset,
    double depthOffset,
    bool isFrontLayer,
  ) {
    const iWidth = 80.0;
    const iHeight = 180.0;
    const barHeight = 22.0;
    const barWidth = 80.0;
    
    final left = center.dx - iWidth / 2 + offset + depthOffset;
    final top = center.dy - iHeight / 2 - offset * 0.3;
    
    // Create gradient paint
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(
        Rect.fromLTWH(left, top, iWidth, iHeight),
      )
      ..style = PaintingStyle.fill;
    
    // Add shadow for depth
    if (!isFrontLayer) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    }
    
    // Top bar of I (rounded)
    final topBarRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, barWidth, barHeight),
      const Radius.circular(4),
    );
    
    // Bottom bar of I (rounded)
    final bottomBarRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top + iHeight - barHeight, barWidth, barHeight),
      const Radius.circular(4),
    );
    
    // Middle vertical bar (rounded)
    const middleBarWidth = 22.0;
    final middleBarRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        left + (barWidth - middleBarWidth) / 2,
        top + barHeight,
        middleBarWidth,
        iHeight - barHeight * 2,
      ),
      const Radius.circular(4),
    );
    
    // Draw the three parts
    canvas.drawRRect(topBarRect, paint);
    canvas.drawRRect(bottomBarRect, paint);
    canvas.drawRRect(middleBarRect, paint);
    
    // Add highlight on front layer
    if (isFrontLayer) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      
      final highlightRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 3, top + 3, barWidth - 6, barHeight / 2),
        const Radius.circular(2),
      );
      canvas.drawRRect(highlightRect, highlightPaint);
      
      // Add edge glow
      final edgeGlow = Paint()
        ..color = Colors.white.withValues(alpha: 0.15 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * pulseValue);
      
      canvas.drawRRect(topBarRect, edgeGlow);
      canvas.drawRRect(bottomBarRect, edgeGlow);
      canvas.drawRRect(middleBarRect, edgeGlow);
    }
  }

  @override
  bool shouldRepaint(covariant LayeredILogoPainter oldDelegate) {
    return oldDelegate.layersSpread != layersSpread ||
        oldDelegate.pulseValue != pulseValue;
  }
}
