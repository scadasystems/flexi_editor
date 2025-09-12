import 'package:flutter/material.dart';

class UIConstants {
  static const double selectionBoxStrokeWidth = 2.0;
  static const double selectionBoxAlpha = 0.3;
}

class SelectionBoxPainter extends CustomPainter {
  final Offset startPosition;
  final Offset endPosition;

  SelectionBoxPainter({required this.startPosition, required this.endPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: UIConstants.selectionBoxAlpha)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromPoints(startPosition, endPosition);
    canvas.drawRect(rect, paint);

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = UIConstants.selectionBoxStrokeWidth;

    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant SelectionBoxPainter oldDelegate) {
    return startPosition != oldDelegate.startPosition ||
        endPosition != oldDelegate.endPosition;
  }
}
