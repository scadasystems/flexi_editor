import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CanvasEvent with ChangeNotifier {
  final _keyboardFocusNode = FocusNode();
  FocusNode get keyboardFocusNode => _keyboardFocusNode;

  bool _isSpacePressed = false;
  bool get isSpacePressed => _isSpacePressed;

  SystemMouseCursor _mouseCursor = SystemMouseCursors.grab;
  SystemMouseCursor get mouseCursor => _mouseCursor;

  Offset? _startDragPosition;
  Offset? get startDragPosition => _startDragPosition;

  Offset? _currentDragPosition;
  Offset? get currentDragPosition => _currentDragPosition;

  bool _isStartDragSelection = true;
  bool get isStartDragSelection => _isStartDragSelection;

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

  /// 선택 드래그 시작
  void startDragSelection() {
    _isStartDragSelection = true;
    notifyListeners();
  }

  /// 선택 드래그 종료
  void stopDragSelection() {
    _isStartDragSelection = false;
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

  /// 키보드 이벤트
  KeyEventResult onKeyboardEvent(FocusNode node, KeyEvent event) {
    //#region 스페이스바 이벤트
    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) {
        setSpacePressed(true);
      } else if (event is KeyUpEvent) {
        setSpacePressed(false);
      }

      return KeyEventResult.handled;
    }
    //#endregion

    return KeyEventResult.ignored;
  }
}
