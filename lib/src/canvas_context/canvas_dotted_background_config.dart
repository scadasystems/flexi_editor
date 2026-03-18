import 'package:flutter/material.dart';

/// 캔버스 배경에 표시되는 도트(점) 그리드 설정입니다.
///
/// - `*Canvas`로 끝나는 값들은 **캔버스 좌표계(월드 좌표)** 기준입니다.
/// - 실제 화면에 그릴 때는 현재 `canvasScale`이 곱해져 픽셀 단위로 변환됩니다.
class CanvasDottedBackgroundConfig {
  /// 도트 배경 표시 여부입니다.
  final bool enabled;

  /// 도트(점) 간격입니다(캔버스 좌표계).
  final double gridSpacingCanvas;

  /// 스냅 판정 임계값입니다(캔버스 좌표계).
  ///
  /// 도트 그리드에 스냅할 때, 목표 지점과 그리드 점 사이의 거리가 이 값보다 작으면 스냅될 수 있습니다.
  final double snapThresholdCanvas;

  /// 도트(점) 반지름입니다(캔버스 좌표계).
  final double dotRadiusCanvas;

  /// 이 값보다 `canvasScale`이 작으면 도트 배경을 그리지 않습니다.
  ///
  /// - `0`이면 항상 표시합니다(기본값).
  final double minVisibleScale;

  /// 도트 색상입니다(알파 포함).
  final Color color;

  const CanvasDottedBackgroundConfig({
    this.enabled = false,
    this.gridSpacingCanvas = 24,
    this.snapThresholdCanvas = 6,
    this.dotRadiusCanvas = 1,
    this.minVisibleScale = 0,
    this.color = const Color(0x332563EB),
  });

  CanvasDottedBackgroundConfig copyWith({
    bool? enabled,
    double? gridSpacingCanvas,
    double? snapThresholdCanvas,
    double? dotRadiusCanvas,
    double? minVisibleScale,
    Color? color,
  }) {
    return CanvasDottedBackgroundConfig(
      enabled: enabled ?? this.enabled,
      gridSpacingCanvas: gridSpacingCanvas ?? this.gridSpacingCanvas,
      snapThresholdCanvas: snapThresholdCanvas ?? this.snapThresholdCanvas,
      dotRadiusCanvas: dotRadiusCanvas ?? this.dotRadiusCanvas,
      minVisibleScale: minVisibleScale ?? this.minVisibleScale,
      color: color ?? this.color,
    );
  }
}
