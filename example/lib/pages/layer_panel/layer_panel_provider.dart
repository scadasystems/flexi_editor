import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';

import '../../editor/editor_controller.dart';
import '../../editor/example_editor_store.dart';

/// 레이어 패널에서 필요한 상태(확장/호버/드래그/이름 편집)를 관리합니다.
///
/// - 편집기 핵심 의존성은 [ExampleEditorStore]에서 주입받아 내부에서 사용합니다.
class LayerPanelProvider extends ChangeNotifier {
  /// 레이어 패널이 참조하는 편집기 컨텍스트입니다.
  final FlexiEditorContext editorContext;

  /// 레이어 패널의 변경사항을 undo/redo에 기록합니다.
  final CanvasUndoRedoController undoRedoController;

  /// 레이어 패널의 선택/도구 상태를 동기화합니다.
  final EditorController controller;

  final Set<String> expandedIds = {};
  String? hoveredExpandableId;
  String? hoveredRowId;
  String? lastSelectedId;
  String? draggingComponentId;
  String? dropTargetComponentId;
  bool dropTargetInsertAbove = true;

  String? editingComponentId;
  late final TextEditingController nameEditingController;
  late final FocusNode nameEditingFocusNode;

  /// 레이어 패널 동작에 필요한 편집기 의존성을 Store에서 가져옵니다.
  LayerPanelProvider({required ExampleEditorStore editor})
    : editorContext = editor.editorContext,
      undoRedoController = editor.undoRedoController,
      controller = editor.controller {
    controller.addListener(_onControllerSelectionChanged);
    nameEditingController = TextEditingController();
    nameEditingFocusNode = FocusNode();
    nameEditingFocusNode.addListener(() {
      if (nameEditingFocusNode.hasFocus) return;
      commitNameEdit(save: true);
    });
  }

  @override
  /// 생성한 리소스를 정리합니다.
  void dispose() {
    controller.removeListener(_onControllerSelectionChanged);
    nameEditingFocusNode.dispose();
    nameEditingController.dispose();
    super.dispose();
  }

  /// 캔버스 선택이 바뀌면, 해당 컴포넌트의 조상 노드를 자동으로 펼칩니다.
  void _onControllerSelectionChanged() {
    final selectedId = controller.selectedComponentIds.length == 1
        ? controller.selectedComponentIds.first
        : null;

    if (selectedId == lastSelectedId) return;
    lastSelectedId = selectedId;
    if (selectedId == null) return;

    final model = editorContext.canvasModel;
    if (!model.componentExists(selectedId)) return;

    final parentId = model.getComponent(selectedId).parentId;
    if (parentId == null) return;

    final ancestors = <String>[];
    String? currentParentId = parentId;
    while (currentParentId != null) {
      final id = currentParentId;
      if (!model.componentExists(id)) break;
      ancestors.add(id);
      currentParentId = model.getComponent(id).parentId;
    }

    final didChange = ancestors.any((id) => !expandedIds.contains(id));
    if (!didChange) return;
    expandedIds.addAll(ancestors);
    notifyListeners();
  }

  /// 특정 컴포넌트의 펼침/접힘 상태를 토글합니다.
  void toggleExpanded(String componentId) {
    if (!expandedIds.add(componentId)) {
      expandedIds.remove(componentId);
    }
    notifyListeners();
  }

  /// 자식이 존재해 패널에서 확장 가능한 컴포넌트 id 집합을 반환합니다.
  Set<String> expandableComponentIds() {
    final model = editorContext.canvasModel;
    final ids = <String>{};
    for (final component in model.components.values) {
      if (component.childrenIds.any(model.componentExists)) {
        ids.add(component.id);
      }
    }
    return ids;
  }

  /// 확장 가능한 모든 노드를 펼칩니다.
  void expandAll() {
    final expandableIds = expandableComponentIds();
    if (expandableIds.isEmpty) return;
    expandedIds.addAll(expandableIds);
    notifyListeners();
  }

  /// 펼친 모든 노드를 접습니다.
  void collapseAll() {
    if (expandedIds.isEmpty) return;
    expandedIds.clear();
    notifyListeners();
  }

  /// 확장 아이콘 호버 상태를 갱신합니다.
  void setHoveredExpandableId(String? id) {
    if (hoveredExpandableId == id) return;
    hoveredExpandableId = id;
    notifyListeners();
  }

  /// 행(row) 호버 상태를 갱신합니다.
  void setHoveredRowId(String? id) {
    if (hoveredRowId == id) return;
    hoveredRowId = id;
    notifyListeners();
  }

  /// 컴포넌트의 visible을 토글하고 필요한 선택/커넥터 상태를 정리합니다.
  void toggleComponentVisible(String componentId) {
    final model = editorContext.canvasModel;
    if (!model.componentExists(componentId)) return;
    final component = model.getComponent(componentId);
    final nextVisible = !component.visible;

    final writer = editorContext.policySet.canvasWriter.model;
    writer.setComponentVisible(componentId, nextVisible);
    undoRedoController.commit(reader: editorContext.policySet.canvasReader);

    if (!nextVisible) {
      if (controller.pendingConnectorSourceComponentId == componentId) {
        controller.clearPendingConnector();
      }

      if (controller.selectedComponentIds.contains(componentId)) {
        controller.setSelectedComponents(
          controller.selectedComponentIds.where((id) => id != componentId),
        );
      }

      final selectedLinkId = controller.selectedLinkId;
      if (selectedLinkId != null && model.linkExists(selectedLinkId)) {
        final link = model.getLink(selectedLinkId);
        if (link.sourceComponentId == componentId ||
            link.targetComponentId == componentId) {
          controller.clearSelection();
        }
      }
    }
  }

  /// 특정 Screen이 화면 중앙에 오도록 캔버스 뷰를 이동시킵니다.
  void focusScreen(String screenId) {
    final model = editorContext.canvasModel;
    if (!model.componentExists(screenId)) return;
    if (model.getComponent(screenId).type != 'screen') return;

    final renderObject = editorContext
        .canvasState
        .canvasGlobalKey
        .currentContext
        ?.findRenderObject();
    final box = renderObject is RenderBox ? renderObject : null;
    if (box == null || !box.hasSize) return;

    final viewportSize = box.size;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );

    final worldRect = model.getComponentWorldRect(screenId);
    final worldCenter = worldRect.center;
    final scale = editorContext.canvasState.scale;
    final position = viewportCenter - worldCenter * scale;

    final writer = editorContext.policySet.canvasWriter.state;
    writer.setPosition(position);
    writer.updateCanvas();
  }

  /// 드래그 세션 상태를 종료하고 필요 시 리스너에 알립니다.
  bool endDragSession({bool notify = true}) {
    final didChange =
        draggingComponentId != null ||
        dropTargetComponentId != null ||
        dropTargetInsertAbove != true;
    if (!didChange) return false;

    draggingComponentId = null;
    dropTargetComponentId = null;
    dropTargetInsertAbove = true;

    if (notify) {
      notifyListeners();
    }
    return true;
  }

  /// 레이어 패널 드래그 시작 상태를 기록합니다.
  void onDragStarted(String componentId) {
    final previousDraggingId = draggingComponentId;
    final previousDropTargetId = dropTargetComponentId;
    final previousInsertAbove = dropTargetInsertAbove;

    endDragSession(notify: false);
    draggingComponentId = componentId;

    if (previousDraggingId != draggingComponentId ||
        previousDropTargetId != dropTargetComponentId ||
        previousInsertAbove != dropTargetInsertAbove) {
      notifyListeners();
    }
  }

  /// 레이어 패널 드래그 세션을 종료합니다.
  void onDragEnded() {
    endDragSession();
  }

  /// 드롭 타겟 및 삽입 방향(위/아래)을 갱신합니다.
  void onDropMove({
    required String targetId,
    required bool insertAbove,
  }) {
    if (dropTargetComponentId == targetId &&
        dropTargetInsertAbove == insertAbove) {
      return;
    }
    dropTargetComponentId = targetId;
    dropTargetInsertAbove = insertAbove;
    notifyListeners();
  }

  /// 드롭 타겟에서 포인터가 떠난 경우 타겟 표시를 해제합니다.
  void onDropLeave(String targetId) {
    if (dropTargetComponentId != targetId) return;
    dropTargetComponentId = null;
    notifyListeners();
  }

  /// 현재 드롭 타겟 표시를 강제로 해제합니다.
  void clearDropTarget() {
    if (dropTargetComponentId == null) return;
    dropTargetComponentId = null;
    notifyListeners();
  }

  /// 특정 컴포넌트의 이름 편집 모드를 시작합니다.
  void startNameEdit(Component component) {
    controller.selectSingleComponent(component.id);
    editingComponentId = component.id;
    nameEditingController.text = component.name ?? '';
    nameEditingController.selection = TextSelection.collapsed(
      offset: nameEditingController.text.length,
    );
    notifyListeners();
  }

  /// 이름 편집을 종료하고 저장 옵션에 따라 모델에 반영합니다.
  void commitNameEdit({required bool save}) {
    final componentId = editingComponentId;
    if (componentId == null) return;

    editingComponentId = null;
    notifyListeners();

    if (!save) return;

    final model = editorContext.canvasModel;
    if (!model.componentExists(componentId)) return;

    final text = nameEditingController.text.trim();
    final nextName = text.isEmpty ? null : text;
    final currentName = model.getComponent(componentId).name?.trim();
    final currentNameNormalized = currentName == null || currentName.isEmpty
        ? null
        : currentName;
    if (nextName == currentNameNormalized) return;

    final writer = editorContext.policySet.canvasWriter.model;
    writer.setComponentName(componentId, nextName);
    undoRedoController.commit(reader: editorContext.policySet.canvasReader);
    controller.selectSingleComponent(componentId);
  }

  /// 드래그된 컴포넌트를 타겟 위치에 드롭할 수 있는지 판정합니다.
  bool isDropAllowed({
    required String draggedId,
    required String targetId,
  }) {
    final model = editorContext.canvasModel;
    if (!model.componentExists(draggedId)) return false;
    if (!model.componentExists(targetId)) return false;
    if (draggedId == targetId) return false;

    final dragged = model.getComponent(draggedId);
    final target = model.getComponent(targetId);

    if (dragged.type == 'screen') {
      return dragged.parentId == null && target.parentId == null;
    }

    if (dragged.parentId == target.parentId) return true;

    if (target.type != 'screen') return false;

    var currentId = target.id;
    while (true) {
      if (currentId == draggedId) return false;
      final current = model.getComponent(currentId);
      final parentId = current.parentId;
      if (parentId == null) break;
      if (!model.componentExists(parentId)) break;
      currentId = parentId;
    }

    return true;
  }

  /// 레이어 패널 표시에 맞춰, 주어진 parent 기준 형제들을 위→아래 순서로 정렬합니다.
  List<String> sortedSiblingIdsForPanel({required String? parentId}) {
    final model = editorContext.canvasModel;
    if (parentId == null) {
      final roots =
          model.components.values
              .where((c) => c.parentId == null)
              .toList(growable: false)
            ..sort((a, b) {
              final zCompare = b.zOrder.compareTo(a.zOrder);
              if (zCompare != 0) return zCompare;
              return b.id.compareTo(a.id);
            });
      return roots.map((c) => c.id).toList(growable: false);
    }

    if (!model.componentExists(parentId)) return const [];
    final parent = model.getComponent(parentId);
    final childOrderIndex = <String, int>{
      for (var i = 0; i < parent.childrenIds.length; i++)
        parent.childrenIds[i]: i,
    };
    final children =
        parent.childrenIds
            .where(model.componentExists)
            .map(model.getComponent)
            .toList(growable: false)
          ..sort((a, b) {
            final zCompare = b.zOrder.compareTo(a.zOrder);
            if (zCompare != 0) return zCompare;
            return (childOrderIndex[b.id] ?? 0).compareTo(
              childOrderIndex[a.id] ?? 0,
            );
          });
    return children.map((c) => c.id).toList(growable: false);
  }

  /// 동일 부모 내에서 드롭 위치에 맞게 zOrder를 재배치합니다.
  bool reorderWithinSameParent({
    required String draggedId,
    required String targetId,
    required bool insertAbove,
  }) {
    final model = editorContext.canvasModel;
    if (!model.componentExists(draggedId)) return false;
    if (!model.componentExists(targetId)) return false;

    final dragged = model.getComponent(draggedId);
    final target = model.getComponent(targetId);
    final parentId = dragged.parentId;
    if (parentId != target.parentId) return false;

    final orderedTopToBottom = sortedSiblingIdsForPanel(parentId: parentId);
    if (!orderedTopToBottom.contains(draggedId) ||
        !orderedTopToBottom.contains(targetId)) {
      return false;
    }

    final next = orderedTopToBottom.where((id) => id != draggedId).toList();
    var insertIndex = next.indexOf(targetId);
    if (!insertAbove) insertIndex += 1;
    if (insertIndex < 0) insertIndex = 0;
    if (insertIndex > next.length) insertIndex = next.length;
    next.insert(insertIndex, draggedId);
    if (next.length == orderedTopToBottom.length) {
      var same = true;
      for (var i = 0; i < next.length; i++) {
        if (next[i] != orderedTopToBottom[i]) {
          same = false;
          break;
        }
      }
      if (same) return false;
    }

    final siblings = parentId == null
        ? model.components.values.where((c) => c.parentId == null).toList()
        : model
              .getComponent(parentId)
              .childrenIds
              .where(model.componentExists)
              .map(model.getComponent)
              .toList();
    if (siblings.isEmpty) return false;

    var minZ = siblings.first.zOrder;
    for (final s in siblings) {
      if (s.zOrder < minZ) minZ = s.zOrder;
    }

    final writer = editorContext.policySet.canvasWriter.model;
    for (var i = 0; i < next.length; i++) {
      final id = next[next.length - 1 - i];
      writer.setComponentZOrder(id, minZ + i);
    }

    controller.selectSingleComponent(draggedId);
    undoRedoController.commit(reader: editorContext.policySet.canvasReader);
    return true;
  }

  /// 드래그된 컴포넌트를 특정 Screen의 자식으로 이동시키고 zOrder를 정리합니다.
  bool moveToScreen({
    required String draggedId,
    required String screenId,
    required bool insertAbove,
  }) {
    final model = editorContext.canvasModel;
    if (!model.componentExists(draggedId)) return false;
    if (!model.componentExists(screenId)) return false;

    final dragged = model.getComponent(draggedId);
    final screen = model.getComponent(screenId);
    if (screen.type != 'screen') return false;
    if (dragged.type == 'screen') return false;
    if (draggedId == screenId) return false;
    if (dragged.parentId == screenId) return false;

    final previousParentId = dragged.parentId;
    final previousParentScrollOffset =
        previousParentId != null && model.componentExists(previousParentId)
        ? model.getComponent(previousParentId).scrollOffset
        : Offset.zero;
    final draggedVisibleLocalPosition =
        dragged.position - previousParentScrollOffset;

    var currentId = screenId;
    while (true) {
      if (currentId == draggedId) return false;
      final current = model.getComponent(currentId);
      final parentId = current.parentId;
      if (parentId == null) break;
      if (!model.componentExists(parentId)) break;
      currentId = parentId;
    }

    final writer = editorContext.policySet.canvasWriter.model;
    writer.attachChild(screenId, draggedId, preserveWorldPosition: false);
    model
        .getComponent(draggedId)
        .setPosition(
          draggedVisibleLocalPosition + screen.scrollOffset,
        );
    writer.updateComponentLinks(draggedId);

    final orderedTopToBottom = sortedSiblingIdsForPanel(parentId: screenId);
    if (!orderedTopToBottom.contains(draggedId)) return false;

    final next = orderedTopToBottom.where((id) => id != draggedId).toList();
    final insertIndex = insertAbove ? 0 : next.length;
    next.insert(insertIndex, draggedId);

    if (next.isNotEmpty) {
      final siblings = model
          .getComponent(screenId)
          .childrenIds
          .where(model.componentExists)
          .map(model.getComponent)
          .toList();
      if (siblings.isEmpty) return false;

      var minZ = siblings.first.zOrder;
      for (final s in siblings) {
        if (s.zOrder < minZ) minZ = s.zOrder;
      }

      for (var i = 0; i < next.length; i++) {
        final id = next[next.length - 1 - i];
        writer.setComponentZOrder(id, minZ + i);
      }
    }

    controller.selectSingleComponent(draggedId);
    undoRedoController.commit(reader: editorContext.policySet.canvasReader);
    return true;
  }
}
