import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CanvasEvent with ChangeNotifier {
  final _keyboardFocusNode = FocusNode();
  bool _isSpacePressed = false;
  SystemMouseCursor _mouseCursor = SystemMouseCursors.grab;
  Offset? _startDragPosition;
  Offset? _currentDragPosition;

  FocusNode get keyboardFocusNode => _keyboardFocusNode;
  bool get isSpacePressed => _isSpacePressed;
  SystemMouseCursor get mouseCursor => _mouseCursor;
  Offset? get startDragPosition => _startDragPosition;
  Offset? get currentDragPosition => _currentDragPosition;

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void requestFocus() {
    _keyboardFocusNode.requestFocus();
  }

  void unfocus() {
    _keyboardFocusNode.unfocus();
  }

  /// 스페이스바 눌림 상태 변경
  void setSpacePressed(bool value) {
    _isSpacePressed = value;
    notifyListeners();
  }

  /// 마우스 커서 변경
  void setMouseGrabCursor(bool grabbing) {
    _mouseCursor = grabbing //
        ? SystemMouseCursors.grabbing
        : SystemMouseCursors.grab;
    notifyListeners();
  }

  /// 드래그 시작
  void startSelectDragPosition(ScaleStartDetails details) {
    _startDragPosition = details.localFocalPoint;
    notifyListeners();
  }

  /// 드래그 업데이트
  void updateSelectDragPosition(ScaleUpdateDetails details) {
    _currentDragPosition = details.localFocalPoint;
    notifyListeners();
  }

  /// 드래그 종료
  void endSelectDragPosition() {
    _startDragPosition = null;
    _currentDragPosition = null;
    notifyListeners();
  }

  void selectComponentsInDragArea(CanvasModel canvasModel) {
    if (startDragPosition == null || currentDragPosition == null) return;

    final selectionRect = Rect.fromPoints(
      startDragPosition!,
      currentDragPosition!,
    );

    for (var component in canvasModel.components.values) {
      final componentRect =
          Rect.fromLTWH(component.position.dx, component.position.dy, component.size.width, component.size.height);

      if (selectionRect.overlaps(componentRect)) {
        // component.component.isSelected = true;
      } else {
        // component.isSelected = false;
      }
    }

    notifyListeners();
  }

  /// 키보드 이벤트
  KeyEventResult onKeyboardEvent(FocusNode node, KeyEvent event) {
    final isControlPressed = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) {
        setSpacePressed(true);
      } else if (event is KeyUpEvent) {
        setSpacePressed(false);
      }

      return KeyEventResult.handled;
    }

    if (isControlPressed && HardwareKeyboard.instance.isLogicalKeyPressed(event.logicalKey)) {
      if (event is KeyDownEvent) {
        print('Control + ${event.logicalKey.keyLabel}');
      }
    }

    return KeyEventResult.ignored;
  }
}
