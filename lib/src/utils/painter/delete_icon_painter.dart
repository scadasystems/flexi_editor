import 'package:flutter/material.dart';

class DeleteIconPainter extends CustomPainter {
  final Offset location;
  final double radius;
  final Color color;
  
  static const double _backgroundAlpha = 0.8;
  static const double _borderStrokeWidth = 2.0;

  DeleteIconPainter({
    required this.location,
    required this.radius,
    required this.color,
  }) : assert(radius > 0);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white.withValues(alpha: _backgroundAlpha)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(location, radius, paint);

    paint
      ..style = PaintingStyle.stroke
      ..color = Colors.grey
      ..strokeWidth = _borderStrokeWidth;

    canvas.drawCircle(location, radius, paint);

    paint.color = color;

    var halfRadius = radius / 2;
    canvas.drawLine(
      location + Offset(-halfRadius, -halfRadius),
      location + Offset(halfRadius, halfRadius),
      paint,
    );

    canvas.drawLine(
      location + Offset(halfRadius, -halfRadius),
      location + Offset(-halfRadius, halfRadius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant DeleteIconPainter oldDelegate) {
    return location != oldDelegate.location ||
           radius != oldDelegate.radius ||
           color != oldDelegate.color;
  }

  @override
  bool hitTest(Offset position) {
    final dx = position.dx - location.dx;
    final dy = position.dy - location.dy;
    return dx * dx + dy * dy <= radius * radius;
  }
}
