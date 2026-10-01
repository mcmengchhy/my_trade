import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../utils/challenge_math.dart' as math_utils;

class WidgetSparklineChart extends StatelessWidget {
  const WidgetSparklineChart({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final duration = challenge.durationDays;
    final lastPlottedDay = math.max(
      math_utils.currentDayIndex(challenge),
      math_utils.lastActivityDayIndex(challenge),
    );

    final pacePoints = List.generate(
      duration + 1,
      (i) => _Point(i.toDouble(), math_utils.expectedBalance(challenge, i)),
    );

    final actualPoints = List.generate(
      lastPlottedDay + 1,
      (i) => _Point(i.toDouble(), math_utils.actualBalanceAtDayIndex(challenge, i)),
    );

    return Container(
      width: 300,
      height: 100,
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: CustomPaint(
        painter: _SparklinePainter(
          duration: duration.toDouble(),
          targetBalance: challenge.targetBalance,
          startBalance: challenge.startBalance,
          pacePoints: pacePoints,
          actualPoints: actualPoints,
        ),
      ),
    );
  }
}

class _Point {
  final double x;
  final double y;
  const _Point(this.x, this.y);
}

class _SparklinePainter extends CustomPainter {
  final double duration;
  final double targetBalance;
  final double startBalance;
  final List<_Point> pacePoints;
  final List<_Point> actualPoints;

  _SparklinePainter({
    required this.duration,
    required this.targetBalance,
    required this.startBalance,
    required this.pacePoints,
    required this.actualPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (duration <= 0) return;

    final allY = [
      startBalance,
      targetBalance,
      ...pacePoints.map((p) => p.y),
      ...actualPoints.map((p) => p.y),
    ];

    double minY = allY.reduce(math.min);
    double maxY = allY.reduce(math.max);

    if (maxY == minY) {
      maxY += 1.0;
      minY -= 1.0;
    }

    final paddingY = (maxY - minY) * 0.1;
    minY -= paddingY;
    maxY += paddingY;

    double toX(double xVal) => (xVal / duration) * size.width;
    double toY(double yVal) =>
        size.height - ((yVal - minY) / (maxY - minY)) * size.height;

    // Draw Target Line (Dashed Cyan)
    final targetY = toY(targetBalance);
    final targetPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double dashWidth = 4, dashSpace = 4, startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, targetY),
        Offset(math.min(startX + dashWidth, size.width), targetY),
        targetPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw Pace Line (Dashed Gray)
    final pacePath = Path();
    for (int i = 0; i < pacePoints.length; i++) {
      final px = toX(pacePoints[i].x);
      final py = toY(pacePoints[i].y);
      if (i == 0) {
        pacePath.moveTo(px, py);
      } else {
        pacePath.lineTo(px, py);
      }
    }

    final pacePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final metrics = pacePath.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final len = math.min(dashWidth, metric.length - distance);
        canvas.drawPath(
          metric.extractPath(distance, distance + len),
          pacePaint,
        );
        distance += dashWidth + dashSpace;
      }
    }

    if (actualPoints.isEmpty) return;

    // Build Actual Equity Path
    final actualPath = Path();
    final fillPath = Path();

    final firstX = toX(actualPoints.first.x);
    final firstY = toY(actualPoints.first.y);

    actualPath.moveTo(firstX, firstY);
    fillPath.moveTo(firstX, size.height);
    fillPath.lineTo(firstX, firstY);

    for (int i = 1; i < actualPoints.length; i++) {
      final px = toX(actualPoints[i].x);
      final py = toY(actualPoints[i].y);
      actualPath.lineTo(px, py);
      fillPath.lineTo(px, py);
    }

    final lastX = toX(actualPoints.last.x);
    final lastY = toY(actualPoints.last.y);
    fillPath.lineTo(lastX, size.height);
    fillPath.close();

    // Gradient Fill Under Equity Curve
    final isProfitable = actualPoints.last.y >= startBalance;
    final primaryColor =
        isProfitable ? const Color(0xFF4ADE80) : const Color(0xFFF87171);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.35),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Actual Line Stroke
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(actualPath, linePaint);

    // Glowing Dot on Endpoint
    final dotOuterPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(lastX, lastY), 6, dotOuterPaint);

    final dotInnerPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(lastX, lastY), 3, dotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => true;
}
