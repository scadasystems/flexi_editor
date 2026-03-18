import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flutter/gestures.dart';

/// 캔버스 배경(빈 공간)에서 발생하는 입력 이벤트를 처리하는 정책입니다.
///
/// 각 메서드의 `details`는 Flutter 제스처 시스템이 제공하는 값이며,
/// 좌표는 기본적으로 위젯 로컬 좌표(화면) 기준입니다.
mixin CanvasPolicy on BasePolicySet {
  /// 캔버스 배경을 탭했을 때 호출됩니다.
  void onCanvasTap() {}

  /// 캔버스 배경에서 탭이 시작될 때 호출됩니다.
  ///
  /// - [details]: 탭 위치/포인터 정보
  void onCanvasTapDown(TapDownDetails details) {}

  /// 캔버스 배경에서 탭이 끝날 때 호출됩니다.
  ///
  /// - [details]: 탭 업 위치/포인터 정보
  void onCanvasTapUp(TapUpDetails details) {}

  /// 캔버스 배경 탭 제스처가 취소될 때 호출됩니다.
  void onCanvasTapCancel() {}

  /// 캔버스 배경에서 스케일 제스처(핀치/드래그)가 시작될 때 호출됩니다.
  ///
  /// - [details]: 포커스/포인터 카운트 등
  void onCanvasScaleStart(ScaleStartDetails details) {}

  /// 캔버스 배경에서 스케일 제스처가 갱신될 때 호출됩니다.
  ///
  /// - [details]: 현재 스케일/이동 델타 등
  void onCanvasScaleUpdate(ScaleUpdateDetails details) {}

  /// 캔버스 배경에서 스케일 제스처가 끝날 때 호출됩니다.
  void onCanvasScaleEnd(ScaleEndDetails details) {}

  /// 내부 로직에서 사용하는 캔버스 스케일 시작 이벤트 훅입니다.
  void onCanvasScaleStartEvent(ScaleStartDetails details) {}

  /// 내부 로직에서 사용하는 캔버스 스케일 갱신 이벤트 훅입니다.
  void onCanvasScaleUpdateEvent(ScaleUpdateDetails details) {}

  /// 내부 로직에서 사용하는 캔버스 스케일 종료 이벤트 훅입니다.
  void onCanvasScaleEndEvent(ScaleEndDetails details) {}

  /// 마우스 휠/트랙패드 스크롤 같은 포인터 시그널 이벤트를 처리합니다.
  ///
  /// - [event]: PointerScrollEvent 등
  void onCanvasPointerSignal(PointerSignalEvent event) {}

  /// `true`이면 링크를 컴포넌트보다 위 레이어에 표시합니다.
  bool get showLinksOnTopOfComponents => true;
}
