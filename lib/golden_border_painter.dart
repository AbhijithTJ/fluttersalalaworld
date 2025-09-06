import 'dart:ui';

import 'package:flutter/material.dart';

class GoldenBorderPainter extends CustomPainter {
  final double animationValue; // Value from 0.0 to 1.0 for animation progress
  final double borderWidth;
  final double borderRadius;

  GoldenBorderPainter({
    required this.animationValue,
    this.borderWidth = 5.0,
    this.borderRadius = 16.0, // Assuming a similar border radius to the Card in BillingPage
  });

  @override
  void paint(Canvas canvas, Size size) {
    final RRect outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3) // A subtle base border
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(outerRect, borderPaint);

    // Define the golden gradient for the glossy effect
    final Paint glossyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 1.5 // Make the glossy part slightly thicker
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.amber.withOpacity(0.8),
          Colors.yellow.withOpacity(0.9),
          Colors.amber.withOpacity(0.8),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(outerRect.outerRect); // Apply shader to the bounding box of the RRect

    // Create a path for the border
    final Path borderPath = Path()..addRRect(outerRect);

    // Calculate the length of the path
    final PathMetrics pathMetrics = borderPath.computeMetrics();
    final PathMetric pathMetric = pathMetrics.first;
    final double pathLength = pathMetric.length;

    // Calculate the segment of the path to draw for the glossy effect
    const double segmentLength = 0.3; // The length of the glossy segment (as a fraction of total path length)
    final double start = pathLength * animationValue;
    final double end = start + (pathLength * segmentLength);

    // Get the animated segment of the path
    final Path animatedPath = pathMetric.extractPath(start, end);

    canvas.drawPath(animatedPath, glossyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as GoldenBorderPainter).animationValue != animationValue;
  }
}
