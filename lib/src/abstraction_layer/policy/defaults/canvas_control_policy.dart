import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 캔버스의 이동/줌(스케일) 동작을 기본 구현으로 제공하는 정책입니다.
///
/// 제스처 이벤트의 `details`는 Flutter가 제공하는 값이며, 좌표는 위젯 로컬 좌표(화면) 기준입니다.
mixin CanvasControlPolicy on BasePolicySet {
  AnimationController? _animationController;
  double _baseScale = 1.0;
  Offset _basePosition = const Offset(0, 0);

  Offset _lastFocalPoint = const Offset(0, 0);

  Offset transformPosition = const Offset(0, 0);
  double transformScale = 1.0;

  bool canUpdateCanvasModel = false;

  AnimationController? getAnimationController() {
    return _animationController;
  }

  void setAnimationController(AnimationController animationController) {
    _animationController = animationController;
  }

  void disposeAnimationController() {
    _animationController?.dispose();
  }

  /// 캔버스 스케일 제스처가 시작될 때 호출됩니다.
  ///
  /// - [details]: 포커스/포인터 카운트 등 제스처 정보
  void onCanvasScaleStart(ScaleStartDetails details) {
    _baseScale = canvasReader.state.scale;
    _basePosition = canvasReader.state.position;

    _lastFocalPoint = details.focalPoint;
  }

  /// 캔버스 스케일 제스처가 갱신될 때 호출됩니다.
  ///
  /// - [details]: 스케일/이동 델타 등 제스처 정보
  void onCanvasScaleUpdate(ScaleUpdateDetails details) {
    if (!canUpdateCanvasModel) return;

    if (_animationController?.isAnimating == false) {
      _animationController?.repeat();
    }

    final double previousScale = transformScale;

    // Position and scale transformation
    transformPosition += details.focalPoint - _lastFocalPoint;
    transformScale = keepScaleInBounds(details.scale, _baseScale);

    final focalPoint = (details.localFocalPoint - transformPosition);
    final focalPointScaled = focalPoint * (transformScale / previousScale);

    _lastFocalPoint = details.focalPoint;

    transformPosition += focalPoint - focalPointScaled;

    if (_animationController?.isAnimating == true) {
      _animationController?.reset();
    }
  }

  /// 캔버스 스케일 제스처가 끝날 때 호출됩니다.
  void onCanvasScaleEnd(ScaleEndDetails details) {
    if (canUpdateCanvasModel) {
      _updateCanvasModelWithLastValues();
    }

    _animationController?.reset();

    transformPosition = const Offset(0, 0);
    transformScale = 1.0;

    canvasWriter.state.updateCanvas();
  }

  void _updateCanvasModelWithLastValues() {
    canvasWriter.state
        .setPosition((_basePosition * transformScale) + transformPosition);
    canvasWriter.state.setScale(transformScale * _baseScale);
    canUpdateCanvasModel = false;
  }

  /// 마우스 휠/트랙패드 스크롤 등 포인터 시그널을 캔버스 이동/줌으로 변환합니다.
  ///
  /// - [event]: PointerScrollEvent 등
  void onCanvasPointerSignal(PointerSignalEvent event) {
    // PointerScrollEvent 처리 - 장치 타입에 따라 다르게 처리
    if (event is PointerScrollEvent) {
      final deviceType = event.kind;

      if (deviceType == PointerDeviceKind.trackpad) {
        // 트랙패드에서 pinch zoom을 위한 특별 처리
        if (_isTrackpadPinchGesture()) {
          _handleTrackpadPinch(event);
        } else {
          // 트랙패드 두 손가락 스크롤 → 캔버스 이동
          final Offset panDelta = event.scrollDelta;
          canvasWriter.state.updatePosition(-panDelta);
          canvasWriter.state.updateCanvas();
        }
      } else if (deviceType == PointerDeviceKind.mouse) {
        // 마우스 스크롤 → 부드러운 줌 기능
        _handleMouseScrollZoom(event);
      } else {
        // 기타 장치는 기본 동작 (캔버스 이동)
        final Offset panDelta = event.scrollDelta;
        canvasWriter.state.updatePosition(-panDelta);
        canvasWriter.state.updateCanvas();
      }
      return;
    }

    // 다른 포인터 시그널 이벤트들 처리
    _tryHandleScaleEvent(event);
  }

  bool _isTrackpadPinchGesture() {
    // 트랙패드 pinch는 웹에서 Ctrl+Scroll로 감지됨
    if (HardwareKeyboard.instance.isControlPressed) {
      return true;
    } else {
      return false;
    }
  }

  /// [focalPoint]를 기준으로 [zoomFactor]만큼 줌 인/아웃합니다.
  ///
  /// - [zoomFactor]: `> 1`이면 확대, `< 1`이면 축소
  /// - [focalPoint]: 줌의 기준점(위젯 로컬 좌표)
  void zoomTowards({
    required double zoomFactor,
    required Offset focalPoint,
  }) {
    if (zoomFactor == 1.0) return;

    final double currentScale = canvasReader.state.scale;
    final double newScale = _clampScale(currentScale * zoomFactor);

    if (newScale != currentScale) {
      final Offset currentPosition = canvasReader.state.position;

      final relativeFocalPoint = (focalPoint - currentPosition);
      final focalPointScaled = relativeFocalPoint * (newScale / currentScale);

      final Offset newPosition =
          currentPosition + (relativeFocalPoint - focalPointScaled);

      canvasWriter.state.setScale(newScale);
      canvasWriter.state.setPosition(newPosition);
      canvasWriter.state.updateCanvas();
    }
  }

  void _handleTrackpadPinch(PointerScrollEvent event) {
    const double sensitivity = 0.01;
    double zoomFactor = 1.0;

    // scrollDelta.dy를 기반으로 zoom 방향 결정
    if (event.scrollDelta.dy < 0) {
      zoomFactor = 1.0 + sensitivity;
    } else if (event.scrollDelta.dy > 0) {
      zoomFactor = 1.0 - sensitivity;
    }

    zoomTowards(zoomFactor: zoomFactor, focalPoint: event.localPosition);
  }

  void _tryHandleScaleEvent(PointerSignalEvent event) {
    try {
      final scaleValue = _extractScaleValue(event);
      final focalPoint = _extractFocalPoint(event);

      if (scaleValue != null && scaleValue != 1.0) {
        _handleScaleGesture(scaleValue, focalPoint ?? event.localPosition);
      }
    } catch (e) {
      // Scale 이벤트가 아니거나 처리할 수 없는 경우 무시
      debugPrint('Scale event handling failed: $e');
    }
  }

  dynamic _extractScaleValue(dynamic event) {
    try {
      return event.scale;
    } catch (_) {
      return null;
    }
  }

  Offset? _extractFocalPoint(dynamic event) {
    try {
      return event.focalPoint ?? event.localPosition;
    } catch (_) {
      try {
        return event.localPosition;
      } catch (_) {
        return null;
      }
    }
  }

  void _handleScaleGesture(double scaleValue, Offset focalPoint) {
    final double scaleChange =
        keepScaleInBounds(scaleValue, canvasReader.state.scale);

    if (scaleChange == 0.0) return;

    final double previousScale = canvasReader.state.scale;
    final Offset previousPosition = canvasReader.state.position;

    canvasWriter.state.updateScale(scaleChange);

    final relativeFocalPoint = (focalPoint - previousPosition);
    final focalPointScaled =
        relativeFocalPoint * (canvasReader.state.scale / previousScale);

    canvasWriter.state.updatePosition(relativeFocalPoint - focalPointScaled);
    canvasWriter.state.updateCanvas();
  }

  void _handleMouseScrollZoom(PointerScrollEvent event) {
    const double zoomSensitivity = 0.1;
    double zoomFactor = 1.0;

    // 스크롤 방향에 따라 줌 인/아웃
    if (event.scrollDelta.dy < 0) {
      // 위로 스크롤 = 줌 인
      zoomFactor = 1.0 + zoomSensitivity;
    } else if (event.scrollDelta.dy > 0) {
      // 아래로 스크롤 = 줌 아웃
      zoomFactor = 1.0 - zoomSensitivity;
    }

    zoomTowards(zoomFactor: zoomFactor, focalPoint: event.localPosition);
  }

  double _clampScale(double scale) {
    return scale.clamp(
        canvasReader.state.minScale, canvasReader.state.maxScale);
  }

  /// 스케일 변경값([scale])을 현재 스케일([canvasScale])과 min/max 범위에 맞게 보정합니다.
  ///
  /// - [scale]: “곱해질 값” 형태의 스케일 변화량(예: 1.1, 0.9)
  /// - [canvasScale]: 현재 캔버스의 절대 스케일
  double keepScaleInBounds(double scale, double canvasScale) {
    double scaleResult = scale;
    if (scale * canvasScale <= canvasReader.state.minScale) {
      scaleResult = canvasReader.state.minScale / canvasScale;
    }
    if (scale * canvasScale >= canvasReader.state.maxScale) {
      scaleResult = canvasReader.state.maxScale / canvasScale;
    }
    return scaleResult;
  }
}

mixin CanvasMovePolicy on BasePolicySet implements CanvasControlPolicy {
  @override
  AnimationController? _animationController;

  @override
  Offset _basePosition = const Offset(0, 0);

  @override
  Offset _lastFocalPoint = const Offset(0, 0);

  @override
  Offset transformPosition = const Offset(0, 0);
  @override
  double transformScale = 1.0;

  @override
  bool canUpdateCanvasModel = false;

  @override
  AnimationController? getAnimationController() {
    return _animationController;
  }

  @override
  void setAnimationController(AnimationController animationController) {
    _animationController = animationController;
  }

  @override
  void disposeAnimationController() {
    _animationController?.dispose();
  }

  @override
  void onCanvasScaleStart(ScaleStartDetails details) {
    _basePosition = canvasReader.state.position;

    _lastFocalPoint = details.focalPoint;
  }

  @override
  void onCanvasScaleUpdate(ScaleUpdateDetails details) {
    if (canUpdateCanvasModel) {
      _animationController?.repeat();
      _updateCanvasModelWithLastValues();

      transformPosition += details.focalPoint - _lastFocalPoint;

      _lastFocalPoint = details.focalPoint;

      _animationController?.reset();
    }
  }

  @override
  void onCanvasScaleEnd(ScaleEndDetails details) {
    if (canUpdateCanvasModel) {
      _updateCanvasModelWithLastValues();
    }

    _animationController?.reset();

    transformPosition = const Offset(0, 0);

    canvasWriter.state.updateCanvas();
  }

  @override
  void _updateCanvasModelWithLastValues() {
    canvasWriter.state.setPosition(_basePosition + transformPosition);
    canUpdateCanvasModel = false;
  }

  @override
  void onCanvasPointerSignal(PointerSignalEvent event) {}

  @override
  double keepScaleInBounds(double scale, double canvasScale) {
    return 1.0;
  }
}
