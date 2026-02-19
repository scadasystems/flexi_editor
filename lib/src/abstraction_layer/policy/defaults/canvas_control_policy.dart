import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  void onCanvasScaleStart(ScaleStartDetails details) {
    _baseScale = canvasReader.state.scale;
    _basePosition = canvasReader.state.position;

    _lastFocalPoint = details.focalPoint;
  }

  void onCanvasScaleUpdate(ScaleUpdateDetails details) {
    if (!canUpdateCanvasModel) return;

    if (_animationController?.isAnimating == false) {
      _animationController?.repeat();
    }

    double previousScale = transformScale;

    // Position and scale transformation
    transformPosition += details.focalPoint - _lastFocalPoint;
    transformScale = keepScaleInBounds(details.scale, _baseScale);

    var focalPoint = (details.localFocalPoint - transformPosition);
    var focalPointScaled = focalPoint * (transformScale / previousScale);

    _lastFocalPoint = details.focalPoint;

    transformPosition += focalPoint - focalPointScaled;

    if (_animationController?.isAnimating == true) {
      _animationController?.reset();
    }
  }

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
          Offset panDelta = event.scrollDelta;
          canvasWriter.state.updatePosition(-panDelta);
          canvasWriter.state.updateCanvas();
        }
      } else if (deviceType == PointerDeviceKind.mouse) {
        // 마우스 스크롤 → 부드러운 줌 기능
        _handleMouseScrollZoom(event);
      } else {
        // 기타 장치는 기본 동작 (캔버스 이동)
        Offset panDelta = event.scrollDelta;
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

  void zoomTowards({
    required double zoomFactor,
    required Offset focalPoint,
  }) {
    if (zoomFactor == 1.0) return;

    double currentScale = canvasReader.state.scale;
    double newScale = _clampScale(currentScale * zoomFactor);

    if (newScale != currentScale) {
      Offset currentPosition = canvasReader.state.position;

      var relativeFocalPoint = (focalPoint - currentPosition);
      var focalPointScaled = relativeFocalPoint * (newScale / currentScale);

      Offset newPosition =
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
    double scaleChange =
        keepScaleInBounds(scaleValue, canvasReader.state.scale);

    if (scaleChange == 0.0) return;

    double previousScale = canvasReader.state.scale;
    Offset previousPosition = canvasReader.state.position;

    canvasWriter.state.updateScale(scaleChange);

    var relativeFocalPoint = (focalPoint - previousPosition);
    var focalPointScaled =
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
