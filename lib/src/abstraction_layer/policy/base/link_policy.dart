import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flexi_editor/src/canvas_context/model/connection.dart';
import 'package:flexi_editor/src/canvas_context/model/port_type.dart';
import 'package:flutter/material.dart';

mixin LinkPolicy on BasePolicySet {
  /// 링크가 생성되었을 때 호출됩니다.
  void onLinkCreated(String sourceId, String targetId) {}

  /// 링크가 삭제되었을 때 호출됩니다.
  void onLinkDeleted(String linkId) {}

  /// 링크 생성 가능 여부를 확인합니다.
  bool canCreateLink(
    String sourceId,
    PortType sourcePort,
    String targetId,
    PortType targetPort,
  ) {
    return true;
  }

  /// 연결선을 그리는 Painter를 반환합니다.
  /// [connections] : 전체 연결 리스트
  /// [scale] : 현재 캔버스 스케일
  CustomPainter? linkPainter(List<Connection> connections, double scale) {
    return null;
  }
}
