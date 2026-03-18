import 'package:flexi_editor/src/canvas_context/canvas_state.dart';
import 'package:flexi_editor/src/canvas_context/canvas_dotted_background_config.dart';
import 'package:flexi_editor/src/canvas_context/model/component.dart';
import 'package:flutter/material.dart';

/// 캔버스 뷰 상태(스케일/위치/좌표 변환 등)를 조회하는 API입니다.
class CanvasStateReader {
  final CanvasState canvasState;

  /// [canvasState]를 감싸 읽기 전용 형태로 노출합니다.
  CanvasStateReader(this.canvasState);

  /// 화면 좌표계에서 캔버스가 이동(패닝)된 오프셋입니다.
  Offset get position => canvasState.position;

  /// 캔버스 스케일(줌) 값입니다.
  double get scale => canvasState.scale;

  /// 마우스 스크롤 줌 민감도입니다.
  double get mouseScaleSpeed => canvasState.mouseScaleSpeed;

  /// 캔버스가 가질 수 있는 최대 스케일입니다.
  double get maxScale => canvasState.maxScale;

  /// 캔버스가 가질 수 있는 최소 스케일입니다.
  double get minScale => canvasState.minScale;

  /// 캔버스 배경색입니다.
  Color get color => canvasState.color;

  /// 도트 배경 설정입니다.
  CanvasDottedBackgroundConfig get dottedBackground =>
      canvasState.dottedBackground;

  /// 캔버스 좌표(월드 좌표)인 [position]을 화면 좌표(위젯 로컬 좌표)로 변환합니다.
  Offset fromCanvasCoordinates(Offset position) {
    return canvasState.fromCanvasCoordinates(position);
  }

  /// 화면 좌표(위젯 로컬 좌표)인 [position]을 캔버스 좌표(월드 좌표)로 변환합니다.
  Offset toCanvasCoordinates(Offset position) {
    return canvasState.toCanvasCoordinates(position);
  }

  /// 화면 픽셀 단위 [size]를 캔버스 좌표계 길이로 변환합니다.
  double toCanvasSize(double size) {
    return canvasState.toCanvasSize(size);
  }

  /// 모든 컴포넌트의 경계를 계산합니다.
  Rect calculateComponentsBounds(List<Component> components) {
    return canvasState.calculateComponentsBounds(components);
  }
}
