import 'dart:collection';
import 'dart:convert';

import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/canvas_context/canvas_state.dart';
import 'package:flexi_editor/src/canvas_context/model/component.dart';

class CanvasModelReader {
  final CanvasModel canvasModel;
  final CanvasState canvasState;

  CanvasModelReader(this.canvasModel, this.canvasState);

  Iterable<Component> get components => canvasModel.components.values;

  bool componentExist(String id) {
    return canvasModel.componentExists(id);
  }

  Component getComponent(String id) {
    assert(componentExist(id), 'model does not contain this component id: $id');
    return canvasModel.getComponent(id);
  }

  HashMap<String, Component> getAllComponents() {
    return canvasModel.getAllComponents();
  }

  String serializeFlexi() {
    return jsonEncode(canvasModel.getFlexi());
  }
}
