import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Circular progress ring badge showing progress count and label in the center.
class CircularProgressBadge extends StatelessWidget {
  final int completed;
  final int total;
  final String sublabel;
  final double size;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;

  const CircularProgressBadge({
    super.key,
    required this.completed,
    required this.total,
    required this.sublabel,
    this.size = 72,
    this.strokeWidth = 6.0,
    this.progressColor = AppColors.dustyGreenDark,
    this.trackColor = AppColors.secondaryNeutral,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CircularProgressPainter(
              progress: progress,
              strokeWidth: strokeWidth,
              progressColor: progressColor,
              trackColor: trackColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$completed/$total',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.signalBlack,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background full track
    canvas.drawCircle(center, radius, trackPaint);

    // Foreground progress arc (starting at 12 o'clock = -pi/2)
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.trackColor != trackColor;
}
