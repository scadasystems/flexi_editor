
import 'package:flexi_editor/src/abstraction_layer/state/model_writer.dart';
import 'package:flexi_editor/src/abstraction_layer/state/state_writer.dart';

class CanvasWriter {
  final CanvasModelWriter model;
  final CanvasStateWriter state;

  CanvasWriter(this.model, this.state);
}
