import 'package:flexi_editor/src/abstraction_layer/state/model_reader.dart';
import 'package:flexi_editor/src/abstraction_layer/state/state_reader.dart';

/// 에디터의 읽기 전용 API 묶음입니다.
///
/// 정책(Policy)이나 외부 코드에서 캔버스 상태/모델을 안전하게 조회할 때 사용합니다.
class CanvasReader {
  /// 모델(컴포넌트/링크) 조회 API입니다.
  final CanvasModelReader model;

  /// 캔버스 뷰(스케일/좌표 변환/색상 등) 조회 API입니다.
  final CanvasStateReader state;

  /// [model]과 [state]를 묶어 제공합니다.
  CanvasReader(this.model, this.state);
}
