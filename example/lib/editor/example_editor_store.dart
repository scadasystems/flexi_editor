import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';

import 'editor_controller.dart';
import 'example_policy_set.dart';

/// 예제에서 사용하는 편집기 의존성을 하나로 묶어 제공하는 Store입니다.
///
/// - [controller], [undoRedoController], [editorContext]를 단일 Provider로 제공해
///   위젯들이 여러 Provider를 각각 알 필요 없게 만듭니다.
class ExampleEditorStore extends ChangeNotifier {
  /// 예제 편집기 입력/선택 상태를 관리합니다.
  late final EditorController controller;

  /// 예제 편집기의 undo/redo 스택을 관리합니다.
  late final CanvasUndoRedoController undoRedoController;

  /// 예제 편집기의 정책(동작 규칙/위젯 확장 포인트) 집합입니다.
  late final ExamplePolicySet policySet;

  /// FlexiEditor가 동작하는 데 필요한 모델/상태/이벤트/정책 컨텍스트입니다.
  late final FlexiEditorContext editorContext;

  /// 기본 편집기 구성요소를 생성하고 상호 연결합니다.
  ExampleEditorStore() {
    controller = EditorController();
    undoRedoController = CanvasUndoRedoController();
    policySet = ExamplePolicySet(
      controller: controller,
      undoRedoController: undoRedoController,
    );
    editorContext = FlexiEditorContext(policySet);
  }

  /// 현재 테마/밝기에 맞춰 예제의 캔버스 배경 및 점선 그리드를 설정합니다.
  void applyTheme({required Brightness brightness, required ColorScheme scheme}) {
    final isDark = brightness == Brightness.dark;
    policySet.setUiTheme(brightness: brightness, scheme: scheme);
    final dottedColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.35)
        : const Color(0xFF000000);
    editorContext.policySet.canvasWriter.state.setCanvasColor(
      isDark ? const Color(0xFF0B1220) : const Color(0xFFF7F7F8),
    );
    editorContext.policySet.canvasWriter.state.setDottedBackground(
      CanvasDottedBackgroundConfig(
        enabled: true,
        snapThresholdCanvas: 4,
        minVisibleScale: 0.2,
        dotRadiusCanvas: 1,
        color: dottedColor,
      ),
    );
  }

  /// 현재 상태를 undo/redo 스택에 커밋합니다.
  void commit() {
    undoRedoController.commit(reader: editorContext.policySet.canvasReader);
  }

  @override
  /// 생성한 리소스를 정리합니다.
  void dispose() {
    controller.dispose();
    undoRedoController.dispose();
    super.dispose();
  }
}
