import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';

mixin ComponentControlPolicy on PolicySet {
  Offset _lastFocalPoint = Offset.zero;

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

    canvasWriter.model.moveComponentWithChildren(componentId, delta);
  }

  @override
  void onComponentSecondaryTap(
    BuildContext context,
    String componentId,
    TapDownDetails details,
  ) async {
    // 우클릭한 컴포넌트가 선택되어 있지 않다면 선택 처리
    if (!canvasReader.state.isComponentSelected(componentId)) {
      canvasWriter.state.clearSelection();
      canvasWriter.state.selectComponent(componentId);
    }

    final selectedIds = canvasReader.state.selectedComponentIds;
    final component = canvasReader.model.getComponent(componentId);

    final List<PopupMenuEntry<String>> items = [];

    // 그룹 생성 메뉴
    if (selectedIds.length >= 2) {
      items.add(
        const PopupMenuItem<String>(
          value: 'group',
          child: Text('Group'),
        ),
      );
    }

    // 그룹 해제 메뉴
    if (component.type == 'group') {
      items.add(
        const PopupMenuItem<String>(
          value: 'ungroup',
          child: Text('Ungroup'),
        ),
      );
    }

    if (items.isEmpty) return;

    final position = RelativeRect.fromLTRB(
      details.globalPosition.dx,
      details.globalPosition.dy,
      details.globalPosition.dx,
      details.globalPosition.dy,
    );

    final value = await showMenu<String>(
      context: context,
      position: position,
      items: items,
    );

    if (value == null) return;

    if (value == 'group') {
      (this as GroupPolicy).groupSelectedComponents(selectedIds.toList());
    } else if (value == 'ungroup') {
      (this as GroupPolicy).ungroupComponent(componentId);
    }
  }
}
