
import 'package:flexi_editor/src/abstraction_layer/state/model_reader.dart';
import 'package:flexi_editor/src/abstraction_layer/state/state_reader.dart';

class CanvasReader {
  final CanvasModelReader model;
  final CanvasStateReader state;

  CanvasReader(this.model, this.state);
}
