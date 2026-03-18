import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/abstraction_layer/state/state_reader.dart';
import 'package:flexi_editor/src/abstraction_layer/state/state_writer.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flexi_editor/src/canvas_context/canvas_model.dart';

/// FlexiEditor가 동작하는 데 필요한 핵심 객체 묶음입니다.
///
/// - 모델: 컴포넌트/링크 데이터([CanvasModel])
/// - 상태: 캔버스 뷰 상태([CanvasState])
/// - 이벤트: 입력 처리 상태([CanvasEvent])
/// - 정책: 동작/위젯 확장 포인트([PolicySet])
class FlexiEditorContext {
  final CanvasModel _canvasModel;
  final CanvasState _canvasState;
  final CanvasEvent _canvasEvent;

  /// 에디터의 동작 규칙(Policy) 집합입니다.
  final PolicySet policySet;

  CanvasModel get canvasModel => _canvasModel;
  CanvasState get canvasState => _canvasState;
  CanvasEvent get canvasEvent => _canvasEvent;

  /// 새 모델/상태/이벤트를 생성하여 컨텍스트를 만듭니다.
  ///
  /// - [policySet]은 생성 직후 `initializePolicy`가 호출됩니다.
  FlexiEditorContext(this.policySet)
      : _canvasModel = CanvasModel(policySet),
        _canvasEvent = CanvasEvent(),
        _canvasState = CanvasState() {
    policySet.initializePolicy(_getReader(), _getWriter(), _canvasEvent);
  }

  /// 기존 컨텍스트의 **모델만 공유**하고, 상태/이벤트는 새로 생성합니다.
  ///
  /// - [oldContext]의 [CanvasModel]을 재사용합니다.
  /// - [policySet]은 새 컨텍스트 기준으로 다시 초기화됩니다.
  FlexiEditorContext.withSharedModel(
    FlexiEditorContext oldContext, {
    required this.policySet,
  })  : _canvasModel = oldContext.canvasModel,
        _canvasEvent = CanvasEvent(),
        _canvasState = CanvasState() {
    policySet.initializePolicy(_getReader(), _getWriter(), _canvasEvent);
  }

  /// 기존 컨텍스트의 **상태만 공유**하고, 모델/이벤트는 새로 생성합니다.
  ///
  /// - [oldContext]의 [CanvasState]를 재사용합니다.
  /// - [policySet]은 새 컨텍스트 기준으로 다시 초기화됩니다.
  FlexiEditorContext.withSharedState(
    FlexiEditorContext oldContext, {
    required this.policySet,
  })  : _canvasModel = CanvasModel(policySet),
        _canvasEvent = CanvasEvent(),
        _canvasState = oldContext.canvasState {
    policySet.initializePolicy(_getReader(), _getWriter(), _canvasEvent);
  }

  /// 기존 컨텍스트의 **모델과 상태를 모두 공유**하고, 이벤트만 새로 생성합니다.
  ///
  /// - [oldContext]의 [CanvasModel], [CanvasState]를 재사용합니다.
  /// - [policySet]은 새 컨텍스트 기준으로 다시 초기화됩니다.
  FlexiEditorContext.withSharedModelAndState(
    FlexiEditorContext oldContext, {
    required this.policySet,
  })  : _canvasModel = oldContext.canvasModel,
        _canvasEvent = CanvasEvent(),
        _canvasState = oldContext.canvasState {
    policySet.initializePolicy(_getReader(), _getWriter(), _canvasEvent);
  }

  CanvasReader _getReader() {
    return CanvasReader(
      CanvasModelReader(canvasModel, canvasState),
      CanvasStateReader(canvasState),
    );
  }

  CanvasWriter _getWriter() {
    return CanvasWriter(
      CanvasModelWriter(canvasModel, canvasState),
      CanvasStateWriter(canvasState),
    );
  }
}
