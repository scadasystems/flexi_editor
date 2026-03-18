import 'dart:collection';

import 'package:flexi_editor/src/abstraction_layer/state/canvas_reader.dart';
import 'package:flexi_editor/src/abstraction_layer/state/canvas_writer.dart';
import 'package:flutter/foundation.dart';

/// 커스텀 데이터(`Component.data`, `LinkData.data`)를 복원할 때 사용되는 디코더입니다.
///
/// - [json]은 직렬화된 데이터(Map)입니다.
/// - 반환 타입은 호출 측에서 캐스팅하여 사용합니다.
typedef DecodeCustomData = Function(Map<String, dynamic> json);

/// FlexiEditor 모델 스냅샷 기반 Undo/Redo 컨트롤러입니다.
///
/// - [commit]으로 스냅샷을 쌓고, [undo]/[redo]로 복원합니다.
/// - 복원 시에는 기존 모델을 모두 제거한 뒤 스냅샷을 역직렬화합니다.
class CanvasUndoRedoController extends ChangeNotifier {
  /// undo 스택에 유지할 최대 스냅샷 개수입니다.
  final int maxDepth;

  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  bool _isRestoring = false;

  /// [maxDepth]만큼 스냅샷을 유지하는 Undo/Redo 컨트롤러를 생성합니다.
  CanvasUndoRedoController({this.maxDepth = 50});

  /// 현재 undo가 가능한지 여부입니다.
  bool get canUndo => _undoStack.length > 1 && !_isRestoring;

  /// 현재 redo가 가능한지 여부입니다.
  bool get canRedo => _redoStack.isNotEmpty && !_isRestoring;

  UnmodifiableListView<String> get undoStack => UnmodifiableListView(_undoStack);

  UnmodifiableListView<String> get redoStack => UnmodifiableListView(_redoStack);

  /// undo/redo 스택을 모두 비웁니다.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  /// 현재 모델 상태를 스냅샷으로 저장합니다.
  ///
  /// - [reader]: 현재 모델을 직렬화하기 위한 reader
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

  /// 이전 스냅샷으로 되돌립니다.
  ///
  /// - [reader]: undo 가능 여부 판단/스냅샷 생성에 필요
  /// - [writer]: 스냅샷 복원을 위해 모델을 수정하는 데 사용
  /// - [decodeCustomComponentData]: 커스텀 컴포넌트 데이터 디코더(선택)
  /// - [decodeCustomLinkData]: 커스텀 링크 데이터 디코더(선택)
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

  /// 되돌린 스냅샷을 다시 적용합니다.
  ///
  /// - [reader]: redo 가능 여부 판단/스냅샷 생성에 필요
  /// - [writer]: 스냅샷 복원을 위해 모델을 수정하는 데 사용
  /// - [decodeCustomComponentData]: 커스텀 컴포넌트 데이터 디코더(선택)
  /// - [decodeCustomLinkData]: 커스텀 링크 데이터 디코더(선택)
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
