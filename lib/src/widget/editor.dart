// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/widget/canvas.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// FlexiEditor의 루트 위젯입니다.
///
/// [flexiEditorContext]가 제공하는 모델/상태/이벤트를 Provider로 주입한 뒤,
/// 내부 캔버스 위젯([FlexiEditorCanvas])을 구성합니다.
class FlexiEditor extends StatefulWidget {
  /// 에디터가 사용할 컨텍스트입니다.
  ///
  /// - 모델/상태를 공유하거나 새로 만들지 여부는 [FlexiEditorContext] 생성 방식에 따라 달라집니다.
  final FlexiEditorContext flexiEditorContext;

  /// 캔버스에서 “선택 사각형(드래그 선택)”이 시작될 때 호출됩니다.
  final VoidCallback? onSelectionRectStart;

  /// 선택 사각형(드래그 선택) 영역이 변경될 때 호출됩니다.
  ///
  /// 콜백 파라미터의 좌표계는 위젯 로컬 좌표(화면) 기준입니다.
  final SelectionRectChangedCallback? onSelectionRectUpdate;

  /// 선택 사각형(드래그 선택)이 종료될 때 호출됩니다.
  final VoidCallback? onSelectionRectEnd;

  /// 키보드 이벤트를 외부에서 처리할 수 있도록 전달합니다.
  ///
  /// - 캔버스가 포커스를 가진 상태에서 키 입력이 발생하면 호출됩니다.
  final KeyboardEventCallback? onKeyboardEvent;

  /// [flexiEditorContext]로 에디터를 구성합니다.
  const FlexiEditor({
    super.key,
    required this.flexiEditorContext,
    this.onSelectionRectStart,
    this.onSelectionRectUpdate,
    this.onSelectionRectEnd,
    this.onKeyboardEvent,
  });

  @override
  FlexiEditorState createState() => FlexiEditorState();
}

class FlexiEditorState extends State<FlexiEditor> {
  @override
  void initState() {
    if (!widget.flexiEditorContext.canvasState.isInitialized) {
      widget.flexiEditorContext.policySet.initializeEditor();
      widget.flexiEditorContext.canvasState.isInitialized = true;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CanvasModel>.value(
          value: widget.flexiEditorContext.canvasModel,
        ),
        ChangeNotifierProvider<CanvasState>.value(
          value: widget.flexiEditorContext.canvasState,
        ),
        ChangeNotifierProvider<CanvasEvent>.value(
          value: widget.flexiEditorContext.canvasEvent,
        ),
      ],
      builder: (context, child) {
        return FlexiEditorCanvas(
          policy: widget.flexiEditorContext.policySet,
          onSelectionRectStart: widget.onSelectionRectStart,
          onSelectionRectUpdate: widget.onSelectionRectUpdate,
          onSelectionRectEnd: widget.onSelectionRectEnd,
          onKeyboardEvent: widget.onKeyboardEvent,
        );
      },
    );
  }
}
