import 'package:example/editor/editor_controller.dart';
import 'package:example/editor/editor_models.dart';
import 'package:example/editor/example_policy_set.dart';
import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('겹치는 자식 동률 zOrder에서 더블탭은 나중 자식을 선택한다', () {
    final controller = EditorController();
    final undoRedoController = CanvasUndoRedoController();
    final policy = ExamplePolicySet(
      controller: controller,
      undoRedoController: undoRedoController,
    );
    FlexiEditorContext(policy);

    final parentId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'parent',
        type: 'screen',
        position: Offset.zero,
        size: const Size(200, 200),
      ),
    );

    final firstChildId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'child_a',
        type: 'rectangle',
        position: const Offset(10, 10),
        size: const Size(100, 100),
        zOrder: 0,
      ),
    );
    policy.canvasWriter.model.attachChild(
      parentId,
      firstChildId,
      preserveWorldPosition: false,
    );

    final secondChildId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'child_b',
        type: 'rectangle',
        position: const Offset(10, 10),
        size: const Size(100, 100),
        zOrder: 0,
      ),
    );
    policy.canvasWriter.model.attachChild(
      parentId,
      secondChildId,
      preserveWorldPosition: false,
    );

    expect(policy.canvasReader.model.getComponent(parentId).childrenIds, [
      firstChildId,
      secondChildId,
    ]);

    policy.onComponentDoubleTapDown(
      parentId,
      TapDownDetails(localPosition: const Offset(20, 20)),
    );

    expect(controller.selectedComponentIds, {secondChildId});
  });
}

