import 'package:flexi_editor/src/canvas_context/canvas_state.dart';
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

  Offset fromCanvasCoordinates(Offset position) {
    return canvasState.fromCanvasCoordinates(position);
  }

  Offset toCanvasCoordinates(Offset position) {
    return canvasState.toCanvasCoordinates(position);
  }

  double toCanvasSize(double size) {
    return canvasState.toCanvasSize(size);
  }
}
