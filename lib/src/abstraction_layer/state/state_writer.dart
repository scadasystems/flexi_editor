import 'package:flexi_editor/src/canvas_context/canvas_state.dart';
import 'package:flexi_editor/src/canvas_context/canvas_dotted_background_config.dart';
import 'package:flutter/material.dart';

class CanvasStateWriter {
  final CanvasState _canvasState;

  /// Allows you to change the state of the canvas.
  CanvasStateWriter(this._canvasState);

  /// Updates everything on canvas.
  ///
  /// It should be used as little as possible, it demands a lot of performance.
  /// Use only in case that something on canvas is not updated.
  /// It calls [notifyListeners] function of [ChangeNotifier].
  void updateCanvas() {
    _canvasState.updateCanvas();
  }

  /// Sets the position of the canvas to [position] value.
  void setPosition(Offset position) {
    _canvasState.setPosition(position);
  }

  /// Sets the scale of the canvas to [scale] value.
  ///
  /// Scale value should be positive.
  void setScale(double scale) {
    assert(scale > 0);
    _canvasState.setScale(scale);
  }

  /// Translates the canvas by [offset].
  void updatePosition(Offset offset) {
    _canvasState.updatePosition(offset);
  }

  /// Multiplies the scale of the canvas by [scale].
  void updateScale(double scale) {
    _canvasState.updateScale(scale);
  }

  /// Sets the position of the canvas to (0, 0) and scale to 1.
  void resetCanvasView() {
    _canvasState.resetCanvasView();
  }

  /// Sets the base color of the canvas.
  void setCanvasColor(Color color) {
    _canvasState.color = color;
  }

  /// 도트 배경 설정을 통째로 [config]로 교체합니다.
  void setDottedBackground(CanvasDottedBackgroundConfig config) {
    _canvasState.dottedBackground = config;
    _canvasState.updateCanvas();
  }

  /// 도트 배경 활성화 여부를 [enabled]로 설정합니다.
  void setDottedBackgroundEnabled(bool enabled) {
    _canvasState.dottedBackground =
        _canvasState.dottedBackground.copyWith(enabled: enabled);
    _canvasState.updateCanvas();
  }

  /// Sets the maximal possible scale of the canvas.
  void setMaxScale(double scale) {
    _canvasState.maxScale = scale;
  }

  /// Sets the minimal possible scale of the canvas.
  void setMinScale(double scale) {
    _canvasState.minScale = scale;
  }
}
