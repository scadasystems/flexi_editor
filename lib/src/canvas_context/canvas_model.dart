import 'dart:collection';

import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/model/connection.dart';
import 'package:flexi_editor/src/canvas_context/model/flexi_data.dart';
import 'package:flexi_editor/src/canvas_context/model/grid_type.dart';
import 'package:flutter/material.dart';

class CanvasModel with ChangeNotifier {
  HashMap<String, Component> components = HashMap();
  HashMap<String, Connection> connections = HashMap();
  PolicySet policySet;

  // 그리드 설정
  GridType gridType = GridType.line;
  Color gridColor = Colors.grey.withOpacity(0.3);
  double gridSpacing = 40.0;

  CanvasModel(this.policySet);

  FlexiData getFlexi() {
    for (final component in components.values) {
      if (!_hasToJsonMethodAtComponent(component)) {
        throw ArgumentError(
          'ComponentData.data does not have a toJson() method.',
        );
      }
    }

    return FlexiData(
      components: components.values.toList(),
      connections: connections.values.toList(),
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

  void updateCanvas() {
    notifyListeners();
  }

  bool componentExists(String id) {
    return components.containsKey(id);
  }

  Component getComponent(String id) {
    return components[id]!;
  }

  HashMap<String, Component> getAllComponents() {
    return components;
  }

  String addComponent(Component componentData) {
    components[componentData.id] = componentData;
    notifyListeners();
    return componentData.id;
  }

  void removeComponent(String id) {
    components.remove(id);
    // 컴포넌트 삭제 시 관련된 연결선도 삭제
    connections.removeWhere(
      (key, value) =>
          value.sourceComponentId == id || value.targetComponentId == id,
    );
    notifyListeners();
  }

  void removeAllComponents() {
    components.clear();
    connections.clear();
    notifyListeners();
  }

  void setComponentZOrder(String componentId, int zOrder) {
    getComponent(componentId).zOrder = zOrder;
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

  // 연결선 관련 메서드
  void addConnection(Connection connection) {
    connections[connection.id] = connection;
    notifyListeners();
  }

  void removeConnection(String id) {
    connections.remove(id);
    notifyListeners();
  }

  Connection getConnection(String id) {
    return connections[id]!;
  }

  // 그리드 설정 관련 메서드
  void setGridType(GridType type) {
    gridType = type;
    notifyListeners();
  }

  void setGridColor(Color color) {
    gridColor = color;
    notifyListeners();
  }

  void setGridSpacing(double spacing) {
    gridSpacing = spacing;
    notifyListeners();
  }
}
