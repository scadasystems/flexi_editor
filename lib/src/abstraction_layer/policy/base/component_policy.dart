import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flutter/gestures.dart';

/// 컴포넌트 위젯에서 발생하는 입력 이벤트를 처리하는 정책입니다.
///
/// - [componentId]는 이벤트가 발생한 컴포넌트의 id입니다.
/// - `details`의 좌표는 기본적으로 위젯 로컬 좌표(화면) 기준입니다.
mixin ComponentPolicy on BasePolicySet {
  /// 마우스/포인터가 컴포넌트 영역으로 진입할 때 호출됩니다.
  void onComponentEnter(String componentId) {}

  /// 마우스/포인터가 컴포넌트 영역에서 벗어날 때 호출됩니다.
  void onComponentExit(String componentId) {}

  /// 컴포넌트를 탭했을 때 호출됩니다.
  void onComponentTap(String componentId) {}

  /// 컴포넌트 탭이 시작될 때 호출됩니다.
  void onComponentTapDown(String componentId, TapDownDetails details) {}

  /// 컴포넌트 탭이 끝날 때 호출됩니다.
  void onComponentTapUp(String componentId, TapUpDetails details) {}

  /// 컴포넌트 탭 제스처가 취소될 때 호출됩니다.
  void onComponentTapCancel(String componentId) {}

  /// 컴포넌트 스케일 제스처(드래그/핀치)가 시작될 때 호출됩니다.
  ///
  /// - [forceMove]: 특정 상황에서 “강제 이동”으로 취급해야 할 때 사용합니다.
  void onComponentScaleStart(String componentId, ScaleStartDetails details,
      {bool forceMove = false}) {}

  /// 컴포넌트 스케일 제스처가 갱신될 때 호출됩니다.
  void onComponentScaleUpdate(String componentId, ScaleUpdateDetails details) {}

  /// 컴포넌트 스케일 제스처가 끝날 때 호출됩니다.
  void onComponentScaleEnd(String componentId, ScaleEndDetails details) {}

  /// 컴포넌트 더블탭이 “다운”될 때 호출됩니다.
  void onComponentDoubleTapDown(String componentId, TapDownDetails details) {}

  /// 컴포넌트 더블탭이 확정되었을 때 호출됩니다.
  void onComponentDoubleTap(String componentId) {}
}
