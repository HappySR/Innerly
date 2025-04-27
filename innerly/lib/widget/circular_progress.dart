import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CircularProgress extends CustomPainter {
  final int currentPage;
  final int totalPages;

  CircularProgress({
    required this.currentPage,
    required this.totalPages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background grey circle
    final greyPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, greyPaint);

    // Green progress arc
    final greenPaint = Paint()
      ..color = InnerlyTheme.secondary
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Sweep angle (in radians)
    double sweepAngle = ((currentPage + 1) / totalPages) * 2 * 3.141592653589793;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.1415926, // Start from left
      sweepAngle,
      false,
      greenPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
