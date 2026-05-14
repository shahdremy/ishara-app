import 'dart:math';
import 'package:flutter/material.dart';

class BubbleSpec {
  final Offset origin;
  final double radius;
  final Color color;
  final double phase;
  const BubbleSpec(this.origin, this.radius, this.color, this.phase);
}

class FadeBubblesPainter extends CustomPainter {
  final double progress;
  final List<BubbleSpec> bubbles;

  FadeBubblesPainter({required this.progress, required this.bubbles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final t = (progress + b.phase) % 1.0;
      final signal = (sin(2 * pi * t) + 1) / 2;
      final baseOpacity =
      (b.color.value == const Color(0xFFD0EFF7).value) ? 0.50 : 0.40;
      final opacity = (0.15 + signal * baseOpacity).clamp(0.0, 1.0);
      final scale = 0.9 + signal * 0.15;
      final radius = b.radius * scale;
      final paint = Paint()..color = b.color.withOpacity(opacity);
      canvas.drawCircle(b.origin, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FadeBubblesPainter oldDelegate) => true;
}
