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
    List<String> componentsToRemove = [];
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
    _canvasModel.updateLinks(componentId);
  }

  void moveComponent(String componentId, Offset offset,
      {bool withScale = true}) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _canvasModel
        .getComponent(componentId)
        .move(offset / (withScale ? _canvasState.scale : 1));
    _canvasModel.updateLinks(componentId);
  }

  void moveComponentWithChildren(String componentId, Offset offset,
      {bool withScale = true}) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    moveComponent(componentId, offset, withScale: withScale);
    _canvasModel.getComponent(componentId).childrenIds.forEach((childId) {
      moveComponentWithChildren(childId, offset);
    });
  }

  void removeComponentConnections(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _canvasModel.removeComponentConnections(componentId);
  }

  void updateComponentLinks(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _canvasModel.updateLinks(componentId);
  }

  void setComponentZOrder(String componentId, int zOrder) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    _canvasModel.setComponentZOrder(componentId, zOrder);
  }

  int moveComponentToTheFront(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    return _canvasModel.moveComponentToTheFront(componentId);
  }

  int moveComponentToTheFrontWithChildren(String componentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    int zOrder = moveComponentToTheFront(componentId);
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
    int zOrder = moveComponentToTheBack(componentId);
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
    _canvasModel.getComponent(componentId).setSize(size);
  }

  void setComponentParent(String componentId, String parentId) {
    assert(_canvasModel.componentExists(componentId),
        'model does not contain this component id: $componentId');
    removeComponentParent(componentId);
    if (_checkParentChildLoop(componentId, parentId)) {
      _canvasModel.getComponent(componentId).setParent(parentId);
      _canvasModel.getComponent(parentId).addChild(componentId);
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
  }

  void _removeParentFromChildren(componentId) {
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
