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
  final int _dropCount = 150;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _initializeDrops();
  }

  void _initializeDrops() {
    _drops.clear();
    for (int i = 0; i < _dropCount; i++) {
      _drops.add(RainDrop(
        x: _random.nextDouble() * 400,
        y: _random.nextDouble() * -200,
        speed: 0.3 + _random.nextDouble() * 0.7,
        length: 15 + _random.nextDouble() * 25,
        opacity: 0.3 + _random.nextDouble() * 0.5,
        angle: -15 + _random.nextDouble() * 10,
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
    y += speed * 8;
    x += speed * 0.5;

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
    final Paint dropPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final drop in drops) {
      drop.update(size);

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

      final radians = drop.angle * (pi / 180);
      final endX = drop.x + cos(radians) * drop.length * 0.3;
      final endY = drop.y + drop.length;

      // Natural fade based on Y position only, no black overlay
      double fadeFactor = 1.0;
      const fadeStart = 0.7; // start fading at 70% of screen height
      if (drop.y > size.height * fadeStart) {
        final fadeProgress = (drop.y - size.height * fadeStart) /
            (size.height * (1.0 - fadeStart));
        fadeFactor = (1.0 - fadeProgress).clamp(0.0, 1.0);
      }

      final fadedPaint = dropPaint
        ..colorFilter = ColorFilter.mode(
          Colors.white.withOpacity(fadeFactor),
          BlendMode.modulate,
        );

      canvas.drawLine(
        Offset(drop.x, drop.y),
        Offset(endX, endY),
        fadedPaint,
      );

      final circlePaint = Paint()
        ..color = Colors.lightBlue.withOpacity(drop.opacity * 0.4 * fadeFactor)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(endX, endY), 1.0, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => true;
}
