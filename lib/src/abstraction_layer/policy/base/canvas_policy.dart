import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flutter/gestures.dart';

mixin CanvasPolicy on BasePolicySet {
  void onCanvasTap() {}

  void onCanvasTapDown(TapDownDetails details) {}

  void onCanvasTapUp(TapUpDetails details) {}

  void onCanvasTapCancel() {}

  void onCanvasScaleStart(ScaleStartDetails details) {}

  void onCanvasScaleUpdate(ScaleUpdateDetails details) {}

  void onCanvasScaleEnd(ScaleEndDetails details) {}

  void onCanvasScaleStartEvent(ScaleStartDetails details) {}

  void onCanvasScaleUpdateEvent(ScaleUpdateDetails details) {}

  void onCanvasScaleEndEvent(ScaleEndDetails details) {}

  void onCanvasPointerSignal(PointerSignalEvent event) {}

  bool get showLinksOnTopOfComponents => true;
}
