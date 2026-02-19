import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

mixin CustomComponentControlPolicy on PolicySet {
  Offset _lastFocalPoint = Offset.zero;

  @override
  void onComponentTapDown(String componentId, TapDownDetails details) {
    super.onComponentTapDown(componentId, details);

    if (canvasReader.state.isComponentSelected(componentId)) {
      canvasWriter.state.deselectComponent(componentId);
    } else {
      canvasWriter.state.selectComponent(componentId);
    }
  }

  @override
  void onComponentScaleStart(
    String componentId,
    ScaleStartDetails details, {
    bool forceMove = false,
  }) {
    _lastFocalPoint = details.focalPoint;
  }

  @override
  void onComponentScaleUpdate(String componentId, ScaleUpdateDetails details) {
    final delta = details.focalPoint - _lastFocalPoint;
    _lastFocalPoint = details.focalPoint;

    // 선택된 컴포넌트가 이동 대상이면 함께 이동
    if (canvasReader.state.isComponentSelected(componentId)) {
      for (final id in canvasReader.state.selectedComponentIds) {
        canvasWriter.model.moveComponentWithChildren(id, delta);
      }
    } else {
      // 선택되지 않은 컴포넌트를 드래그하면 해당 컴포넌트만 이동
      canvasWriter.model.moveComponentWithChildren(componentId, delta);
    }
  }
}
