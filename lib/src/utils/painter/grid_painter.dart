import 'dart:ui';

import 'package:flexi_editor/src/canvas_context/model/grid_type.dart';
import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final GridType gridType;
  final Color gridColor;
  final double gridSpacing;
  final Offset position;
  final double scale;

  static const double minPixelSpacing = 20.0;

  GridPainter({
    required this.gridType,
    required this.gridColor,
    required this.gridSpacing,
    required this.position,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (gridType == GridType.none) return;

    final Paint paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 화면에 보이는 영역에 대해서만 그리기 위해 계산
    // position은 캔버스의 이동 값 (음수일 수 있음)
    // scale은 캔버스의 확대/축소 값

    // 동적 간격 조정 (Dynamic Spacing)
    double effectiveSpacing = gridSpacing;
    while (effectiveSpacing * scale < minPixelSpacing) {
      effectiveSpacing *= 2;
    }

    // 실제 그리드 간격 (스케일 적용)
    final double spacing = effectiveSpacing * scale;

    // 시작 오프셋 (position을 spacing으로 나눈 나머지를 이용하여 그리드가 이동하도록 함)
    final double startX = position.dx % spacing;
    final double startY = position.dy % spacing;

    if (gridType == GridType.line) {
      // 세로선 그리기
      for (double x = startX; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }

      // 가로선 그리기
      for (double y = startY; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (gridType == GridType.point) {
      paint.style = PaintingStyle.fill;
      paint.strokeCap = StrokeCap.round;
      paint.strokeWidth = 3.0; // 점 크기

      final List<Offset> points = [];

      // 점 그리기 (Batch Draw)
      for (double x = startX; x < size.width; x += spacing) {
        for (double y = startY; y < size.height; y += spacing) {
          points.add(Offset(x, y));
        }
      }

      if (points.isNotEmpty) {
        canvas.drawPoints(PointMode.points, points, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.gridType != gridType ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.gridSpacing != gridSpacing ||
        oldDelegate.position != position ||
        oldDelegate.scale != scale;
  }
}
