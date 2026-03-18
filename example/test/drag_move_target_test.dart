import 'package:example/editor/editor_controller.dart';
import 'package:example/editor/editor_models.dart';
import 'package:example/editor/example_policy_set.dart';
import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Screen 선택 상태에서 자식 id로 드래그하면 자식이 이동한다', () {
    final controller = EditorController();
    final undoRedoController = CanvasUndoRedoController();
    final policy = ExamplePolicySet(
      controller: controller,
      undoRedoController: undoRedoController,
    );
    FlexiEditorContext(policy);

    policy.canvasWriter.state.setDottedBackground(
      const CanvasDottedBackgroundConfig(enabled: false),
    );

    final parentId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'parent',
        type: 'screen',
        position: const Offset(80, 80),
        size: const Size(200, 200),
      ),
    );
    final childId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'child',
        type: 'rectangle',
        position: const Offset(10, 10),
        size: const Size(50, 50),
      ),
    );
    policy.canvasWriter.model.attachChild(
      parentId,
      childId,
      preserveWorldPosition: false,
    );

    controller.selectSingleComponent(parentId);

    policy.onComponentScaleUpdate(
      childId,
      ScaleUpdateDetails(focalPointDelta: const Offset(20, 0), pointerCount: 1),
    );

    expect(
      policy.canvasReader.model.getComponent(parentId).position,
      const Offset(80, 80),
    );
    expect(
      policy.canvasReader.model.getComponent(childId).position,
      const Offset(30, 10),
    );
  });

  test('자식 선택 상태에서 자식 id로 드래그하면 자식이 이동한다', () {
    final controller = EditorController();
    final undoRedoController = CanvasUndoRedoController();
    final policy = ExamplePolicySet(
      controller: controller,
      undoRedoController: undoRedoController,
    );
    FlexiEditorContext(policy);

    policy.canvasWriter.state.setDottedBackground(
      const CanvasDottedBackgroundConfig(enabled: false),
    );

    final parentId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'parent',
        type: 'screen',
        position: const Offset(80, 80),
        size: const Size(200, 200),
      ),
    );
    final childId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'child',
        type: 'rectangle',
        position: const Offset(10, 10),
        size: const Size(50, 50),
      ),
    );
    policy.canvasWriter.model.attachChild(
      parentId,
      childId,
      preserveWorldPosition: false,
    );

    controller.selectSingleComponent(childId);

    policy.onComponentScaleUpdate(
      childId,
      ScaleUpdateDetails(focalPointDelta: const Offset(20, 0), pointerCount: 1),
    );

    expect(
      policy.canvasReader.model.getComponent(parentId).position,
      const Offset(80, 80),
    );
    expect(
      policy.canvasReader.model.getComponent(childId).position,
      const Offset(30, 10),
    );
  });

  test('선택 없음에서 자식 id로 드래그 시작하면 자식이 선택되고 이동한다', () {
    final controller = EditorController();
    final undoRedoController = CanvasUndoRedoController();
    final policy = ExamplePolicySet(
      controller: controller,
      undoRedoController: undoRedoController,
    );
    FlexiEditorContext(policy);

    policy.canvasWriter.state.setDottedBackground(
      const CanvasDottedBackgroundConfig(enabled: false),
    );

    final screenId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'screen',
        type: 'screen',
        position: const Offset(80, 80),
        size: const Size(200, 200),
      ),
    );
    final childId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'child',
        type: 'rectangle',
        position: const Offset(10, 10),
        size: const Size(50, 50),
      ),
    );
    policy.canvasWriter.model.attachChild(
      screenId,
      childId,
      preserveWorldPosition: false,
    );

    expect(controller.selectedComponentIds, isEmpty);

    policy.onComponentScaleStart(childId, ScaleStartDetails());
    policy.onComponentScaleUpdate(
      childId,
      ScaleUpdateDetails(focalPointDelta: const Offset(20, 0), pointerCount: 1),
    );

    expect(controller.selectedComponentIds, {childId});
    expect(
      policy.canvasReader.model.getComponent(screenId).position,
      const Offset(80, 80),
    );
    expect(
      policy.canvasReader.model.getComponent(childId).position,
      const Offset(30, 10),
    );
  });

  test('중첩 Screen에서 선택 없음 드래그는 자식 컴포넌트가 이동한다', () {
    final controller = EditorController();
    final undoRedoController = CanvasUndoRedoController();
    final policy = ExamplePolicySet(
      controller: controller,
      undoRedoController: undoRedoController,
    );
    FlexiEditorContext(policy);

    policy.canvasWriter.state.setDottedBackground(
      const CanvasDottedBackgroundConfig(enabled: false),
    );

    final outerScreenId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'outer',
        type: 'screen',
        position: const Offset(80, 80),
        size: const Size(400, 400),
      ),
    );
    final innerScreenId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'inner',
        type: 'screen',
        position: const Offset(20, 20),
        size: const Size(200, 200),
      ),
    );
    policy.canvasWriter.model.attachChild(
      outerScreenId,
      innerScreenId,
      preserveWorldPosition: false,
    );

    final shapeId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'shape',
        type: 'rectangle',
        position: const Offset(5, 5),
        size: const Size(50, 50),
      ),
    );
    policy.canvasWriter.model.attachChild(
      innerScreenId,
      shapeId,
      preserveWorldPosition: false,
    );

    expect(controller.selectedComponentIds, isEmpty);

    policy.onComponentScaleStart(shapeId, ScaleStartDetails());
    policy.onComponentScaleUpdate(
      shapeId,
      ScaleUpdateDetails(focalPointDelta: const Offset(10, 0), pointerCount: 1),
    );

    expect(controller.selectedComponentIds, {shapeId});
    expect(
      policy.canvasReader.model.getComponent(outerScreenId).position,
      const Offset(80, 80),
    );
    expect(
      policy.canvasReader.model.getComponent(innerScreenId).position,
      const Offset(20, 20),
    );
    expect(
      policy.canvasReader.model.getComponent(shapeId).position,
      const Offset(15, 5),
    );
  });

  test('선택 없음에서 자식 없는 Screen 드래그 시작/이동은 Screen을 선택하고 이동한다', () {
    final controller = EditorController();
    final undoRedoController = CanvasUndoRedoController();
    final policy = ExamplePolicySet(
      controller: controller,
      undoRedoController: undoRedoController,
    );
    FlexiEditorContext(policy);

    policy.canvasWriter.state.setDottedBackground(
      const CanvasDottedBackgroundConfig(enabled: false),
    );

    final screenId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'screen',
        type: 'screen',
        position: const Offset(80, 80),
        size: const Size(200, 200),
      ),
    );

    expect(controller.selectedComponentIds, isEmpty);

    policy.onComponentScaleStart(screenId, ScaleStartDetails());
    policy.onComponentScaleUpdate(
      screenId,
      ScaleUpdateDetails(focalPointDelta: const Offset(20, 0), pointerCount: 1),
    );

    expect(controller.selectedComponentIds, {screenId});
    expect(
      policy.canvasReader.model.getComponent(screenId).position,
      const Offset(100, 80),
    );
  });

  test('forceMove=true로 자식 있는 Screen 드래그 시작/이동은 Screen을 선택하고 이동한다', () {
    final controller = EditorController();
    final undoRedoController = CanvasUndoRedoController();
    final policy = ExamplePolicySet(
      controller: controller,
      undoRedoController: undoRedoController,
    );
    FlexiEditorContext(policy);

    policy.canvasWriter.state.setDottedBackground(
      const CanvasDottedBackgroundConfig(enabled: false),
    );

    final screenId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'screen',
        type: 'screen',
        position: const Offset(80, 80),
        size: const Size(200, 200),
      ),
    );
    final childId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'child',
        type: 'rectangle',
        position: const Offset(10, 10),
        size: const Size(50, 50),
      ),
    );
    policy.canvasWriter.model.attachChild(
      screenId,
      childId,
      preserveWorldPosition: false,
    );

    expect(controller.selectedComponentIds, isEmpty);
    final beforeChildWorld = policy.canvasReader.model.getComponentWorldPosition(childId);

    policy.onComponentScaleStart(screenId, ScaleStartDetails(), forceMove: true);
    policy.onComponentScaleUpdate(
      screenId,
      ScaleUpdateDetails(focalPointDelta: const Offset(20, 0), pointerCount: 1),
    );

    expect(controller.selectedComponentIds, {screenId});
    expect(
      policy.canvasReader.model.getComponent(screenId).position,
      const Offset(100, 80),
    );
    expect(
      policy.canvasReader.model.getComponent(childId).position,
      const Offset(10, 10),
    );
    expect(
      policy.canvasReader.model.getComponentWorldPosition(childId),
      beforeChildWorld + const Offset(20, 0),
    );
  });

  test('선택 없음에서 자식 있는 Screen 드래그 시작/이동은 Screen을 움직이지 않는다', () {
    final controller = EditorController();
    final undoRedoController = CanvasUndoRedoController();
    final policy = ExamplePolicySet(
      controller: controller,
      undoRedoController: undoRedoController,
    );
    FlexiEditorContext(policy);

    policy.canvasWriter.state.setDottedBackground(
      const CanvasDottedBackgroundConfig(enabled: false),
    );

    final screenId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'screen',
        type: 'screen',
        position: const Offset(80, 80),
        size: const Size(200, 200),
      ),
    );
    final childId = policy.canvasWriter.model.addComponent(
      Component<EditorShapeData>(
        id: 'child',
        type: 'rectangle',
        position: const Offset(10, 10),
        size: const Size(50, 50),
      ),
    );
    policy.canvasWriter.model.attachChild(
      screenId,
      childId,
      preserveWorldPosition: false,
    );

    expect(controller.selectedComponentIds, isEmpty);

    policy.onComponentScaleStart(screenId, ScaleStartDetails());
    policy.onComponentScaleUpdate(
      screenId,
      ScaleUpdateDetails(focalPointDelta: const Offset(20, 0), pointerCount: 1),
    );

    expect(controller.selectedComponentIds, isEmpty);
    expect(
      policy.canvasReader.model.getComponent(screenId).position,
      const Offset(80, 80),
    );
  });
}
