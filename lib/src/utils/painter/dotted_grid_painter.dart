import 'package:flexi_editor/src/canvas_context/canvas_dotted_background_config.dart';
import 'package:flutter/material.dart';

/// 캔버스 배경에 도트(점) 그리드를 그리는 페인터입니다.
///
/// - [canvasPosition], [canvasScale]은 캔버스의 현재 변환 값입니다.
/// - [config]의 `*Canvas` 값들은 캔버스 좌표계 기준이며, 실제 렌더링 시 스케일이 반영됩니다.
class DottedGridPainter extends CustomPainter {
  final Offset canvasPosition;
  final double canvasScale;
  final CanvasDottedBackgroundConfig config;

  const DottedGridPainter({
    required this.canvasPosition,
    required this.canvasScale,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!config.enabled) return;
    if (config.gridSpacingCanvas <= 0) return;
    if (config.dotRadiusCanvas <= 0) return;

    final scale = canvasScale;
    if (scale <= 0) return;
    // scale이 너무 작을 때는 도트를 렌더링하지 않아 비용을 줄입니다.
    if (config.minVisibleScale > 0 && scale < config.minVisibleScale) return;

    final spacing = config.gridSpacingCanvas;
    final topLeftCanvas = Offset(
      -canvasPosition.dx / scale,
      -canvasPosition.dy / scale,
    );
    final bottomRightCanvas = Offset(
      (size.width - canvasPosition.dx) / scale,
      (size.height - canvasPosition.dy) / scale,
    );

    final startX = (topLeftCanvas.dx / spacing).floor() * spacing;
    final endX = (bottomRightCanvas.dx / spacing).ceil() * spacing;
    final startY = (topLeftCanvas.dy / spacing).floor() * spacing;
    final endY = (bottomRightCanvas.dy / spacing).ceil() * spacing;

    final paint = Paint()
      ..color = config.color
      ..style = PaintingStyle.fill;

    final radius = config.dotRadiusCanvas * scale;
    if (radius <= 0) return;

    for (double x = startX; x <= endX; x += spacing) {
      for (double y = startY; y <= endY; y += spacing) {
        final screen = Offset(x * scale, y * scale) + canvasPosition;
        if (screen.dx < -radius ||
            screen.dy < -radius ||
            screen.dx > size.width + radius ||
            screen.dy > size.height + radius) {
          continue;
        }
        canvas.drawCircle(screen, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedGridPainter oldDelegate) {
    return oldDelegate.canvasPosition != canvasPosition ||
        oldDelegate.canvasScale != canvasScale ||
        oldDelegate.config != config;
  }
}
