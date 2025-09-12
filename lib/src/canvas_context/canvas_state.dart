import 'package:flutter/material.dart';
import 'package:flexi_editor/src/canvas_context/model/component.dart';

class CanvasState with ChangeNotifier {
  Offset _position = const Offset(0, 0);
  double _scale = 1.0;

  double mouseScaleSpeed = 0.8;

  double maxScale = 8.0;
  double minScale = 0.1;

  Color color = Colors.white;

  GlobalKey canvasGlobalKey = GlobalKey();

  bool shouldAbsorbPointer = false;

  bool isInitialized = false;

  Offset get position => _position;

  double get scale => _scale;

  void updateCanvas() {
    notifyListeners();
  }

  void setPosition(Offset position) {
    _position = position;
  }

  void setScale(double scale) {
    _scale = scale;
  }

  void updatePosition(Offset offset) {
    _position += offset;
  }

  void updateScale(double scale) {
    _scale *= scale;
  }

  void resetCanvasView() {
    _position = const Offset(0, 0);
    _scale = 1.0;
    notifyListeners();
  }

  Offset fromCanvasCoordinates(Offset position) {
    return (position - this.position) / scale;
  }

  Offset toCanvasCoordinates(Offset position) {
    return position * scale + this.position;
  }

  double toCanvasSize(double size) {
    return size * scale;
  }

  /// 모든 컴포넌트의 경계를 계산합니다.
  /// [components]: 컴포넌트 리스트
  /// 컴포넌트가 없거나 빈 경우 Rect.zero를 반환합니다.
  Rect calculateComponentsBounds(List<Component> components) {
    if (components.isEmpty) {
      return Rect.zero;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final component in components) {
      final left = component.position.dx;
      final top = component.position.dy;
      final right = left + component.size.width;
      final bottom = top + component.size.height;

      if (left < minX) minX = left;
      if (top < minY) minY = top;
      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 컴포넌트 리스트를 받아서 자동으로 경계를 계산하고 뷰에 맞춥니다.
  /// [components]: 컴포넌트 리스트
  /// [viewportSize]: 현재 뷰포트 크기
  /// [padding]: 경계 주변 여백 (기본값: 50)
  void fitAllComponentsToView(List<Component> components, Size viewportSize,
      {double padding = 50.0}) {
    if (components.isEmpty || viewportSize.isEmpty) {
      return;
    }

    final bounds = calculateComponentsBounds(components);
    if (bounds.isEmpty || bounds == Rect.zero) {
      return;
    }

    fitToView(bounds, viewportSize, padding: padding);
  }

  /// 모든 컴포넌트가 뷰포트에 맞게 스케일과 위치를 조정합니다.
  /// [bounds]: 모든 컴포넌트를 포함하는 경계 사각형
  /// [viewportSize]: 현재 뷰포트 크기
  /// [padding]: 경계 주변 여백 (기본값: 50)
  void fitToView(Rect bounds, Size viewportSize, {double padding = 50.0}) {
    if (bounds.isEmpty || viewportSize.isEmpty) {
      return;
    }

    // 패딩을 고려한 실제 사용 가능한 뷰포트 크기
    final availableWidth = viewportSize.width - (padding * 2);
    final availableHeight = viewportSize.height - (padding * 2);

    // 컴포넌트들의 경계를 뷰포트에 맞추기 위한 스케일 계산
    final scaleX = availableWidth / bounds.width;
    final scaleY = availableHeight / bounds.height;
    final targetScale =
        (scaleX < scaleY ? scaleX : scaleY).clamp(minScale, maxScale);

    // 스케일된 컴포넌트 경계의 중심을 뷰포트 중심으로 맞추기 위한 위치 계산
    final scaledBounds = Rect.fromLTWH(
      bounds.left * targetScale,
      bounds.top * targetScale,
      bounds.width * targetScale,
      bounds.height * targetScale,
    );

    final viewportCenter =
        Offset(viewportSize.width / 2, viewportSize.height / 2);
    final boundsCenter = scaledBounds.center;
    final targetPosition = viewportCenter - boundsCenter;

    _scale = targetScale;
    _position = targetPosition;
    notifyListeners();
  }
}
