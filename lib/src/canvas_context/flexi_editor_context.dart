import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/abstraction_layer/state/canvas_reader.dart';
import 'package:flexi_editor/src/abstraction_layer/state/canvas_writer.dart';
import 'package:flexi_editor/src/abstraction_layer/state/model_reader.dart';
import 'package:flexi_editor/src/abstraction_layer/state/model_writer.dart';
import 'package:flexi_editor/src/abstraction_layer/state/state_reader.dart';
import 'package:flexi_editor/src/abstraction_layer/state/state_writer.dart';
import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/canvas_context/canvas_state.dart';

class FlexiEditorContext {
  final CanvasModel _canvasModel;
  final CanvasState _canvasState;

  final PolicySet policySet;

  CanvasModel get canvasModel => _canvasModel;

  CanvasState get canvasState => _canvasState;

  FlexiEditorContext({
    required this.policySet,
  })  : _canvasModel = CanvasModel(policySet),
        _canvasState = CanvasState() {
    policySet.initializePolicy(_getReader(), _getWriter());
  }

  FlexiEditorContext.withSharedModel(
    FlexiEditorContext oldContext, {
    required this.policySet,
  })  : _canvasModel = oldContext.canvasModel,
        _canvasState = CanvasState() {
    policySet.initializePolicy(_getReader(), _getWriter());
  }

  FlexiEditorContext.withSharedState(
    FlexiEditorContext oldContext, {
    required this.policySet,
  })  : _canvasModel = CanvasModel(policySet),
        _canvasState = oldContext.canvasState {
    policySet.initializePolicy(_getReader(), _getWriter());
  }

  FlexiEditorContext.withSharedModelAndState(
    FlexiEditorContext oldContext, {
    required this.policySet,
  })  : _canvasModel = oldContext.canvasModel,
        _canvasState = oldContext.canvasState {
    policySet.initializePolicy(_getReader(), _getWriter());
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
