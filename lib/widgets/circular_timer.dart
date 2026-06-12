import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'dart:math' as math;

class CircularTimer extends StatelessWidget {
  final int currentTime;
  final int totalTime;
  final int minutes;
  final int seconds;
  final int totalMinutes;

  const CircularTimer({
    super.key,
    required this.currentTime,
    required this.totalTime,
    required this.minutes,
    required this.seconds,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentTime / totalTime;
    final angle = 2 * math.pi * (1 - progress);

    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[300]!,
                width: 8,
              ),
            ),
          ),
          // Progress arc
          CustomPaint(
            size: const Size(250, 250),
            painter: TimerPainter(angle: angle),
          ),
          // Time display
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                totalTime >= 60 
                    ? '$totalMinutes ${totalMinutes == 1 ? 'Minute' : 'Minutes'}'
                    : '$totalTime ${totalTime == 1 ? 'Second' : 'Seconds'}',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textPrimary, // Brown color
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final double angle;

  TimerPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary // Brown color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      -angle, // Negative to go clockwise
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}
