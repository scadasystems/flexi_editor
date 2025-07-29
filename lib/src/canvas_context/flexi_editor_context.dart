import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/abstraction_layer/state/state_reader.dart';
import 'package:flexi_editor/src/abstraction_layer/state/state_writer.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flexi_editor/src/canvas_context/canvas_model.dart';

class FlexiEditorContext {
  final CanvasModel _canvasModel;
  final CanvasState _canvasState;
  final CanvasEvent _canvasEvent;

  final PolicySet policySet;

  CanvasModel get canvasModel => _canvasModel;
  CanvasState get canvasState => _canvasState;
  CanvasEvent get canvasEvent => _canvasEvent;

  FlexiEditorContext(this.policySet)
      : _canvasModel = CanvasModel(policySet),
        _canvasEvent = CanvasEvent(),
        _canvasState = CanvasState() {
    policySet.initializePolicy(_getReader(), _getWriter(), _canvasEvent);
  }

  FlexiEditorContext.withSharedModel(
    FlexiEditorContext oldContext, {
    required this.policySet,
  })  : _canvasModel = oldContext.canvasModel,
        _canvasEvent = CanvasEvent(),
        _canvasState = CanvasState() {
    policySet.initializePolicy(_getReader(), _getWriter(), _canvasEvent);
  }

  FlexiEditorContext.withSharedState(
    FlexiEditorContext oldContext, {
    required this.policySet,
  })  : _canvasModel = CanvasModel(policySet),
        _canvasEvent = CanvasEvent(),
        _canvasState = oldContext.canvasState {
    policySet.initializePolicy(_getReader(), _getWriter(), _canvasEvent);
  }

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
