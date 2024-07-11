import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flutter/gestures.dart';

mixin ComponentPolicy on BasePolicySet {
  void onComponentEnter(String componentId) {}

  void onComponentExit(String componentId) {}

  void onComponentTap(String componentId) {}

  void onComponentTapDown(String componentId, TapDownDetails details) {}

  void onComponentTapUp(String componentId, TapUpDetails details) {}

  void onComponentTapCancel(String componentId) {}

  void onComponentScaleStart(String componentId, ScaleStartDetails details, {bool forceMove = false}) {}

  void onComponentScaleUpdate(String componentId, ScaleUpdateDetails details) {}

  void onComponentScaleEnd(String componentId, ScaleEndDetails details) {}

  void onComponentLongPress(String componentId) {}

  void onComponentLongPressStart(String componentId, LongPressStartDetails details) {}

  void onComponentLongPressMoveUpdate(String componentId, LongPressMoveUpdateDetails details) {}

  void onComponentLongPressEnd(String componentId, LongPressEndDetails details) {}

  void onComponentLongPressUp(String componentId) {}

  void onComponentPointerSignal(String componentId, PointerSignalEvent event) {}
}
