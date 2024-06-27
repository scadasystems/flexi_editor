import 'package:flutter/material.dart';

class SelectionPressCirclePainter extends CustomPainter {
  final Offset position;

  SelectionPressCirclePainter(this.position);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 20, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
