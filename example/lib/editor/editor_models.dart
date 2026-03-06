import 'package:flutter/material.dart';

class EditorShapeData {
  final int fillColorValue;
  final int strokeColorValue;
  final double strokeWidth;
  final double cornerRadius;
  final double rotationRadians;

  const EditorShapeData({
    required this.fillColorValue,
    required this.strokeColorValue,
    required this.strokeWidth,
    required this.cornerRadius,
    required this.rotationRadians,
  });

  Color get fillColor => Color(fillColorValue);
  Color get strokeColor => Color(strokeColorValue);

  Map<String, dynamic> toJson() => {
        'fill': fillColorValue,
        'stroke': strokeColorValue,
        'strokeWidth': strokeWidth,
        'cornerRadius': cornerRadius,
        'rotationRadians': rotationRadians,
      };

  EditorShapeData copyWith({
    int? fillColorValue,
    int? strokeColorValue,
    double? strokeWidth,
    double? cornerRadius,
    double? rotationRadians,
  }) {
    return EditorShapeData(
      fillColorValue: fillColorValue ?? this.fillColorValue,
      strokeColorValue: strokeColorValue ?? this.strokeColorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      rotationRadians: rotationRadians ?? this.rotationRadians,
    );
  }
}
