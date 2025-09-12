import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CanvasEvent with ChangeNotifier {
  final _keyboardFocusNode = FocusNode();
  FocusNode get keyboardFocusNode => _keyboardFocusNode;

  bool _disableKeyboardEvents = false;
  bool get disableKeyboardEvents => _disableKeyboardEvents;

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

  bool _isTapComponent = false;
  bool get isTapComponent => _isTapComponent;

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void requestFocus() {
    _keyboardFocusNode.requestFocus();
  }

  void unfocus() {
    _keyboardFocusNode.unfocus(
        disposition: UnfocusDisposition.previouslyFocusedChild);
  }

  void enableKeyboardEvent() {
    _disableKeyboardEvents = false;
    requestFocus();
  }

  void disableKeyboardEvent() {
    _disableKeyboardEvents = true;
    unfocus();
  }

  /// 스페이스바 눌림 상태 변경
  void setSpacePressed(bool value) {
    _isSpacePressed = value;

    if (!value) {
      setMouseGrabCursor(false);
    }

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

  void startTapComponent() => _isTapComponent = true;

  void stopTapComponent() => _isTapComponent = false;
}
