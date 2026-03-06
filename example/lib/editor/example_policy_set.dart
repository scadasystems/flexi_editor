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
  final CanvasUndoRedoController undoRedoController;

  ExamplePolicySet({
    required this.controller,
    required this.undoRedoController,
  });

  @override
  void initializeEditor() {
    canvasWriter.state.setCanvasColor(const Color(0xFFF7F7F8));
    canvasWriter.state.setDottedBackground(
      const CanvasDottedBackgroundConfig(enabled: true, snapThresholdCanvas: 4),
    );
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
      undoRedoController.commit(reader: canvasReader);
      return;
    }

    if (tool == EditorTool.select) {
      controller.selectSingleComponent(componentId);
    }
  }

  @override
  void onComponentScaleUpdate(String componentId, ScaleUpdateDetails details) {
    if (controller.tool != EditorTool.select) return;
    final deltaScreen = details.focalPointDelta;
    if (deltaScreen == Offset.zero) return;

    final state = canvasReader.state;
    final dotted = state.dottedBackground;
    if (!dotted.enabled || dotted.gridSpacingCanvas <= 0) {
      canvasWriter.model.moveComponentWithChildren(componentId, deltaScreen);
      return;
    }

    final component = canvasReader.model.getComponent(componentId);
    final currentPos = component.position;
    final scale = state.scale;
    if (scale <= 0) return;

    final deltaCanvas = Offset(deltaScreen.dx / scale, deltaScreen.dy / scale);
    final candidate = currentPos + deltaCanvas;

    final spacing = dotted.gridSpacingCanvas;
    final snapped = Offset(
      (candidate.dx / spacing).round() * spacing,
      (candidate.dy / spacing).round() * spacing,
    );

    final target = (candidate - snapped).distance <= dotted.snapThresholdCanvas
        ? snapped
        : candidate;

    final finalDeltaCanvas = target - currentPos;
    final finalDeltaScreen = finalDeltaCanvas * scale;
    canvasWriter.model.moveComponentWithChildren(componentId, finalDeltaScreen);
  }

  @override
  void onComponentScaleEnd(String componentId, ScaleEndDetails details) {
    if (controller.tool != EditorTool.select) return;
    undoRedoController.commit(reader: canvasReader);
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
