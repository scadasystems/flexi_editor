import 'package:flexi_editor/src/canvas_context/canvas_state.dart';
import 'package:flexi_editor/src/canvas_context/model/component.dart';
import 'package:flutter/material.dart';

class CanvasStateReader {
  final CanvasState canvasState;

  CanvasStateReader(this.canvasState);

  Offset get position => canvasState.position;

  double get scale => canvasState.scale;

  double get mouseScaleSpeed => canvasState.mouseScaleSpeed;

  double get maxScale => canvasState.maxScale;

  double get minScale => canvasState.minScale;

  Color get color => canvasState.color;

  Offset fromCanvasCoordinates(Offset position) =>
      canvasState.fromCanvasCoordinates(position);

  Offset toCanvasCoordinates(Offset position) =>
      canvasState.toCanvasCoordinates(position);

  double toCanvasSize(double size) => canvasState.toCanvasSize(size);

  /// 모든 컴포넌트의 경계를 계산합니다.
  Rect calculateComponentsBounds(List<Component> components) =>
      canvasState.calculateComponentsBounds(components);

  bool isComponentSelected(String id) => canvasState.isComponentSelected(id);

  Set<String> get selectedComponentIds => canvasState.selectedComponentIds;

  GlobalKey get canvasGlobalKey => canvasState.canvasGlobalKey;

  String? get hoveredPortId => canvasState.hoveredPortId;
}
