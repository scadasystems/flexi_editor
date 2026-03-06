import 'dart:math' as math;

import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'editor_controller.dart';
import 'editor_models.dart';

part 'policy/resize_handle.dart';
part 'policy/rotate_handle.dart';
part 'policy/selection_overlay.dart';

class ExamplePolicySet extends PolicySet
    with
        CanvasControlPolicy,
        LinkControlPolicy,
        LinkJointControlPolicy,
        LinkAttachmentRectPolicy {
  final EditorController controller;

  ExamplePolicySet({required this.controller});

  @override
  void initializeEditor() {
    canvasWriter.state.setCanvasColor(const Color(0xFFF7F7F8));
    canvasWriter.state.setMinScale(0.1);
    canvasWriter.state.setMaxScale(8);
  }

  @override
  void onCanvasTap() {
    controller.clearPendingConnector();
    if (controller.tool == EditorTool.select) {
      controller.clearSelection();
    }
  }

  @override
  void onComponentTap(String componentId) {
    final tool = controller.tool;

    if (tool == EditorTool.connector) {
      final sourceId = controller.pendingConnectorSourceComponentId;
      if (sourceId == null) {
        controller
          ..setPendingConnectorSource(componentId)
          ..selectSingleComponent(componentId);
        return;
      }

      if (sourceId == componentId) {
        controller.clearPendingConnector();
        return;
      }

      final linkId = canvasWriter.model.connectTwoComponents(
        sourceComponentId: sourceId,
        targetComponentId: componentId,
        linkStyle: LinkStyle(color: const Color(0xFF6B7280), lineWidth: 2),
      );
      controller
        ..clearPendingConnector()
        ..selectLink(linkId);
      return;
    }

    if (tool == EditorTool.select) {
      controller.selectSingleComponent(componentId);
    }
  }

  @override
  void onComponentScaleUpdate(String componentId, ScaleUpdateDetails details) {
    if (controller.tool != EditorTool.select) return;
    if (details.focalPointDelta == Offset.zero) return;
    canvasWriter.model.moveComponentWithChildren(
      componentId,
      details.focalPointDelta,
    );
  }

  @override
  void onLinkTap(String linkId) {
    if (controller.tool != EditorTool.select) return;
    controller.selectLink(linkId);
  }

  @override
  Widget? showComponentBody(Component componentData) {
    final data = componentData.data;

    final shapeData = data is EditorShapeData
        ? data
        : const EditorShapeData(
            fillColorValue: 0xFFFFFFFF,
            strokeColorValue: 0xFF111827,
            strokeWidth: 1,
            cornerRadius: 8,
            rotationRadians: 0,
          );

    final isOval = componentData.subtype == 'oval';

    return Transform.rotate(
      angle: shapeData.rotationRadians,
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: shapeData.fillColor,
          border: Border.all(
            color: shapeData.strokeColor,
            width: shapeData.strokeWidth,
          ),
          borderRadius: isOval ? null : .circular(shapeData.cornerRadius),
          shape: isOval ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }

  @override
  Widget buildComponentOverWidget(
    BuildContext context,
    Component componentData,
  ) {
    return _ComponentSelectionOverlay(
      policy: this,
      componentData: componentData,
    );
  }
}
