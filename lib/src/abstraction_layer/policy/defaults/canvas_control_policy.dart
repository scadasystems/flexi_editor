
import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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
    canvasWriter.state.setPosition((_basePosition * transformScale) + transformPosition);
    canvasWriter.state.setScale(transformScale * _baseScale);
    canUpdateCanvasModel = false;
  }

  void onCanvasPointerSignal(PointerSignalEvent event) {
    // 트랙패드 두 손가락 스크롤 이벤트 처리 (캔버스 이동)
    if (event is PointerScrollEvent) {
      // 스크롤 델타를 캔버스 이동으로 변환
      Offset panDelta = event.scrollDelta;
      
      // 캔버스 위치 업데이트 (스크롤 방향의 반대로 이동)
      canvasWriter.state.updatePosition(-panDelta);
      canvasWriter.state.updateCanvas();
      return;
    }

    // 트랙패드 Scale 이벤트 처리 (Pinch Zoom)
    if (event.runtimeType.toString().contains('Scale')) {
      try {
        // 이벤트에서 스케일 정보 추출
        final dynamic scaleEvent = event;
        dynamic scaleValue;
        
        try { scaleValue = scaleEvent.scale; } catch (_) {}
        
        if (scaleValue != null && scaleValue != 1.0) {
          double scaleChange = scaleValue;
          scaleChange = keepScaleInBounds(scaleChange, canvasReader.state.scale);
          
          if (scaleChange == 0.0) return;

          double previousScale = canvasReader.state.scale;
          Offset previousPosition = canvasReader.state.position;

          canvasWriter.state.updateScale(scaleChange);

          // 포커스 포인트 계산 (트랙패드 pinch 중심점)
          Offset focalPoint;
          try { 
            focalPoint = scaleEvent.focalPoint ?? scaleEvent.localPosition ?? event.localPosition;
          } catch (_) {
            focalPoint = event.localPosition;
          }
          
          var relativeFocalPoint = (focalPoint - previousPosition);
          var focalPointScaled = relativeFocalPoint * (canvasReader.state.scale / previousScale);

          canvasWriter.state.updatePosition(relativeFocalPoint - focalPointScaled);
          canvasWriter.state.updateCanvas();
        }
      } catch (e) {
        // Scale 이벤트 처리 실패 시 무시
      }
    }
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
