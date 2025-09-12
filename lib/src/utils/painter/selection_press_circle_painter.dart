import 'package:flutter/material.dart';

class SelectionPressCirclePainter extends CustomPainter {
  final Offset position;

  static const double _defaultCircleRadius = 20.0;
  static const double _circleAlpha = 0.5;

  SelectionPressCirclePainter(this.position);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: _circleAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, _defaultCircleRadius, paint);
  }

  @override
  bool shouldRepaint(covariant SelectionPressCirclePainter oldDelegate) {
    return position != oldDelegate.position;
  }
}
