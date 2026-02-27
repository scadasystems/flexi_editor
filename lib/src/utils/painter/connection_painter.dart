import 'package:flexi_editor/src/canvas_context/model/component.dart';
import 'package:flexi_editor/src/canvas_context/model/connection.dart';
import 'package:flexi_editor/src/canvas_context/model/port_type.dart';
import 'package:flexi_editor/src/utils/router/orthogonal_path_finder.dart';
import 'package:flutter/material.dart';

class ConnectionPainter extends CustomPainter {
  final List<Connection> connections;
  final Map<String, Component> components;
  final Offset? dragStart;
  final Offset? dragEnd;
  final String? dragSourceComponentId;
  final PortType? dragSourcePort;
  final String? snappedPortComponentId;
  final PortType? snappedPortType;
  final double scale;
  final Offset offset;

  static const double viaDistance = 20.0;

  ConnectionPainter({
    required this.connections,
    required this.components,
    this.dragStart,
    this.dragEnd,
    this.dragSourceComponentId,
    this.dragSourcePort,
    this.snappedPortComponentId,
    this.snappedPortType,
    this.scale = 1.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 캔버스 스케일 및 오프셋 적용
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scale; // 스케일에 반비례하여 두께 조절

    final Paint dragPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scale
      ..strokeCap = StrokeCap.round;

    // 1. 완료된 연결 그리기
    for (final connection in connections) {
      final source = components[connection.sourceComponentId];
      final target = components[connection.targetComponentId];

      if (source == null || target == null) continue;

      final startPos = source.getPortPosition(connection.sourcePort);
      final endPos = target.getPortPosition(connection.targetPort);

      final fullPath = _calculatePath(
        startPos: startPos,
        startPort: connection.sourcePort,
        endPos: endPos,
        targetPort: connection.targetPort,
        sourceComponentId: connection.sourceComponentId,
        targetComponentId: connection.targetComponentId,
      );

      _drawPath(canvas, fullPath, paint);
    }

    // 2. 드래그 중인 연결 그리기
    if (dragStart != null &&
        dragEnd != null &&
        dragSourcePort != null &&
        dragSourceComponentId != null) {
      List<Offset> fullPath;

      if (snappedPortComponentId != null && snappedPortType != null) {
        // 스냅된 경우: 타겟 포트 위치를 직접 계산하여 완료된 연결과 동일한 방식으로 처리
        final targetComponent = components[snappedPortComponentId];
        if (targetComponent != null) {
          final targetPos = targetComponent.getPortPosition(snappedPortType!);
          
          fullPath = _calculatePath(
            startPos: dragStart!,
            startPort: dragSourcePort!,
            endPos: targetPos,
            targetPort: snappedPortType,
            sourceComponentId: dragSourceComponentId!,
            targetComponentId: snappedPortComponentId,
          );
        } else {
          // 타겟 컴포넌트를 찾을 수 없는 경우 (예외 처리)
          fullPath = _calculatePath(
            startPos: dragStart!,
            startPort: dragSourcePort!,
            endPos: dragEnd!,
            targetPort: null,
            sourceComponentId: dragSourceComponentId!,
            targetComponentId: null,
          );
        }
      } else {
        // 스냅되지 않은 경우: 마우스 위치로 연결
        fullPath = _calculatePath(
          startPos: dragStart!,
          startPort: dragSourcePort!,
          endPos: dragEnd!,
          targetPort: null,
          sourceComponentId: dragSourceComponentId!,
          targetComponentId: null,
        );
      }

      _drawPath(canvas, fullPath, dragPaint);
    }

    canvas.restore();
  }

  /// 경로 계산 공통 메서드
  List<Offset> _calculatePath({
    required Offset startPos,
    required PortType startPort,
    required Offset endPos,
    PortType? targetPort,
    required String sourceComponentId,
    String? targetComponentId,
  }) {
    // 장애물 리스트 생성
    final List<Rect> obstacles = [];
    for (final component in components.values) {
      // 시작 컴포넌트와 도착 컴포넌트(있는 경우)는 장애물에서 제외
      if (component.id == sourceComponentId ||
          component.id == targetComponentId) {
        continue;
      }

      obstacles.add(
        Rect.fromLTWH(
          component.position.dx,
          component.position.dy,
          component.size.width,
          component.size.height,
        ),
      );
    }

    // 시작점 ViaPoint 계산
    final viaStart = _getViaPoint(startPos, startPort);

    // 도착점 ViaPoint 계산 (targetPort가 있는 경우)
    Offset viaEnd = endPos;
    if (targetPort != null) {
      viaEnd = _getViaPoint(endPos, targetPort);
    }

    // 경로 탐색
    final pathPoints = OrthogonalPathFinder.findPath(
      viaStart,
      viaEnd,
      obstacles,
    );

    // 전체 경로 구성: [시작점, ...경로점, 끝점]
    return [startPos, ...pathPoints, endPos];
  }

  Offset _getViaPoint(Offset pos, PortType portType) {
    switch (portType) {
      case PortType.top:
        return pos + const Offset(0, -viaDistance);
      case PortType.bottom:
        return pos + const Offset(0, viaDistance);
      case PortType.left:
        return pos + const Offset(-viaDistance, 0);
      case PortType.right:
        return pos + const Offset(viaDistance, 0);
    }
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    final Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return true; // 항상 다시 그림 (애니메이션, 드래그 등)
  }
}
