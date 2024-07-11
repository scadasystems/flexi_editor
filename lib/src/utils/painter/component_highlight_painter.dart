import 'package:flutter/material.dart';

enum ComponentHighlightPainterType { solid, dash }

class ComponentHighlightPainter extends CustomPainter {
  final ComponentHighlightPainterType type;
  final double width;
  final double height;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  // Radius
  final double radiusTl;
  final double radiusTr;
  final double radiusBl;
  final double radiusBr;
  // Setting
  final bool showOutRect;

  ComponentHighlightPainter({
    this.type = ComponentHighlightPainterType.solid,
    required this.width,
    required this.height,
    this.color = Colors.blue,
    this.strokeWidth = 2,
    this.dashWidth = 10,
    this.dashSpace = 5,
    this.radiusTl = 0,
    this.radiusTr = 0,
    this.radiusBl = 0,
    this.radiusBr = 0,
    this.showOutRect = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (dashWidth <= 0 || dashSpace <= 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          0,
          this.width,
          this.height,
        ),
        paint,
      );
      return;
    }

    final width = this.width + strokeWidth;
    final height = this.height + strokeWidth;

    // 현재 크기에 맞는 직사각형 그리기
    if (showOutRect) {
      canvas.drawRect(
        Rect.fromLTWH(-strokeWidth / 2, -strokeWidth / 2, width, height),
        paint,
      );
    }

    // 곡선 모서리를 가진 사각형 경로 생성
    final rect = RRect.fromRectAndCorners(
      Rect.fromLTWH(-strokeWidth / 2, -strokeWidth / 2, width, height),
      topLeft: Radius.circular(radiusTl),
      topRight: Radius.circular(radiusTr),
      bottomLeft: Radius.circular(radiusBl),
      bottomRight: Radius.circular(radiusBr),
    );

    // 대시 효과 적용
    if (dashWidth <= 0 || dashSpace <= 0 || type == ComponentHighlightPainterType.solid) {
      canvas.drawRRect(rect, paint);
    } else {
      Path path = Path()..addRRect(rect);
      Path dashedPath = Path();
      var pathMetrics = path.computeMetrics().toList();
      for (var metric in pathMetrics) {
        var pathLength = 0.0;
        while (pathLength < metric.length) {
          var extractPath = metric.extractPath(pathLength, pathLength + dashWidth);
          dashedPath.addPath(extractPath, Offset.zero);
          pathLength += dashWidth + dashSpace;
        }
      }
      canvas.drawPath(dashedPath, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
