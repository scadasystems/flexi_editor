import 'dart:collection';

import 'package:flexi_editor/src/abstraction_layer/state/canvas_reader.dart';
import 'package:flexi_editor/src/abstraction_layer/state/canvas_writer.dart';
import 'package:flutter/foundation.dart';

typedef DecodeCustomData = Function(Map<String, dynamic> json);

class CanvasUndoRedoController extends ChangeNotifier {
  final int maxDepth;

  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  bool _isRestoring = false;

  CanvasUndoRedoController({this.maxDepth = 50});

  bool get canUndo => _undoStack.length > 1 && !_isRestoring;

  bool get canRedo => _redoStack.isNotEmpty && !_isRestoring;

  UnmodifiableListView<String> get undoStack => UnmodifiableListView(_undoStack);

  UnmodifiableListView<String> get redoStack => UnmodifiableListView(_redoStack);

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  void commit({required CanvasReader reader}) {
    if (_isRestoring) return;
    final snapshot = reader.model.serializeFlexi();
    if (_undoStack.isNotEmpty && _undoStack.last == snapshot) return;
    _undoStack.add(snapshot);
    _redoStack.clear();
    if (_undoStack.length > maxDepth) {
      _undoStack.removeRange(0, _undoStack.length - maxDepth);
    }
    notifyListeners();
  }

  bool undo({
    required CanvasReader reader,
    required CanvasWriter writer,
    DecodeCustomData? decodeCustomComponentData,
    DecodeCustomData? decodeCustomLinkData,
  }) {
    if (!canUndo) return false;
    _isRestoring = true;
    try {
      final current = _undoStack.removeLast();
      _redoStack.add(current);
      final target = _undoStack.last;
      _restore(
        target,
        writer: writer,
        decodeCustomComponentData: decodeCustomComponentData,
        decodeCustomLinkData: decodeCustomLinkData,
      );
      return true;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  bool redo({
    required CanvasReader reader,
    required CanvasWriter writer,
    DecodeCustomData? decodeCustomComponentData,
    DecodeCustomData? decodeCustomLinkData,
  }) {
    if (!canRedo) return false;
    _isRestoring = true;
    try {
      final target = _redoStack.removeLast();
      _undoStack.add(target);
      _restore(
        target,
        writer: writer,
        decodeCustomComponentData: decodeCustomComponentData,
        decodeCustomLinkData: decodeCustomLinkData,
      );
      return true;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  void _restore(
    String snapshot, {
    required CanvasWriter writer,
    DecodeCustomData? decodeCustomComponentData,
    DecodeCustomData? decodeCustomLinkData,
  }) {
    writer.model.removeAllComponents();
    writer.model.deserializeFlexi(
      snapshot,
      decodeCustomComponentData: decodeCustomComponentData,
      decodeCustomLinkData: decodeCustomLinkData,
    );
  }
}
