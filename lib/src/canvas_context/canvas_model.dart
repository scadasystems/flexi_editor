import 'dart:collection';

import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/model/flexi_data.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CanvasModel with ChangeNotifier {
  final Uuid _uuid = const Uuid();
  HashMap<String, Component> components = HashMap();
  HashMap<String, LinkData> links = HashMap();
  PolicySet policySet;

  CanvasModel(this.policySet);

  FlexiData getFlexi() {
    for (final component in components.values) {
      if (!_hasToJsonMethodAtComponent(component)) {
        throw ArgumentError(
          'ComponentData.data does not have a toJson() method.',
        );
      }
    }

    for (final link in links.values) {
      if (!_hasToJsonMethodAtLink(link)) {
        throw ArgumentError('LinkData.data does not have a toJson() method.');
      }
    }

    return FlexiData(
      components: components.values.toList(),
      links: links.values.toList(),
    );
  }

  bool _hasToJsonMethodAtComponent(Component component) {
    try {
      component.data.toJson();
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _hasToJsonMethodAtLink(LinkData link) {
    try {
      link.data.toJson();
      return true;
    } catch (e) {
      return false;
    }
  }

  void updateCanvas() {
    notifyListeners();
  }

  bool componentExists(String id) {
    return components.containsKey(id);
  }

  Component getComponent(String id) {
    return components[id]!;
  }

  Offset getComponentWorldPosition(String componentId) {
    final visited = HashSet<String>();
    return _getComponentWorldPositionInternal(componentId, visited);
  }

  Rect getComponentWorldRect(String componentId) {
    final component = getComponent(componentId);
    final position = getComponentWorldPosition(componentId);
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      component.size.width,
      component.size.height,
    );
  }

  Offset _getComponentWorldPositionInternal(
    String componentId,
    HashSet<String> visited,
  ) {
    if (!visited.add(componentId)) {
      return components[componentId]?.position ?? Offset.zero;
    }

    final component = getComponent(componentId);
    final parentId = component.parentId;
    if (parentId == null) return component.position;
    if (!componentExists(parentId)) return component.position;

    final parentWorld = _getComponentWorldPositionInternal(parentId, visited);
    final parent = getComponent(parentId);
    return parentWorld + (component.position - parent.scrollOffset);
  }

  HashMap<String, Component> getAllComponents() {
    return components;
  }

  bool linkExists(String id) {
    return links.containsKey(id);
  }

  LinkData getLink(String id) {
    return links[id]!;
  }

  HashMap<String, LinkData> getAllLinks() {
    return links;
  }

  String addComponent(Component componentData) {
    components[componentData.id] = componentData;
    notifyListeners();
    return componentData.id;
  }

  void removeComponent(String id) {
    removeComponentConnections(id);
    components.remove(id);
    notifyListeners();
  }

  void removeComponentConnections(String id) {
    assert(components.keys.contains(id));

    final List<String> linksToRemove = [];

    getComponent(id).connections.forEach((connection) {
      linksToRemove.add(connection.connectionId);
    });

    linksToRemove.forEach(removeLink);
    notifyListeners();
  }

  void removeAllComponents() {
    links.clear();
    components.clear();
    notifyListeners();
  }

  void setComponentZOrder(String componentId, int zOrder) {
    getComponent(componentId).zOrder = zOrder;
    notifyListeners();
  }

  void setComponentName(String componentId, String? name) {
    getComponent(componentId).setName(name);
    notifyListeners();
  }

  void setComponentVisible(String componentId, bool visible) {
    final component = getComponent(componentId);
    if (component.visible == visible) return;
    component.setVisible(visible);
    notifyListeners();
  }

  int moveComponentToTheFront(String componentId) {
    int zOrderMax = getComponent(componentId).zOrder;
    for (final component in components.values) {
      if (component.zOrder > zOrderMax) {
        zOrderMax = component.zOrder;
      }
    }
    getComponent(componentId).zOrder = zOrderMax + 1;
    notifyListeners();
    return zOrderMax + 1;
  }

  int moveComponentToTheBack(String componentId) {
    int zOrderMin = getComponent(componentId).zOrder;
    for (final component in components.values) {
      if (component.zOrder < zOrderMin) {
        zOrderMin = component.zOrder;
      }
    }
    getComponent(componentId).zOrder = zOrderMin - 1;
    notifyListeners();
    return zOrderMin - 1;
  }

  void addLink(LinkData linkData) {
    links[linkData.id] = linkData;
    notifyListeners();
  }

  void removeLink(String linkId) {
    getComponent(getLink(linkId).sourceComponentId).removeConnection(linkId);
    getComponent(getLink(linkId).targetComponentId).removeConnection(linkId);
    links.remove(linkId);
    notifyListeners();
  }

  void removeAllLinks() {
    for (final component in components.values) {
      removeComponentConnections(component.id);
    }
  }

  String connectTwoComponents(
    String sourceComponentId,
    String targetComponentId,
    LinkStyle? linkStyle,
    dynamic data,
  ) {
    final linkId = _uuid.v4();
    final sourceComponent = getComponent(sourceComponentId);
    final targetComponent = getComponent(targetComponentId);

    sourceComponent.addConnection(
      ConnectionOut(
        connectionId: linkId,
        otherComponentId: targetComponentId,
      ),
    );
    targetComponent.addConnection(
      ConnectionIn(
        connectionId: linkId,
        otherComponentId: sourceComponentId,
      ),
    );

    final sourceWorld = getComponentWorldPosition(sourceComponentId);
    final targetWorld = getComponentWorldPosition(targetComponentId);
    final sourceForAlign = sourceComponent.copyWith(position: sourceWorld);
    final targetForAlign = targetComponent.copyWith(position: targetWorld);

    final sourceLinkAlignment = policySet.getLinkEndpointAlignment(
      sourceForAlign,
      targetWorld + targetComponent.size.center(Offset.zero),
    );
    final targetLinkAlignment = policySet.getLinkEndpointAlignment(
      targetForAlign,
      sourceWorld + sourceComponent.size.center(Offset.zero),
    );

    links[linkId] = LinkData(
      id: linkId,
      sourceComponentId: sourceComponentId,
      targetComponentId: targetComponentId,
      linkPoints: [
        sourceWorld + sourceComponent.getPointOnComponent(sourceLinkAlignment),
        targetWorld + targetComponent.getPointOnComponent(targetLinkAlignment),
      ],
      linkStyle: linkStyle ?? LinkStyle(),
      data: data,
    );

    notifyListeners();
    return linkId;
  }

  void updateLinks(String componentId) {
    assert(
      componentExists(componentId),
      'model does not contain this component id: $componentId',
    );
    final component = getComponent(componentId);
    for (final connection in component.connections) {
      final link = getLink(connection.connectionId);

      Component sourceComponent = component;
      var targetComponent = getComponent(connection.otherComponentId);

      if (connection is ConnectionOut) {
        sourceComponent = component;
        targetComponent = getComponent(connection.otherComponentId);
      } else if (connection is ConnectionIn) {
        sourceComponent = getComponent(connection.otherComponentId);
        targetComponent = component;
      } else {
        throw ArgumentError('Invalid port connection.');
      }

      final Alignment firstLinkAlignment = _getLinkEndpointAlignment(
        sourceComponent,
        targetComponent,
        link,
        1,
      );
      final Alignment secondLinkAlignment = _getLinkEndpointAlignment(
        targetComponent,
        sourceComponent,
        link,
        link.linkPoints.length - 2,
      );

      final sourceWorld = getComponentWorldPosition(sourceComponent.id);
      final targetWorld = getComponentWorldPosition(targetComponent.id);
      final sourceForSet = sourceComponent.copyWith(position: sourceWorld);
      final targetForSet = targetComponent.copyWith(position: targetWorld);
      _setLinkEndpoints(
        link,
        sourceForSet,
        targetForSet,
        firstLinkAlignment,
        secondLinkAlignment,
      );
    }
  }

  Alignment _getLinkEndpointAlignment(
    Component component1,
    Component component2,
    LinkData link,
    int linkPointIndex,
  ) {
    final component1World = getComponentWorldPosition(component1.id);
    final component2World = getComponentWorldPosition(component2.id);
    final component1ForAlign = component1.copyWith(position: component1World);

    if (link.linkPoints.length <= 2) {
      return policySet.getLinkEndpointAlignment(
        component1ForAlign,
        component2World + component2.size.center(Offset.zero),
      );
    } else {
      return policySet.getLinkEndpointAlignment(
        component1ForAlign,
        link.linkPoints[linkPointIndex],
      );
    }
  }

  void _setLinkEndpoints(
    LinkData link,
    Component component1,
    Component component2,
    Alignment alignment1,
    Alignment alignment2,
  ) {
    link.setEndpoints(
      component1.position + component1.getPointOnComponent(alignment1),
      component2.position + component2.getPointOnComponent(alignment2),
    );
  }
}
