
import 'dart:async';

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
  Timer? _mouseScrollTimer;
  bool _isMouseScrolling = false;

  AnimationController? getAnimationController() {
    return _animationController;
  }

  void setAnimationController(AnimationController animationController) {
    _animationController = animationController;
  }

  void disposeAnimationController() {
    _animationController?.dispose();
    _mouseScrollTimer?.cancel();
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
    if (_isMouseScrolling) {
      // 마우스 스크롤 줌의 경우 이미 실시간으로 위치가 업데이트되었으므로
      // 스케일만 업데이트
      canvasWriter.state.setScale(transformScale * _baseScale);
    } else {
      // 기존 pinch/pan 로직
      canvasWriter.state.setPosition((_basePosition * transformScale) + transformPosition);
      canvasWriter.state.setScale(transformScale * _baseScale);
    }
    canUpdateCanvasModel = false;
  }

  void onCanvasPointerSignal(PointerSignalEvent event) {
    // PointerScrollEvent 처리 - 장치 타입에 따라 다르게 처리
    if (event is PointerScrollEvent) {
      final deviceType = event.kind;
      
      if (deviceType == PointerDeviceKind.trackpad) {
        // 트랙패드 두 손가락 스크롤 → 캔버스 이동
        Offset panDelta = event.scrollDelta;
        canvasWriter.state.updatePosition(-panDelta);
        canvasWriter.state.updateCanvas();
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

  void _handleMouseScrollZoom(PointerScrollEvent event) {
    // 첫 번째 스크롤에서 초기화
    if (!canUpdateCanvasModel) {
      _baseScale = canvasReader.state.scale;
      _basePosition = canvasReader.state.position;
      canUpdateCanvasModel = true;
      _isMouseScrolling = true;
    }
    
    const double zoomSensitivity = 0.08;
    double zoomFactor = 1.0;
    
    // 스크롤 방향에 따라 줌 인/아웃
    if (event.scrollDelta.dy < 0) {
      // 위로 스크롤 = 줌 인
      zoomFactor = 1.0 + zoomSensitivity;
    } else if (event.scrollDelta.dy > 0) {
      // 아래로 스크롤 = 줌 아웃  
      zoomFactor = 1.0 - zoomSensitivity;
    }
    
    if (zoomFactor == 1.0) return;
    
    // 현재 캔버스 상태
    double currentScale = canvasReader.state.scale;
    Offset currentPosition = canvasReader.state.position;
    
    // 새로운 스케일 계산
    double newScale = _clampScale(currentScale * zoomFactor);
    
    if (newScale != currentScale) {
      // 마우스 위치를 중심으로 줌
      Offset focalPoint = event.localPosition;
      var relativeFocalPoint = (focalPoint - currentPosition);
      var focalPointScaled = relativeFocalPoint * (newScale / currentScale);
      
      Offset newPosition = currentPosition + (relativeFocalPoint - focalPointScaled);
      
      // 캔버스 상태를 즉시 업데이트
      canvasWriter.state.setScale(newScale);
      canvasWriter.state.setPosition(newPosition);
      canvasWriter.state.updateCanvas();
      
      // Transform 값도 업데이트 (애니메이션용)
      transformScale = newScale / _baseScale;
      transformPosition = newPosition - _basePosition;
      
      // 애니메이션 시작
      if (_animationController?.isAnimating == false) {
        _animationController?.repeat();
      }
      if (_animationController?.isAnimating == true) {
        _animationController?.reset();
      }
    }
    
    // 스크롤 종료를 위한 타이머 설정
    _resetMouseScrollTimer();
  }
  
  void _resetMouseScrollTimer() {
    _mouseScrollTimer?.cancel();
    _mouseScrollTimer = Timer(const Duration(milliseconds: 150), () {
      if (canUpdateCanvasModel) {
        if (_isMouseScrolling) {
          // 마우스 스크롤 줌 종료 - 애니메이션만 정리
          _animationController?.reset();
          transformPosition = const Offset(0, 0);
          transformScale = 1.0;
          _isMouseScrolling = false;
        } else {
          // 기존 pinch/pan 로직
          _updateCanvasModelWithLastValues();
          _animationController?.reset();
          transformPosition = const Offset(0, 0);
          transformScale = 1.0;
        }
        canUpdateCanvasModel = false;
        canvasWriter.state.updateCanvas();
      }
    });
  }

  double _clampScale(double scale) {
    return scale.clamp(canvasReader.state.minScale, canvasReader.state.maxScale);
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
