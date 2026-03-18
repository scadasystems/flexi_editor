import 'dart:convert';
import 'dart:math' as math;

import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../editor/editor_controller.dart';
import '../editor/editor_models.dart';
import '../editor/example_editor_store.dart';
import '../theme/theme_mode_controller.dart';
import '../widgets/editor_debug_json_viewer_sheet.dart';
import 'layer_panel/layer_panel.dart';

part 'editor_page/editor_page_drag_helpers.dart';
part 'editor_page/editor_page_inspector.dart';
part 'editor_page/editor_page_top_bar.dart';

const double _layerPanelWidth = 220;
const double _shapePanelGap = 5;

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> with _EditorPageDragHelpers {
  late final ExampleEditorStore _editor;
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    _editor = ExampleEditorStore();
    _controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _undoRedoController.commit(reader: _editorContext.policySet.canvasReader);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _editor.dispose();
    super.dispose();
  }

  @override
  /// 편집기 입력/선택 상태를 제공하는 컨트롤러입니다.
  EditorController get _controller => _editor.controller;

  @override
  /// FlexiEditor 동작에 필요한 컨텍스트입니다.
  FlexiEditorContext get _editorContext => _editor.editorContext;

  @override
  /// undo/redo를 관리하는 컨트롤러입니다.
  CanvasUndoRedoController get _undoRedoController =>
      _editor.undoRedoController;

  /// 새 Screen 컴포넌트를 추가하고 선택 상태 및 zOrder를 정리한 뒤 커밋합니다.
  void _addScreen() {
    final component = Component<EditorShapeData>(
      type: 'screen',
      position: const Offset(80, 80),
      size: const Size(640, 420),
      data: const EditorShapeData(
        fillColorValue: 0xFFF8FAFC,
        strokeColorValue: 0xFFCBD5E1,
        strokeWidth: 1,
        cornerRadius: 16,
        rotationRadians: 0,
      ),
    );
    final id = _editorContext.canvasModel.addComponent(component);
    _applyTopmostZOrderToNewComponent(componentId: id, parentId: null);
    _controller.selectSingleComponent(id);
    _applyComponentGesturePolicy();
    _undoRedoController.commit(reader: _editorContext.policySet.canvasReader);
  }

  /// 키보드 입력(undo/redo/escape/reset/delete)을 처리합니다.
  void _onKeyboardEvent(FocusNode node, KeyEvent keyEvent) {
    if (keyEvent is! KeyDownEvent) return;

    final key = keyEvent.logicalKey;
    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isCmdOrCtrl = isMeta || isCtrl;

    if (isCmdOrCtrl && key == LogicalKeyboardKey.keyZ) {
      final didUndo = _undoRedoController.undo(
        reader: _editorContext.policySet.canvasReader,
        writer: _editorContext.policySet.canvasWriter,
        decodeCustomComponentData: _decodeEditorShapeData,
      );
      if (didUndo) _controller.clearSelection();
      return;
    }

    if (isCmdOrCtrl && key == LogicalKeyboardKey.keyY) {
      final didRedo = _undoRedoController.redo(
        reader: _editorContext.policySet.canvasReader,
        writer: _editorContext.policySet.canvasWriter,
        decodeCustomComponentData: _decodeEditorShapeData,
      );
      if (didRedo) _controller.clearSelection();
      return;
    }

    if (key == LogicalKeyboardKey.escape) {
      _controller
        ..clearPendingConnector()
        ..setTool(EditorTool.select);
      return;
    }

    if (isCmdOrCtrl && key == LogicalKeyboardKey.digit0) {
      _editorContext.canvasState.resetCanvasView();
      return;
    }

    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      var changed = false;
      final selectedLinkId = _controller.selectedLinkId;
      if (selectedLinkId != null &&
          _editorContext.canvasModel.linkExists(selectedLinkId)) {
        _editorContext.canvasModel.removeLink(selectedLinkId);
        changed = true;
      }

      final selectedComponentIds = _controller.selectedComponentIds.toList(
        growable: false,
      );
      for (final id in selectedComponentIds) {
        if (_editorContext.canvasModel.componentExists(id)) {
          _editorContext.policySet.canvasWriter.model
              .removeComponentWithChildren(id);
          changed = true;
        }
      }

      _controller.clearSelection();
      if (changed) {
        _undoRedoController.commit(
          reader: _editorContext.policySet.canvasReader,
        );
      }
    }
  }

  /// 커스텀 컴포넌트 데이터(EditorShapeData)를 JSON에서 복원합니다.
  dynamic _decodeEditorShapeData(Map<String, dynamic> json) {
    return EditorShapeData(
      fillColorValue: json['fill'] as int? ?? 0xFFFFFFFF,
      strokeColorValue: json['stroke'] as int? ?? 0xFF111827,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 1,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 12,
      rotationRadians: (json['rotationRadians'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  /// 에디터 화면을 구성하고, 테마 변경에 따라 캔버스 스타일을 갱신합니다.
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    if (_lastBrightness != brightness) {
      _lastBrightness = brightness;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _editor.applyTheme(brightness: brightness, scheme: scheme);
      });
    }

    return ChangeNotifierProvider.value(
      value: _editor,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Row(
            children: [
              const SizedBox(
                width: _layerPanelWidth,
                child: LayerPanel(),
              ),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      onAddScreen: _addScreen,
                      onUndo: () {
                        final didUndo = _undoRedoController.undo(
                          reader: _editorContext.policySet.canvasReader,
                          writer: _editorContext.policySet.canvasWriter,
                          decodeCustomComponentData: _decodeEditorShapeData,
                        );
                        if (didUndo) _controller.clearSelection();
                      },
                      onRedo: () {
                        final didRedo = _undoRedoController.redo(
                          reader: _editorContext.policySet.canvasReader,
                          writer: _editorContext.policySet.canvasWriter,
                          decodeCustomComponentData: _decodeEditorShapeData,
                        );
                        if (didRedo) _controller.clearSelection();
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const .all(12),
                        child: ClipRRect(
                          borderRadius: .circular(12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: scheme.surface),
                            child: Stack(
                              children: [
                                FlexiEditor(
                                  flexiEditorContext: _editorContext,
                                  onSelectionRectStart: _onSelectionRectStart,
                                  onSelectionRectUpdate: _onSelectionRectUpdate,
                                  onSelectionRectEnd: _onSelectionRectEnd,
                                  onKeyboardEvent: _onKeyboardEvent,
                                ),
                                const Positioned(
                                  left: _shapePanelGap,
                                  top: 12,
                                  child: _FloatingShapePanel(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _Inspector(),
            ],
          ),
        ),
      ),
    );
  }
}
