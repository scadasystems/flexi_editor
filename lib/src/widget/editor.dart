// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/widget/canvas.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlexiEditor extends StatefulWidget {
  final FlexiEditorContext flexiEditorContext;
  final VoidCallback? onSelectionRectStart;
  final SelectionRectChangedCallback? onSelectionRectUpdate;
  final VoidCallback? onSelectionRectEnd;
  final KeyboardEventCallback? onKeyboardEvent;

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
