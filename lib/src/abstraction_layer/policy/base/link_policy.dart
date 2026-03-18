import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flutter/gestures.dart';

/// 링크 위젯에서 발생하는 입력 이벤트를 처리하는 정책입니다.
///
/// - [linkId]는 이벤트가 발생한 링크의 id입니다.
/// - `details`의 좌표는 기본적으로 위젯 로컬 좌표(화면) 기준입니다.
mixin LinkPolicy on BasePolicySet {
  /// 링크를 탭했을 때 호출됩니다.
  void onLinkTap(String linkId) {}

  /// 링크 탭이 시작될 때 호출됩니다.
  void onLinkTapDown(String linkId, TapDownDetails details) {}

  /// 링크 탭이 끝날 때 호출됩니다.
  void onLinkTapUp(String linkId, TapUpDetails details) {}

  /// 링크 탭 제스처가 취소될 때 호출됩니다.
  void onLinkTapCancel(String linkId) {}

  /// 링크 스케일 제스처(드래그/핀치)가 시작될 때 호출됩니다.
  void onLinkScaleStart(String linkId, ScaleStartDetails details) {}

  /// 링크 스케일 제스처가 갱신될 때 호출됩니다.
  void onLinkScaleUpdate(String linkId, ScaleUpdateDetails details) {}

  /// 링크 스케일 제스처가 끝날 때 호출됩니다.
  void onLinkScaleEnd(String linkId, ScaleEndDetails details) {}

  /// 링크를 길게 눌렀을 때 호출됩니다.
  void onLinkLongPress(String linkId) {}

  /// 링크 롱프레스가 시작될 때 호출됩니다.
  void onLinkLongPressStart(String linkId, LongPressStartDetails details) {}

  /// 링크 롱프레스 중 포인터가 이동할 때 호출됩니다.
  void onLinkLongPressMoveUpdate(
      String linkId, LongPressMoveUpdateDetails details) {}

  /// 링크 롱프레스가 끝날 때 호출됩니다.
  void onLinkLongPressEnd(String linkId, LongPressEndDetails details) {}

  /// 링크 롱프레스가 포인터 업으로 종료될 때 호출됩니다.
  void onLinkLongPressUp(String linkId) {}

  /// 링크 위에서 발생하는 포인터 시그널(스크롤 등) 이벤트를 처리합니다.
  void onLinkPointerSignal(String linkId, PointerSignalEvent event) {}
}
