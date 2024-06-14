import 'dart:collection';
import 'dart:convert';

import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/canvas_context/canvas_state.dart';
import 'package:flexi_editor/src/canvas_context/model/component_data.dart';
import 'package:flexi_editor/src/canvas_context/model/link_data.dart';
import 'package:flutter/material.dart';

class CanvasModelReader {
  final CanvasModel canvasModel;
  final CanvasState canvasState;

  CanvasModelReader(this.canvasModel, this.canvasState);

  bool componentExist(String id) {
    return canvasModel.componentExists(id);
  }

  ComponentData getComponent(String id) {
    assert(componentExist(id), 'model does not contain this component id: $id');
    return canvasModel.getComponent(id);
  }

  HashMap<String, ComponentData> getAllComponents() {
    return canvasModel.getAllComponents();
  }

  bool linkExist(String id) {
    return canvasModel.linkExists(id);
  }

  LinkData getLink(String id) {
    assert(linkExist(id), 'model does not contain this link id: $id');
    return canvasModel.getLink(id);
  }

  HashMap<String, LinkData> getAllLinks() {
    return canvasModel.getAllLinks();
  }

  int? determineLinkSegmentIndex(
    String linkId,
    Offset tapPosition,
  ) {
    return canvasModel.getLink(linkId).determineLinkSegmentIndex(
          tapPosition,
          canvasState.position,
          canvasState.scale,
        );
  }

  String serializeFlexi() {
    return jsonEncode(canvasModel.getFlexi());
  }
}
