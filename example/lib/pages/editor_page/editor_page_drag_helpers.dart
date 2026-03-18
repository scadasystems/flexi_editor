part of '../editor_page.dart';

/// 에디터 페이지의 드래그/선택/도형 드래프트 생성 관련 헬퍼 로직 모음입니다.
mixin _EditorPageDragHelpers on State<EditorPage> {
  /// 에디터 입력/선택 상태를 제어하는 컨트롤러입니다.
  EditorController get _controller;

  /// 캔버스 모델/상태/이벤트/정책이 포함된 컨텍스트입니다.
  FlexiEditorContext get _editorContext;

  /// 캔버스 변경사항의 undo/redo 스택을 관리합니다.
  CanvasUndoRedoController get _undoRedoController;

  final Map<String, bool> _componentLockedBackup = {};

  String? _draftComponentId;
  String? _draftParentId;
  Rect? _lastDragRect;
  Set<String>? _selectionBeforeDraftShape;
  String? _selectedLinkBeforeDraftShape;

  /// 컨트롤러 변경 시 현재 도구에 맞춰 제스처 정책을 재적용합니다.
  void _onControllerChanged() {
    _applyComponentGesturePolicy();
  }

  /// 도형 드래프트를 시작하기 전 선택 상태를 백업합니다.
  void _backupSelectionBeforeDraftShapeIfNeeded() {
    if (_selectionBeforeDraftShape != null ||
        _selectedLinkBeforeDraftShape != null) {
      return;
    }

    if (_controller.selectedComponentIds.isEmpty &&
        _controller.selectedLinkId == null) {
      return;
    }

    _selectionBeforeDraftShape = _controller.selectedComponentIds.toSet();
    _selectedLinkBeforeDraftShape = _controller.selectedLinkId;
  }

  /// 드래프트가 취소되는 경우 백업했던 선택 상태를 복원합니다.
  void _restoreSelectionBeforeDraftShapeIfNeeded() {
    final componentIds = _selectionBeforeDraftShape;
    final linkId = _selectedLinkBeforeDraftShape;

    _selectionBeforeDraftShape = null;
    _selectedLinkBeforeDraftShape = null;

    if (linkId != null) {
      _controller.selectLink(linkId);
      return;
    }

    if (componentIds != null && componentIds.isNotEmpty) {
      _controller.setSelectedComponents(componentIds);
    }
  }

  /// 현재 도구에 따라 컴포넌트 잠금 정책을 적용/해제합니다.
  void _applyComponentGesturePolicy() {
    final tool = _controller.tool;
    final shouldLockComponents =
        tool == EditorTool.rectangle || tool == EditorTool.oval;

    if (shouldLockComponents) {
      for (final component in _editorContext.canvasModel.components.values) {
        _componentLockedBackup.putIfAbsent(
          component.id,
          () => component.locked,
        );
        if (!component.locked) {
          component.setLocked(true);
        }
      }
      return;
    }

    if (_componentLockedBackup.isEmpty) return;
    for (final entry in _componentLockedBackup.entries) {
      if (!_editorContext.canvasModel.componentExists(entry.key)) continue;
      _editorContext.canvasModel.getComponent(entry.key).setLocked(entry.value);
    }
    _componentLockedBackup.clear();
  }

  /// 같은 부모(루트 또는 특정 부모) 내에서 가장 큰 zOrder를 계산합니다.
  int _maxSiblingZOrder({
    required String? parentId,
    String? excludeComponentId,
  }) {
    final model = _editorContext.canvasModel;

    Iterable<Component> siblings;
    if (parentId == null) {
      siblings = model.components.values.where((c) => c.parentId == null);
    } else if (model.componentExists(parentId)) {
      final parent = model.getComponent(parentId);
      siblings = parent.childrenIds
          .where(model.componentExists)
          .map(model.getComponent);
    } else {
      return -1;
    }

    var hasAny = false;
    var maxZ = 0;
    for (final s in siblings) {
      if (excludeComponentId != null && s.id == excludeComponentId) continue;
      if (!hasAny) {
        hasAny = true;
        maxZ = s.zOrder;
        continue;
      }
      if (s.zOrder > maxZ) maxZ = s.zOrder;
    }
    return hasAny ? maxZ : -1;
  }

  /// 새로 생성된 컴포넌트의 zOrder를 형제 중 최상단으로 맞춥니다.
  void _applyTopmostZOrderToNewComponent({
    required String componentId,
    required String? parentId,
  }) {
    if (!_editorContext.canvasModel.componentExists(componentId)) return;
    final maxZ = _maxSiblingZOrder(
      parentId: parentId,
      excludeComponentId: componentId,
    );
    _editorContext.policySet.canvasWriter.model.setComponentZOrder(
      componentId,
      maxZ + 1,
    );
  }

  /// 선택 사각형(드래그 선택/도형 생성) 시작 시 상태를 초기화합니다.
  void _onSelectionRectStart() {
    _lastDragRect = null;
    _draftParentId = null;
    if (_controller.tool == EditorTool.select) {
      _controller.clearSelection();
    }
  }

  /// 선택 사각형 업데이트에 따라 선택 또는 드래프트 도형을 갱신합니다.
  void _onSelectionRectUpdate(Rect selectionRect) {
    _lastDragRect = selectionRect;

    final tool = _controller.tool;
    if (tool == EditorTool.rectangle || tool == EditorTool.oval) {
      if (_draftComponentId == null) {
        _draftParentId ??= _hitTestDeepestScreenFromDragStart();
      }
      _upsertDraftShape(selectionRect, tool);
      return;
    }

    if (tool == EditorTool.select) {
      final ids = _hitTestComponentsInRect(selectionRect);
      _controller.setSelectedComponents(ids);
    }
  }

  /// 선택 사각형 종료 시 드래프트 도형 확정/취소 및 선택 복원을 처리합니다.
  void _onSelectionRectEnd() {
    final tool = _controller.tool;
    final rect = _lastDragRect;

    if ((tool == EditorTool.rectangle || tool == EditorTool.oval) &&
        _draftComponentId != null) {
      final id = _draftComponentId!;
      _draftComponentId = null;
      _draftParentId = null;

      final finalized =
          rect != null && rect.size.width >= 8 && rect.size.height >= 8;

      if (!finalized) {
        if (_editorContext.canvasModel.componentExists(id)) {
          _editorContext.canvasModel.removeComponent(id);
          _undoRedoController.commit(
            reader: _editorContext.policySet.canvasReader,
          );
        }
        _restoreSelectionBeforeDraftShapeIfNeeded();
        return;
      }

      _selectionBeforeDraftShape = null;
      _selectedLinkBeforeDraftShape = null;
      _controller
        ..selectSingleComponent(id)
        ..setTool(EditorTool.select);
      _undoRedoController.commit(reader: _editorContext.policySet.canvasReader);

      return;
    }

    _draftComponentId = null;
    _draftParentId = null;
    _lastDragRect = null;
    _selectionBeforeDraftShape = null;
    _selectedLinkBeforeDraftShape = null;
  }

  /// 선택 사각형과 겹치는 컴포넌트 id들을 반환합니다.
  Iterable<String> _hitTestComponentsInRect(Rect selectionRect) sync* {
    for (final component in _editorContext.canvasModel.components.values) {
      if (!component.visible) continue;
      final componentRect = _editorContext.canvasModel.getComponentWorldRect(
        component.id,
      );
      if (selectionRect.overlaps(componentRect)) {
        yield component.id;
      }
    }
  }

  /// 드래그 시작 지점을 기준으로 가장 깊은 Screen을 hit-test합니다.
  String? _hitTestDeepestScreenFromDragStart() {
    final start = _editorContext.canvasEvent.startDragPosition;
    if (start == null) return null;

    final scale = _editorContext.canvasState.scale;
    if (scale <= 0) return null;

    final world = (start - _editorContext.canvasState.position) / scale;
    return _hitTestDeepestScreenAtWorldPoint(world);
  }

  /// 월드 좌표에서 가장 깊은 Screen(중첩 포함)을 hit-test합니다.
  String? _hitTestDeepestScreenAtWorldPoint(Offset worldPoint) {
    final screens =
        _editorContext.canvasModel.components.values
            .where((c) => c.visible && c.type == 'screen' && c.parentId == null)
            .toList()
          ..sort((a, b) => b.zOrder.compareTo(a.zOrder));

    for (final screen in screens) {
      final rect = _editorContext.canvasModel.getComponentWorldRect(screen.id);
      if (!rect.contains(worldPoint)) continue;
      final pointInScreen = worldPoint - rect.topLeft + screen.scrollOffset;
      return _hitTestDeepestScreenInContainer(screen.id, pointInScreen);
    }
    return null;
  }

  /// 특정 Screen 내부 좌표에서 가장 깊은 중첩 Screen을 찾습니다.
  String _hitTestDeepestScreenInContainer(
    String screenId,
    Offset pointInScreen,
  ) {
    final screen = _editorContext.canvasModel.getComponent(screenId);
    final childScreens =
        screen.childrenIds
            .where(_editorContext.canvasModel.componentExists)
            .map(_editorContext.canvasModel.getComponent)
            .where((c) => c.visible && c.type == 'screen')
            .toList()
          ..sort((a, b) => b.zOrder.compareTo(a.zOrder));

    for (final child in childScreens) {
      final rect = Rect.fromLTWH(
        child.position.dx,
        child.position.dy,
        child.size.width,
        child.size.height,
      );
      if (!rect.contains(pointInScreen)) continue;
      final nextPoint = pointInScreen - child.position + child.scrollOffset;
      return _hitTestDeepestScreenInContainer(child.id, nextPoint);
    }
    return screenId;
  }

  /// 도형 생성 도구 사용 중 드래프트 도형을 생성하거나 위치/크기를 갱신합니다.
  void _upsertDraftShape(Rect rect, EditorTool tool) {
    final subtype = tool == EditorTool.oval ? 'oval' : 'rect';

    final id = _draftComponentId;
    if (id == null) {
      String? parentId = _draftParentId;
      if (parentId == null && _controller.selectedComponentIds.length == 1) {
        final candidate = _controller.selectedComponentIds.first;
        if (_editorContext.canvasModel.componentExists(candidate)) {
          final c = _editorContext.canvasModel.getComponent(candidate);
          if (c.type == 'screen') {
            parentId = candidate;
          }
        }
      }

      var position = rect.topLeft;
      if (parentId != null) {
        final parentWorld = _editorContext.canvasModel
            .getComponentWorldPosition(parentId);
        final parent = _editorContext.canvasModel.getComponent(parentId);
        position = rect.topLeft - parentWorld + parent.scrollOffset;
      }

      final component = Component<EditorShapeData>(
        type: 'shape',
        subtype: subtype,
        position: position,
        size: rect.size,
        data: const EditorShapeData(
          fillColorValue: 0xFFFFFFFF,
          strokeColorValue: 0xFF111827,
          strokeWidth: 1,
          cornerRadius: 12,
          rotationRadians: 0,
        ),
      );
      _backupSelectionBeforeDraftShapeIfNeeded();
      _controller.clearSelection();
      _draftComponentId = _editorContext.canvasModel.addComponent(component);
      _draftParentId = parentId;
      if (parentId != null) {
        _editorContext.policySet.canvasWriter.model.attachChild(
          parentId,
          _draftComponentId!,
          preserveWorldPosition: false,
        );
      }
      _applyTopmostZOrderToNewComponent(
        componentId: _draftComponentId!,
        parentId: parentId,
      );
      return;
    }

    if (!_editorContext.canvasModel.componentExists(id)) {
      _draftComponentId = null;
      _draftParentId = null;
      return;
    }

    final component = _editorContext.canvasModel.getComponent(id);
    var position = rect.topLeft;
    final parentId = _draftParentId;
    if (parentId != null &&
        _editorContext.canvasModel.componentExists(parentId)) {
      final parentWorld = _editorContext.canvasModel.getComponentWorldPosition(
        parentId,
      );
      final parent = _editorContext.canvasModel.getComponent(parentId);
      position = rect.topLeft - parentWorld + parent.scrollOffset;
    }
    component
      ..setPosition(position)
      ..setSize(rect.size);
  }
}
