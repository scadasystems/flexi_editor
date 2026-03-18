import 'package:flexi_editor/src/abstraction_layer/state/model_writer.dart';
import 'package:flexi_editor/src/abstraction_layer/state/state_writer.dart';

/// 에디터의 쓰기(변경) API 묶음입니다.
///
/// 정책(Policy)이나 외부 코드에서 모델/상태를 변경할 때 사용합니다.
class CanvasWriter {
  /// 모델(컴포넌트/링크) 변경 API입니다.
  final CanvasModelWriter model;

  /// 캔버스 뷰(스케일/위치/색상 등) 변경 API입니다.
  final CanvasStateWriter state;

  /// [model]과 [state]를 묶어 제공합니다.
  CanvasWriter(this.model, this.state);
}
