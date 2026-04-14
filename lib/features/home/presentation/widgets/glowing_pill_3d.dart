import 'package:flutter/material.dart';

class GlowingPill3D extends StatefulWidget {
  final bool isDarkMode;

  const GlowingPill3D({super.key, required this.isDarkMode});

  @override
  State<GlowingPill3D> createState() => _GlowingPill3DState();
}

class _GlowingPill3DState extends State<GlowingPill3D>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.85,
          child: SizedBox(
            width: 300,
            height: 300,
            child: CustomPaint(
              painter: GlowingPillPainter(
                isDarkMode: widget.isDarkMode,
                animationValue: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class GlowingPillPainter extends CustomPainter {
  final bool isDarkMode;
  final double animationValue;

  GlowingPillPainter({required this.isDarkMode, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Define the main pill shape (RRect)
    // Reference image shows a pill shape, say width 200, height 120?
    // Let's use 0.7 of width for shape width, and aspect ratio ~1.6
    final double pillWidth = size.width * 0.75;
    final double pillHeight = pillWidth / 1.6;

    final Rect pillRectBounds = Rect.fromCenter(
      center: center,
      width: pillWidth,
      height: pillHeight,
    );
    final RRect pillShape = RRect.fromRectAndRadius(
      pillRectBounds,
      Radius.circular(pillHeight / 2),
    );

    // Draw Outer Shadows
    _drawOuterShadows(canvas, pillShape);

    // Draw Main Body
    _drawMainBody(canvas, pillShape, pillRectBounds);

    // Draw Inset Shadows
    _drawInsetShadows(canvas, pillShape);

    // Draw Eyes
    _drawEyes(canvas, center, pillWidth, pillHeight);
  }

  void _drawOuterShadows(Canvas canvas, RRect shape) {
    // 0 25px 140px 0 rgba(6, 182, 212, 0.50)
    _drawShadow(canvas, shape, const Offset(0, 25), 70,
        const Color(0xFF06B6D4).withValues(alpha: 0.50));
    // 0 45px 240px 0 rgba(14, 165, 233, 0.40)
    _drawShadow(canvas, shape, const Offset(0, 45), 120,
        const Color(0xFF0EA5E9).withValues(alpha: 0.40));
    // 0 -10px 80px 0 rgba(224, 242, 254, 0.20)
    _drawShadow(canvas, shape, const Offset(0, -10), 40,
        const Color(0xFFE0F2FE).withValues(alpha: 0.20));
  }

  void _drawShadow(Canvas canvas, RRect shape, Offset offset, double blurSigma,
      Color color) {
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    canvas.drawRRect(shape.shift(offset), paint);
  }

  void _drawMainBody(Canvas canvas, RRect shape, Rect bounds) {
    // Main Gradient: Glossy Blue 3D look
    // Radial gradient centered near top-left or top-center
    final paint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.2), // Near top center highlight
        radius: 1.2,
        colors: [
          Color(0xFF67E8F9), // Bright Cyan Highlight
          Color(0xFF06B6D4), // Cyan
          Color(0xFF0284C7), // Blue
          Color(0xFF0369A1), // Darker Blue
          Color(0xFF0C4A6E), // Deep Blue Shadow
        ],
        stops: [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(bounds);

    canvas.drawRRect(shape, paint);

    // Add a top glossy highlight (inner reflection)
    final highlightPath = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(
          bounds.left + bounds.width * 0.1,
          bounds.top + bounds.height * 0.05,
          bounds.width * 0.8,
          bounds.height * 0.4,
        ),
        topLeft: Radius.circular(bounds.height * 0.4),
        topRight: Radius.circular(bounds.height * 0.4),
        bottomLeft: Radius.circular(bounds.height * 0.1),
        bottomRight: Radius.circular(bounds.height * 0.1),
      ));

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(bounds);

    canvas.drawPath(highlightPath, highlightPaint);
  }

  void _drawInsetShadows(Canvas canvas, RRect shape) {
    // Clip to shape
    canvas.save();
    canvas.clipRRect(shape);

    // Simulate inset shadows using the frame technique (draw outside ring shifted in)
    // The frame needs to be the inverse of the RRect
    // Simplified: Draw a stroked RRect with blur, shifted?
    // Or stick to the "frame with hole" technique which worked well.

    final holeRect = shape.outerRect;
    final bigRect = holeRect.inflate(50);

    // Helper to draw inset
    void drawInset(double dx, double dy, double blur, Color color) {
      final framePath = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(bigRect)
        ..addRRect(shape.shift(Offset(dx, dy)));

      final paint = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

      canvas.drawPath(framePath, paint);
    }

    // -10px -10px 30px (Top Left light shadow) -> Shift +10, +10 to draw shadow on Top Left?
    // If I shift hole +10, +10 (down, right), the gap appears on Top & Left.
    // The Frame paint covers Top & Left.
    // So shift = (10, 10) creates shadow on Top-Left.
    drawInset(10, 10, 15,
        const Color(0xFF0C4A6E).withValues(alpha: 0.6)); // Deep shadow top-left

    // Bottom-Right highlight/light reflection?
    // usually inset shadow on bottom right is light (reflection)
    // Shift (-10, -10). Hole moves Up-Left. Frame covers Bottom-Right.
    drawInset(
        -10,
        -10,
        15,
        const Color(0xFF67E8F9)
            .withValues(alpha: 0.3)); // Cyan highlight bottom-right

    canvas.restore();
  }

  void _drawEyes(
      Canvas canvas, Offset center, double pillWidth, double pillHeight) {
    final double eyeRadius = pillHeight * 0.18; // circle radius
    final double eyeSpacing = pillWidth * 0.15;

    final Paint eyePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFE0F2FE)],
      ).createShader(Rect.fromCenter(
          center: center, width: pillWidth, height: pillHeight));

    final Paint glowPaint = Paint()
      ..color = const Color(0xFF67E8F9).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final Paint shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7);

    void drawEye(Offset eyeCenter) {
      // Glow ring behind eye
      canvas.drawCircle(eyeCenter, eyeRadius + 3, glowPaint);
      // Main eye circle
      canvas.drawCircle(eyeCenter, eyeRadius, eyePaint);
      // Small shine dot (top-right of eye)
      canvas.drawCircle(
        eyeCenter + Offset(eyeRadius * 0.3, -eyeRadius * 0.3),
        eyeRadius * 0.22,
        shinePaint,
      );
    }

    final double centerX = center.dx;
    final double centerY = center.dy;

    // Left Eye
    drawEye(Offset(centerX - eyeRadius - eyeSpacing / 2, centerY));
    // Right Eye
    drawEye(Offset(centerX + eyeRadius + eyeSpacing / 2, centerY));
  }

  @override
  bool shouldRepaint(covariant GlowingPillPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
