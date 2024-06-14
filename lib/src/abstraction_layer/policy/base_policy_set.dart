import 'package:flexi_editor/src/abstraction_layer/state/canvas_reader.dart';
import 'package:flexi_editor/src/abstraction_layer/state/canvas_writer.dart';

class BasePolicySet {
  late CanvasReader canvasReader;

  late CanvasWriter canvasWriter;

  void initializePolicy(CanvasReader canvasReader, CanvasWriter canvasWriter) {
    this.canvasReader = canvasReader;
    this.canvasWriter = canvasWriter;
  }
}
