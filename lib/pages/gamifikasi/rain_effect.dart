import 'package:flutter/material.dart';
import 'dart:math';

class RainEffect extends StatefulWidget {
  const RainEffect({Key? key}) : super(key: key);

  @override
  State<RainEffect> createState() => _RainEffectState();
}

class _RainEffectState extends State<RainEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<RainDrop> _drops = [];
  final int _dropCount = 150; // More drops for better effect
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // Faster animation
      vsync: this,
    )..repeat();

    // Initialize rain drops with random properties
    _initializeDrops();
  }

  void _initializeDrops() {
    _drops.clear();
    for (int i = 0; i < _dropCount; i++) {
      _drops.add(RainDrop(
        x: _random.nextDouble() * 400, // Random horizontal position
        y: _random.nextDouble() * -200, // Start above screen
        speed: 0.3 + _random.nextDouble() * 0.7, // Random speed (0.3-1.0)
        length: 15 + _random.nextDouble() * 25, // Random length (15-40)
        opacity: 0.3 + _random.nextDouble() * 0.5, // Random opacity (0.3-0.8)
        angle: -15 + _random.nextDouble() * 10, // Slight angle variation
      ));
    }
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
        return CustomPaint(
          painter: _RainPainter(
            animationValue: _controller.value,
            drops: _drops,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class RainDrop {
  double x;
  double y;
  final double speed;
  final double length;
  final double opacity;
  final double angle;

  RainDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
    required this.opacity,
    required this.angle,
  });

  void update(Size size) {
    // Move drop down and slightly to the right
    y += speed * 8; // Faster movement
    x += speed * 0.5; // Slight horizontal drift
    
    // Reset drop when it goes off screen
    if (y > size.height + 50) {
      y = -length;
      x = Random().nextDouble() * (size.width + 100) - 50;
    }
  }
}

class _RainPainter extends CustomPainter {
  final double animationValue;
  final List<RainDrop> drops;

  _RainPainter({required this.animationValue, required this.drops});

  @override
  void paint(Canvas canvas, Size size) {
    // Create gradient paint for more realistic drops
    final Paint dropPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final drop in drops) {
      // Update drop position
      drop.update(size);
      
      // Create gradient effect
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.lightBlue.withOpacity(drop.opacity * 0.3),
          Colors.blue.withOpacity(drop.opacity),
          Colors.lightBlue.withOpacity(drop.opacity * 0.8),
        ],
      );

      dropPaint.shader = gradient.createShader(
        Rect.fromLTWH(drop.x, drop.y, 2, drop.length),
      );

      // Calculate end position based on angle
      final radians = drop.angle * (pi / 180);
      final endX = drop.x + cos(radians) * drop.length * 0.3;
      final endY = drop.y + drop.length;

      // Draw the raindrop as a line
      canvas.drawLine(
        Offset(drop.x, drop.y),
        Offset(endX, endY),
        dropPaint,
      );

      // Add a small circle at the bottom for drop effect
      final circlePaint = Paint()
        ..color = Colors.lightBlue.withOpacity(drop.opacity * 0.4)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(endX, endY),
        1.0,
        circlePaint,
      );
    }

    // Add subtle background mist effect
    final mistPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (i * 50.0) % size.width;
      final y = (animationValue * size.height * 2) % size.height;
      canvas.drawCircle(
        Offset(x, y),
        2.0,
        mistPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) {
    return true; // Always repaint for smooth animation
  }
}
