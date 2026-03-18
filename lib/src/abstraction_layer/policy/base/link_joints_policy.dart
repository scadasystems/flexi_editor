import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flutter/material.dart';

/// 링크의 조인트(꺾이는 점, 중간점)에서 발생하는 입력 이벤트를 처리하는 정책입니다.
///
/// - [jointIndex]는 링크의 `linkPoints`에서 조인트 위치를 가리키는 인덱스입니다.
/// - [linkId]는 대상 링크의 id입니다.
mixin LinkJointPolicy on BasePolicySet {
  /// 특정 조인트([jointIndex])에서 제스처를 활성화할지 여부를 반환합니다.
  bool isLinkJointGestureEnabled(int jointIndex, String linkId) {
    return true;
  }

  /// 링크 조인트를 탭했을 때 호출됩니다.
  void onLinkJointTap(int jointIndex, String linkId) {}

  /// 링크 조인트 탭이 시작될 때 호출됩니다.
  void onLinkJointTapDown(
      int jointIndex, String linkId, TapDownDetails details) {}

  /// 링크 조인트 탭이 끝날 때 호출됩니다.
  void onLinkJointTapUp(int jointIndex, String linkId, TapUpDetails details) {}

  /// 링크 조인트 탭 제스처가 취소될 때 호출됩니다.
  void onLinkJointTapCancel(int jointIndex, String linkId) {}

  /// 링크 조인트 스케일 제스처(드래그/핀치)가 시작될 때 호출됩니다.
  void onLinkJointScaleStart(
      int jointIndex, String linkId, ScaleStartDetails details) {}

  /// 링크 조인트 스케일 제스처가 갱신될 때 호출됩니다.
  void onLinkJointScaleUpdate(
      int jointIndex, String linkId, ScaleUpdateDetails details) {}

  /// 링크 조인트 스케일 제스처가 끝날 때 호출됩니다.
  void onLinkJointScaleEnd(
      int jointIndex, String linkId, ScaleEndDetails details) {}

  /// 링크 조인트를 길게 눌렀을 때 호출됩니다.
  void onLinkJointLongPress(int jointIndex, String linkId) {}

  /// 링크 조인트 롱프레스가 시작될 때 호출됩니다.
  void onLinkJointLongPressStart(
      int jointIndex, String linkId, LongPressStartDetails details) {}

  /// 링크 조인트 롱프레스 중 포인터가 이동할 때 호출됩니다.
  void onLinkJointLongPressMoveUpdate(
      int jointIndex, String linkId, LongPressMoveUpdateDetails details) {}

  /// 링크 조인트 롱프레스가 끝날 때 호출됩니다.
  void onLinkJointLongPressEnd(
      int jointIndex, String linkId, LongPressEndDetails details) {}

  /// 링크 조인트 롱프레스가 포인터 업으로 종료될 때 호출됩니다.
  void onLinkJointLongPressUp(int jointIndex, String linkId) {}
}
