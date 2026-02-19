import 'dart:collection';

import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/model/flexi_data.dart';
import 'package:flutter/material.dart';

class CanvasModel with ChangeNotifier {
  HashMap<String, Component> components = HashMap();
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

    return FlexiData(
      components: components.values.toList(),
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
    notifyListeners();
  }

  void removeAllComponents() {
    components.clear();
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
}
