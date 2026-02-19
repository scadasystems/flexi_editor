import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flexi_editor/src/canvas_context/model/component.dart';
import 'package:flutter/material.dart';

mixin GroupPolicy on BasePolicySet {
  /// 그룹 해제
  void ungroupComponent(String groupId) {
    if (!canvasReader.model.componentExist(groupId)) return;
    final groupComponent = canvasReader.model.getComponent(groupId);

    // 그룹이 아니면 무시
    if (groupComponent.type != 'group') return;

    final childrenIds = List<String>.from(groupComponent.childrenIds);
    final groupPosition = groupComponent.position;

    // 1. 자식들의 위치를 절대 좌표로 변환하고 부모 관계 해제
    for (final childId in childrenIds) {
      final child = canvasReader.model.getComponent(childId);

      // 절대 좌표 계산 (그룹 위치 + 자식의 상대 위치)
      // 주의: 자식의 position은 이미 상대 좌표로 저장되어 있음
      final absolutePosition = groupPosition + child.position;

      // 먼저 부모 관계를 끊어야 함 (removeComponentParent 내부에서 removeChild 호출됨)
      canvasWriter.model.removeComponentParent(childId);

      // 위치 업데이트
      canvasWriter.model.setComponentPosition(childId, absolutePosition);
    }

    // 2. 그룹 컴포넌트 삭제
    canvasWriter.model.removeComponent(groupId);
  }

  void groupSelectedComponents(List<String> componentIds) {
    if (componentIds.isEmpty) return;

    // 1. 선택된 컴포넌트들의 경계 상자(Bounding Box) 계산
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    final components =
        componentIds.map((id) => canvasReader.model.getComponent(id)).toList();

    for (final component in components) {
      if (component.position.dx < minX) minX = component.position.dx;
      if (component.position.dy < minY) minY = component.position.dy;
      if (component.position.dx + component.size.width > maxX) {
        maxX = component.position.dx + component.size.width;
      }
      if (component.position.dy + component.size.height > maxY) {
        maxY = component.position.dy + component.size.height;
      }
    }

    // 그룹에 약간의 패딩 추가 (선택 사항)
    // const padding = 20.0;
    // minX -= padding;
    // minY -= padding;
    // maxX += padding;
    // maxY += padding;

    final groupPosition = Offset(minX, minY);
    final groupSize = Size(maxX - minX, maxY - minY);

    // 2. 그룹 컴포넌트 생성 및 추가
    final groupId = DateTime.now().millisecondsSinceEpoch.toString();
    final groupComponent = Component(
      id: groupId,
      type: 'group',
      position: groupPosition,
      size: groupSize,
    );
    canvasWriter.model.addComponent(groupComponent);

    // 3. 자식 컴포넌트들을 그룹으로 이동
    for (final id in componentIds) {
      final component = canvasReader.model.getComponent(id);

      // 상대 좌표 계산 (현재 절대 좌표 - 그룹 좌표)
      final relativePosition = component.position - groupPosition;

      // 위치 업데이트 (절대 좌표 -> 상대 좌표)
      canvasWriter.model.setComponentPosition(id, relativePosition);

      // 부모 설정 (이 과정에서 그룹의 childrenIds에도 추가됨)
      canvasWriter.model.setComponentParent(id, groupId);
    }

    // 그룹을 맨 뒤로 보내서 자식들이 위에 보이게 함 (Z-Order 관리)
    // 하지만 자식들이 그룹 위에 그려지려면 그룹이 먼저 그려져야 함 (Stack 구조상)
    // FlexiEditor는 Z-Order를 사용하여 그리기 순서를 제어함.
    // 그룹의 Z-Order를 가장 낮게 설정하거나, 자식들을 높게 설정해야 함.

    // 간단하게 자식들을 맨 앞으로 가져오기
    for (final id in componentIds) {
      canvasWriter.model.moveComponentToTheFront(id);
    }
  }
}
