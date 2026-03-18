import 'dart:collection';
import 'dart:convert';

import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/canvas_context/canvas_state.dart';
import 'package:flexi_editor/src/canvas_context/model/component.dart';
import 'package:flexi_editor/src/canvas_context/model/link_data.dart';
import 'package:flutter/material.dart';

/// 캔버스 모델(컴포넌트/링크)을 조회하는 API입니다.
///
/// 이 클래스는 정책(Policy)이나 외부 코드가 모델에 접근할 때 필요한 최소 기능을 제공합니다.
class CanvasModelReader {
  final CanvasModel canvasModel;
  final CanvasState canvasState;

  /// [canvasModel]과 [canvasState]를 함께 사용해,
  /// 월드 좌표(캔버스 좌표) 기반 연산을 수행할 수 있습니다.
  CanvasModelReader(this.canvasModel, this.canvasState);

  /// id가 [id]인 컴포넌트가 존재하는지 반환합니다.
  bool componentExist(String id) {
    return canvasModel.componentExists(id);
  }

  /// id가 [id]인 컴포넌트를 반환합니다.
  ///
  /// 존재하지 않으면 assert가 발생합니다.
  Component getComponent(String id) {
    assert(componentExist(id), 'model does not contain this component id: $id');
    return canvasModel.getComponent(id);
  }

  /// id가 [id]인 컴포넌트의 월드 좌표(캔버스 좌표) 위치를 반환합니다.
  Offset getComponentWorldPosition(String id) {
    assert(componentExist(id), 'model does not contain this component id: $id');
    return canvasModel.getComponentWorldPosition(id);
  }

  /// id가 [id]인 컴포넌트의 월드 좌표(캔버스 좌표) Rect를 반환합니다.
  Rect getComponentWorldRect(String id) {
    assert(componentExist(id), 'model does not contain this component id: $id');
    return canvasModel.getComponentWorldRect(id);
  }

  /// 모든 컴포넌트를 반환합니다.
  HashMap<String, Component> getAllComponents() {
    return canvasModel.getAllComponents();
  }

  /// id가 [id]인 링크가 존재하는지 반환합니다.
  bool linkExist(String id) {
    return canvasModel.linkExists(id);
  }

  /// id가 [id]인 링크를 반환합니다.
  ///
  /// 존재하지 않으면 assert가 발생합니다.
  LinkData getLink(String id) {
    assert(linkExist(id), 'model does not contain this link id: $id');
    return canvasModel.getLink(id);
  }

  /// 모든 링크를 반환합니다.
  HashMap<String, LinkData> getAllLinks() {
    return canvasModel.getAllLinks();
  }

  /// 링크([linkId])를 구성하는 선분들 중, [tapPosition]이 가장 가깝게 닿은 선분 인덱스를 반환합니다.
  ///
  /// - [tapPosition]은 **화면 좌표(위젯 로컬 좌표)** 를 기대합니다.
  /// - 내부적으로 현재 캔버스의 [CanvasState.position], [CanvasState.scale]을 사용해 판정합니다.
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

  /// 현재 모델을 직렬화한 문자열을 반환합니다.
  ///
  /// undo/redo 스냅샷 등 외부 저장 용도로 사용할 수 있습니다.
  String serializeFlexi() {
    return jsonEncode(canvasModel.getFlexi());
  }
}
