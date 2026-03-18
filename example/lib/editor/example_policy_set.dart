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

/// 예제 에디터에서 사용하는 PolicySet 구현입니다.
///
/// - 선택/이동/리사이즈/회전/링크 연결 및 Screen 이름 라벨 UI를 제공합니다.
class ExamplePolicySet extends PolicySet
    with
        CanvasControlPolicy,
        LinkControlPolicy,
        LinkJointControlPolicy,
        LinkAttachmentRectPolicy {
  final EditorController controller;
  final CanvasUndoRedoController undoRedoController;

  String? _activeDragMoveTargetId;
  bool _activeDragMoveForceMove = false;
  String? _editingScreenNameComponentId;
  Color _uiAccentColor = const Color(0xFF2563EB);
  Color _uiHandleFillColor = const Color(0xFFFFFFFF);
  Color _uiLinkColor = const Color(0xFF6B7280);

  /// 예제 UI 컨트롤러 및 undo/redo 컨트롤러를 주입받아 정책을 구성합니다.
  ExamplePolicySet({
    required this.controller,
    required this.undoRedoController,
  });

  /// 선택/핸들/하이라이트 UI에 사용하는 강조 색상입니다.
  Color get uiAccentColor => _uiAccentColor;

  /// 조작 핸들(리사이즈/회전)의 채움 색상입니다.
  Color get uiHandleFillColor => _uiHandleFillColor;

  /// 링크(선/커넥터) 색상입니다.
  Color get uiLinkColor => _uiLinkColor;

  /// 현재 테마에 맞춰 예제 UI 색상을 갱신합니다.
  void setUiTheme({
    required Brightness brightness,
    required ColorScheme scheme,
  }) {
    final isDark = brightness == Brightness.dark;
    _uiAccentColor = scheme.primary;
    _uiHandleFillColor = isDark ? scheme.surface : const Color(0xFFFFFFFF);
    _uiLinkColor = isDark ? scheme.onSurfaceVariant : const Color(0xFF6B7280);
  }

  @override
  void initializeEditor() {
    canvasWriter.state.setCanvasColor(const Color(0xFFF7F7F8));
    canvasWriter.state.setDottedBackground(
      const CanvasDottedBackgroundConfig(
        enabled: true,
        snapThresholdCanvas: 4,
        minVisibleScale: 0.2,
        dotRadiusCanvas: 1,
        color: Colors.black,
      ),
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
        linkStyle: LinkStyle(color: uiLinkColor, lineWidth: 2),
      );
      controller
        ..clearPendingConnector()
        ..selectLink(linkId);
      undoRedoController.commit(reader: canvasReader);
      return;
    }

    if (tool == EditorTool.select) {
      final component = canvasReader.model.getComponent(componentId);
      if (component.isScreen && component.hasChildren) return;
      controller.selectSingleComponent(componentId);
    }
  }

  @override
  void onComponentDoubleTapDown(String componentId, TapDownDetails details) {
    if (controller.tool != EditorTool.select) return;
    final scale = canvasReader.state.scale;
    if (scale <= 0) return;

    final component = canvasReader.model.getComponent(componentId);
    final point =
        Offset(
          details.localPosition.dx / scale,
          details.localPosition.dy / scale,
        ) +
        component.scrollOffset;

    final hit = _hitTestDeepestChild(componentId, point);
    controller.selectSingleComponent(hit ?? componentId);
  }

  /// 중첩된 자식들 중, [pointInParent]에 가장 깊게 포함되는 컴포넌트를 찾습니다.
  String? _hitTestDeepestChild(String parentId, Offset pointInParent) {
    if (!canvasReader.model.componentExist(parentId)) return null;
    final parent = canvasReader.model.getComponent(parentId);
    final childOrderIndex = <String, int>{
      for (var i = 0; i < parent.childrenIds.length; i++)
        parent.childrenIds[i]: i,
    };
    final children =
        parent.childrenIds
            .where(canvasReader.model.componentExist)
            .map(canvasReader.model.getComponent)
            .toList()
          ..sort((a, b) {
            final zCompare = a.zOrder.compareTo(b.zOrder);
            if (zCompare != 0) return zCompare;
            return (childOrderIndex[a.id] ?? 0).compareTo(
              childOrderIndex[b.id] ?? 0,
            );
          });

    for (var i = children.length - 1; i >= 0; i--) {
      final child = children[i];
      final rect = Rect.fromLTWH(
        child.position.dx,
        child.position.dy,
        child.size.width,
        child.size.height,
      );
      if (!rect.contains(pointInParent)) continue;
      if (child.hasChildren) {
        final childPoint = pointInParent - child.position + child.scrollOffset;
        return _hitTestDeepestChild(child.id, childPoint) ?? child.id;
      }
      return child.id;
    }
    return null;
  }

  /// [componentId]가 [ancestorId]의 하위(자손)인지 판정합니다.
  bool _isDescendantOf(String componentId, String ancestorId) {
    var currentId = componentId;
    while (true) {
      if (!canvasReader.model.componentExist(currentId)) return false;
      final parentId = canvasReader.model.getComponent(currentId).parentId;
      if (parentId == null) return false;
      if (parentId == ancestorId) return true;
      currentId = parentId;
    }
  }

  /// 드래그 시작 컴포넌트와 선택 상태를 기준으로 실제 이동 대상 id를 결정합니다.
  String _resolveDragMoveTargetId(String componentId) {
    final selected = controller.selectedComponentIds;
    if (selected.length != 1) return componentId;
    final selectedId = selected.first;
    if (selectedId == componentId) return componentId;
    if (canvasReader.model.componentExist(selectedId) &&
        canvasReader.model.getComponent(selectedId).isScreen &&
        canvasReader.model.getComponent(selectedId).hasChildren) {
      return componentId;
    }
    if (_isDescendantOf(componentId, selectedId)) return selectedId;
    return componentId;
  }

  @override
  void onComponentScaleStart(
    String componentId,
    ScaleStartDetails details, {
    bool forceMove = false,
  }) {
    if (controller.tool != EditorTool.select) {
      _activeDragMoveTargetId = null;
      _activeDragMoveForceMove = false;
      return;
    }

    if (forceMove) {
      if (!canvasReader.model.componentExist(componentId)) return;
      controller.selectSingleComponent(componentId);
      _activeDragMoveTargetId = componentId;
      _activeDragMoveForceMove = true;
      return;
    }
    _activeDragMoveForceMove = false;

    final selected = controller.selectedComponentIds;
    if (selected.isEmpty) {
      if (!canvasReader.model.componentExist(componentId)) return;
      final component = canvasReader.model.getComponent(componentId);
      if (component.isScreen && component.hasChildren) {
        _activeDragMoveTargetId = null;
        return;
      }
      controller.selectSingleComponent(componentId);
      _activeDragMoveTargetId = componentId;
      return;
    }

    final targetId = _resolveDragMoveTargetId(componentId);
    if (canvasReader.model.componentExist(targetId) &&
        canvasReader.model.getComponent(targetId).isScreen &&
        canvasReader.model.getComponent(targetId).hasChildren) {
      _activeDragMoveTargetId = null;
      return;
    }
    if (selected.length == 1 && selected.first != targetId) {
      controller.selectSingleComponent(targetId);
    }
    _activeDragMoveTargetId = targetId;
  }

  @override
  void onComponentScaleUpdate(String componentId, ScaleUpdateDetails details) {
    if (controller.tool != EditorTool.select) return;
    final deltaScreen = details.focalPointDelta;
    if (deltaScreen == Offset.zero) return;

    final targetComponentId =
        _activeDragMoveTargetId ?? _resolveDragMoveTargetId(componentId);
    if (canvasReader.model.componentExist(targetComponentId) &&
        canvasReader.model.getComponent(targetComponentId).isScreen &&
        canvasReader.model.getComponent(targetComponentId).hasChildren &&
        !_activeDragMoveForceMove) {
      return;
    }
    final state = canvasReader.state;
    final dotted = state.dottedBackground;
    if (!dotted.enabled || dotted.gridSpacingCanvas <= 0) {
      canvasWriter.model.moveComponentWithChildren(
        targetComponentId,
        deltaScreen,
      );
      return;
    }

    final component = canvasReader.model.getComponent(targetComponentId);
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
    canvasWriter.model.moveComponentWithChildren(
      targetComponentId,
      finalDeltaScreen,
    );
  }

  @override
  void onComponentScaleEnd(String componentId, ScaleEndDetails details) {
    if (controller.tool != EditorTool.select) return;
    _activeDragMoveTargetId = null;
    _activeDragMoveForceMove = false;
    undoRedoController.commit(reader: canvasReader);
  }

  @override
  void onLinkTap(String linkId) {
    if (controller.tool != EditorTool.select) return;
    controller.selectLink(linkId);
  }

  /// 현재 Screen 이름 라벨이 편집 중인지 확인합니다.
  bool _isScreenNameEditing(String componentId) {
    return _editingScreenNameComponentId == componentId;
  }

  /// Screen 이름 라벨 편집 모드를 시작합니다.
  void _startScreenNameEdit(Component component) {
    if (!component.isScreen) return;
    controller.selectSingleComponent(component.id);
    _editingScreenNameComponentId = component.id;
    canvasWriter.state.updateCanvas();
  }

  /// Screen 이름 라벨 편집 모드를 종료합니다.
  void _endScreenNameEdit() {
    if (_editingScreenNameComponentId == null) return;
    _editingScreenNameComponentId = null;
    canvasWriter.state.updateCanvas();
  }

  /// 편집된 Screen 이름을 모델에 반영하고 undo/redo에 커밋합니다.
  void _commitScreenNameEdit({
    required String componentId,
    required String text,
  }) {
    if (!canvasReader.model.componentExist(componentId)) {
      _endScreenNameEdit();
      return;
    }

    final nextText = text.trim();
    final nextName = nextText.isEmpty ? null : nextText;
    final currentName = canvasReader.model
        .getComponent(componentId)
        .name
        ?.trim();
    final currentNameNormalized = currentName == null || currentName.isEmpty
        ? null
        : currentName;
    if (nextName != currentNameNormalized) {
      canvasWriter.model.setComponentName(componentId, nextName);
      undoRedoController.commit(reader: canvasReader);
      controller.selectSingleComponent(componentId);
    }
    _endScreenNameEdit();
  }

  @override
  Widget showCustomWidgetWithComponentData(
    BuildContext context,
    Component componentData,
  ) {
    return const SizedBox.shrink();
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
    if (componentData.isScreen) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          _ScreenNameOverlay(policy: this, componentData: componentData),
          _ComponentSelectionOverlay(
            policy: this,
            componentData: componentData,
          ),
        ],
      );
    }

    return _ComponentSelectionOverlay(
      policy: this,
      componentData: componentData,
    );
  }
}

class _ScreenNameOverlay extends StatelessWidget {
  final ExamplePolicySet policy;
  final Component componentData;

  const _ScreenNameOverlay({required this.policy, required this.componentData});

  @override
  Widget build(BuildContext context) {
    return Consumer<CanvasState>(
      builder: (context, canvasState, child) {
        return AnimatedBuilder(
          animation: componentData,
          builder: (context, child) {
            final rawName = componentData.name?.trim() ?? '';
            final label = rawName.isNotEmpty ? rawName : 'Screen';
            final isEditing = policy._isScreenNameEditing(componentData.id);

            final worldPosition = policy.canvasReader.model
                .getComponentWorldPosition(
                  componentData.id,
                );
            final left =
                canvasState.scale * worldPosition.dx + canvasState.position.dx;
            final top =
                canvasState.scale * worldPosition.dy + canvasState.position.dy;

            final scheme = Theme.of(context).colorScheme;
            final backgroundColor = scheme.surface.withAlpha(235);
            final borderColor = scheme.outline.withAlpha(120);
            final textColor = scheme.onSurface.withAlpha(190);

            const outerPadding = 8.0;
            const labelGap = 28.0;

            return Positioned(
              left: left - outerPadding,
              top: top - labelGap - outerPadding,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: isEditing
                    ? null
                    : () => policy._startScreenNameEdit(componentData),
                onScaleStart: isEditing
                    ? null
                    : (details) => policy.onComponentScaleStart(
                        componentData.id,
                        details,
                        forceMove: true,
                      ),
                onScaleUpdate: isEditing
                    ? null
                    : (details) => policy.onComponentScaleUpdate(
                        componentData.id,
                        details,
                      ),
                onScaleEnd: isEditing
                    ? null
                    : (details) => policy.onComponentScaleEnd(
                        componentData.id,
                        details,
                      ),
                child: Padding(
                  padding: const EdgeInsets.all(outerPadding),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      child: _ScreenNameLabelContent(
                        key: ValueKey('screen_name_label:${componentData.id}'),
                        policy: policy,
                        componentData: componentData,
                        isEditing: isEditing,
                        displayLabel: label,
                        textColor: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ScreenNameLabelContent extends StatefulWidget {
  final ExamplePolicySet policy;
  final Component componentData;
  final bool isEditing;
  final String displayLabel;
  final Color textColor;

  /// Screen 이름 라벨의 표시/편집 UI를 렌더링합니다.
  const _ScreenNameLabelContent({
    super.key,
    required this.policy,
    required this.componentData,
    required this.isEditing,
    required this.displayLabel,
    required this.textColor,
  });

  @override
  State<_ScreenNameLabelContent> createState() =>
      _ScreenNameLabelContentState();
}

class _ScreenNameLabelContentState extends State<_ScreenNameLabelContent> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isCommitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) return;
      if (!widget.isEditing) return;
      _commit();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ScreenNameLabelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isEditing && widget.isEditing) {
      _controller.text = widget.componentData.name ?? '';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!widget.isEditing) return;
        _focusNode.requestFocus();
      });
      return;
    }

    if (oldWidget.isEditing && !widget.isEditing) {
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    }
  }

  /// 현재 입력 값을 정책에 전달해 Screen 이름을 저장합니다.
  void _commit() {
    if (_isCommitting) return;
    _isCommitting = true;
    widget.policy._commitScreenNameEdit(
      componentId: widget.componentData.id,
      text: _controller.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 12,
      color: widget.textColor,
      fontWeight: FontWeight.w500,
      height: 1.1,
    );

    if (!widget.isEditing) {
      return Text(
        widget.displayLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        style: style,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _commit(),
      ),
    );
  }
}
