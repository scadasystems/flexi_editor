import 'package:flutter/material.dart';

class CanvasDottedBackgroundConfig {
  final bool enabled;
  final double gridSpacingCanvas;
  final double snapThresholdCanvas;
  final double dotRadiusCanvas;
  final Color color;

  const CanvasDottedBackgroundConfig({
    this.enabled = false,
    this.gridSpacingCanvas = 24,
    this.snapThresholdCanvas = 6,
    this.dotRadiusCanvas = 1,
    this.color = const Color(0x332563EB),
  });

  CanvasDottedBackgroundConfig copyWith({
    bool? enabled,
    double? gridSpacingCanvas,
    double? snapThresholdCanvas,
    double? dotRadiusCanvas,
    Color? color,
  }) {
    return CanvasDottedBackgroundConfig(
      enabled: enabled ?? this.enabled,
      gridSpacingCanvas: gridSpacingCanvas ?? this.gridSpacingCanvas,
      snapThresholdCanvas: snapThresholdCanvas ?? this.snapThresholdCanvas,
      dotRadiusCanvas: dotRadiusCanvas ?? this.dotRadiusCanvas,
      color: color ?? this.color,
    );
  }
}
