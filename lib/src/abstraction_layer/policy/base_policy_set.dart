import 'package:flexi_editor/src/abstraction_layer/state/canvas_reader.dart';
import 'package:flexi_editor/src/abstraction_layer/state/canvas_writer.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';

class BasePolicySet {
  late CanvasReader canvasReader;
  late CanvasWriter canvasWriter;
  late CanvasEvent canvasEvent;

  void initializePolicy(
    CanvasReader canvasReader,
    CanvasWriter canvasWriter,
    CanvasEvent canvasEvent,
  ) {
    this.canvasReader = canvasReader;
    this.canvasWriter = canvasWriter;
    this.canvasEvent = canvasEvent;
  }
}
