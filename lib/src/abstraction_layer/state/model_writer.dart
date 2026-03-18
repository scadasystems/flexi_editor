import 'dart:convert';

import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/canvas_context/canvas_state.dart';
import 'package:flexi_editor/src/canvas_context/model/component.dart';
import 'package:flexi_editor/src/canvas_context/model/flexi_data.dart';
import 'package:flexi_editor/src/utils/link_style.dart';
import 'package:flutter/material.dart';

class ModelWriter {
  final CanvasModel _canvasModel;
  final CanvasState _canvasState;

  ModelWriter(this._canvasModel, this._canvasState);
}

class CanvasModelWriter extends ModelWriter
    with ComponentWriter, LinkWriter, ConnectionWriter {
  CanvasModelWriter(super.canvasModel, super.canvasState);

  String addComponent(Component componentData) {
    return _canvasModel.addComponent(componentData);
  }

  void removeComponent(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    removeComponentParent(componentId);
    _removeParentFromChildren(componentId);
    _canvasModel.removeComponent(componentId);
  }

  void removeComponentWithChildren(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    final List<String> componentsToRemove = [];
    _removeComponentWithChildren(componentId, componentsToRemove);
    componentsToRemove.reversed.forEach(removeComponent);
  }

  void _removeComponentWithChildren(String componentId, List<String> toRemove) {
    toRemove.add(componentId);
    _canvasModel.getComponent(componentId).childrenIds.forEach((childId) {
      _removeComponentWithChildren(childId, toRemove);
    });
  }

  void removeAllComponents() {
    _canvasModel.removeAllComponents();
  }

  void removeLink(String linkId) {
    assert(_canvasModel.linkExists(linkId),
        'model does not contain this link id: $linkId');
    _canvasModel.removeLink(linkId);
  }

  void removeAllLinks() {
    _canvasModel.removeAllLinks();
  }

  void deserializeFlexi(
    String json, {
    Function(Map<String, dynamic> json)? decodeCustomComponentData,
    Function(Map<String, dynamic> json)? decodeCustomLinkData,
  }) {
    final flexiData = FlexiData.fromJson(
      jsonDecode(json),
      decodeCustomComponentData: decodeCustomComponentData,
      decodeCustomLinkData: decodeCustomLinkData,
    );
    for (final componentData in flexiData.components) {
      _canvasModel.components[componentData.id] = componentData;
    }
    for (final linkData in flexiData.links) {
      _canvasModel.links[linkData.id] = linkData;
      linkData.refresh();
    }
    _canvasModel.updateCanvas();
  }
}

mixin ComponentWriter on ModelWriter {
  void _updateLinksRecursively(String componentId) {
    _canvasModel.updateLinks(componentId);
    final component = _canvasModel.getComponent(componentId);
    for (final childId in component.childrenIds) {
      if (_canvasModel.componentExists(childId)) {
        _updateLinksRecursively(childId);
      }
    }
  }

  void updateComponent(String? componentId) {
    if (componentId == null) return;
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _canvasModel.getComponent(componentId).refresh();
  }

  void setComponentPosition(String componentId, Offset position) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _canvasModel.getComponent(componentId).setPosition(position);
    _updateLinksRecursively(componentId);
  }

  void moveComponent(String componentId, Offset offset,
      {bool withScale = true}) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _canvasModel
        .getComponent(componentId)
        .move(offset / (withScale ? _canvasState.scale : 1));
    _updateLinksRecursively(componentId);
  }

  void moveComponentWithChildren(String componentId, Offset offset,
      {bool withScale = true}) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    moveComponent(componentId, offset, withScale: withScale);
  }

  void removeComponentConnections(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _canvasModel.removeComponentConnections(componentId);
  }

  void updateComponentLinks(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _updateLinksRecursively(componentId);
  }

  void setComponentZOrder(String componentId, int zOrder) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _canvasModel.setComponentZOrder(componentId, zOrder);
  }

  void setComponentName(String componentId, String? name) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _canvasModel.setComponentName(componentId, name);
  }

  void setComponentVisible(String componentId, bool visible) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _canvasModel.setComponentVisible(componentId, visible);
  }

  int moveComponentToTheFront(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    return _canvasModel.moveComponentToTheFront(componentId);
  }

  int moveComponentToTheFrontWithChildren(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    final int zOrder = moveComponentToTheFront(componentId);
    _setZOrderToChildren(componentId, zOrder);
    return zOrder;
  }

  void _setZOrderToChildren(String componentId, int zOrder) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    setComponentZOrder(componentId, zOrder);
    _canvasModel.getComponent(componentId).childrenIds.forEach((childId) {
      _setZOrderToChildren(childId, zOrder + 1);
    });
  }

  int moveComponentToTheBack(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    return _canvasModel.moveComponentToTheBack(componentId);
  }

  int moveComponentToTheBackWithChildren(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    final int zOrder = moveComponentToTheBack(componentId);
    _setZOrderToChildren(componentId, zOrder);
    return zOrder;
  }

  void resizeComponent(String componentId, Offset deltaSize) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _canvasModel.getComponent(componentId).resizeDelta(deltaSize);
  }

  void setComponentSize(String componentId, Size size) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    final component = _canvasModel.getComponent(componentId);
    final oldSize = component.size;
    component.setSize(size);
    if (component.childrenIds.isNotEmpty &&
        oldSize.width != 0 &&
        oldSize.height != 0) {
      final scaleX = size.width / oldSize.width;
      final scaleY = size.height / oldSize.height;
      _scaleChildrenRecursively(componentId, scaleX: scaleX, scaleY: scaleY);
    }
    _updateLinksRecursively(componentId);
  }

  void _scaleChildrenRecursively(
    String parentId, {
    required double scaleX,
    required double scaleY,
  }) {
    final parent = _canvasModel.getComponent(parentId);
    for (final childId in parent.childrenIds) {
      if (!_canvasModel.componentExists(childId)) continue;
      final child = _canvasModel.getComponent(childId);
      child
        ..setPosition(Offset(child.position.dx * scaleX, child.position.dy * scaleY))
        ..setSize(Size(child.size.width * scaleX, child.size.height * scaleY));
      if (child.childrenIds.isNotEmpty) {
        _scaleChildrenRecursively(childId, scaleX: scaleX, scaleY: scaleY);
      }
    }
  }

  void setComponentParent(String componentId, String parentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    removeComponentParent(componentId);
    if (_checkParentChildLoop(componentId, parentId)) {
      _canvasModel.getComponent(componentId).setParent(parentId);
      _canvasModel.getComponent(parentId).addChild(componentId);
    }
    _canvasModel.updateCanvas();
    _updateLinksRecursively(parentId);
  }

  void attachChild(
    String parentId,
    String childId, {
    bool preserveWorldPosition = true,
  }) {
    assert(_canvasModel.componentExists(parentId),
        'model does not contain this component id: $parentId');
    assert(_canvasModel.componentExists(childId),
        'model does not contain this component id: $childId');

    final childWorldBefore = preserveWorldPosition
        ? _canvasModel.getComponentWorldPosition(childId)
        : null;

    setComponentParent(childId, parentId);

    if (preserveWorldPosition && childWorldBefore != null) {
      final parentWorld = _canvasModel.getComponentWorldPosition(parentId);
      final parent = _canvasModel.getComponent(parentId);
      final local = childWorldBefore - parentWorld + parent.scrollOffset;
      _canvasModel.getComponent(childId).setPosition(local);
      _updateLinksRecursively(parentId);
    }
  }

  void detachChild(
    String childId, {
    bool preserveWorldPosition = true,
  }) {
    assert(_canvasModel.componentExists(childId),
        'model does not contain this component id: $childId');

    final parentId = _canvasModel.getComponent(childId).parentId;
    final childWorldBefore = preserveWorldPosition
        ? _canvasModel.getComponentWorldPosition(childId)
        : null;

    removeComponentParent(childId);

    if (preserveWorldPosition && childWorldBefore != null) {
      _canvasModel.getComponent(childId).setPosition(childWorldBefore);
      _updateLinksRecursively(childId);
      if (parentId != null) {
        _updateLinksRecursively(parentId);
      }
    }
  }

  bool _checkParentChildLoop(String componentId, String parentId) {
    if (componentId == parentId) return false;
    final parentIdOfParent = _canvasModel.getComponent(parentId).parentId;
    if (parentIdOfParent != null) {
      return _checkParentChildLoop(componentId, parentIdOfParent);
    }

    return true;
  }

  void removeComponentParent(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    final parentId = _canvasModel.getComponent(componentId).parentId;
    if (parentId != null) {
      _canvasModel.getComponent(componentId).removeParent();
      _canvasModel.getComponent(parentId).removeChild(componentId);
    }
    _canvasModel.updateCanvas();
    if (parentId != null) {
      _updateLinksRecursively(parentId);
    }
  }

  void _removeParentFromChildren(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    final component = _canvasModel.getComponent(componentId);
    final childrenToRemove = List.from(component.childrenIds);
    for (final childId in childrenToRemove) {
      removeComponentParent(childId);
    }
  }

  void setComponentLocked(String componentId) {
    _canvasModel.getComponent(componentId).lock();
  }

  void setComponentUnlocked(String componentId) {
    _canvasModel.getComponent(componentId).unlock();
  }
}

mixin LinkWriter on ModelWriter {
  void updateLink(String linkId) {
    assert(_canvasModel.linkExists(linkId),
        'model does not contain this link id: $linkId');
    _canvasModel.updateLinks(_canvasModel.getLink(linkId).sourceComponentId);
    _canvasModel.updateLinks(_canvasModel.getLink(linkId).targetComponentId);
  }

  void insertLinkMiddlePoint(String linkId, Offset point, int index) {
    assert(_canvasModel.linkExists(linkId),
        'model does not contain this link id: $linkId');
    _canvasModel
        .getLink(linkId)
        .insertMiddlePoint(_canvasState.fromCanvasCoordinates(point), index);
  }

  void setLinkMiddlePointPosition(String linkId, Offset point, int index) {
    assert(_canvasModel.linkExists(linkId),
        'model does not contain this link id: $linkId');
    _canvasModel.getLink(linkId).setMiddlePointPosition(
        _canvasState.fromCanvasCoordinates(point), index);
  }

  void moveLinkMiddlePoint(String linkId, Offset offset, int index) {
    assert(_canvasModel.linkExists(linkId),
        'model does not contain this link id: $linkId');
    _canvasModel
        .getLink(linkId)
        .moveMiddlePoint(offset / _canvasState.scale, index);
  }

  void removeLinkMiddlePoint(String linkId, int index) {
    assert(_canvasModel.linkExists(linkId),
        'model does not contain this link id: $linkId');
    _canvasModel.getLink(linkId).removeMiddlePoint(index);
  }

  void moveAllLinkMiddlePoints(String linkId, Offset position) {
    assert(_canvasModel.linkExists(linkId),
        'model does not contain this link id: $linkId');
    _canvasModel
        .getLink(linkId)
        .moveAllMiddlePoints(position / _canvasState.scale);
  }
}

mixin ConnectionWriter on ModelWriter {
  String connectTwoComponents({
    required String sourceComponentId,
    required String targetComponentId,
    LinkStyle? linkStyle,
    dynamic data,
  }) {
    assert(_canvasModel.componentExists(sourceComponentId));
    assert(_canvasModel.componentExists(targetComponentId));
    return _canvasModel.connectTwoComponents(
      sourceComponentId,
      targetComponentId,
      linkStyle,
      data,
    );
  }
}
