import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CanvasScaleEvent with ChangeNotifier {
  final _keyboardFocusNode = FocusNode();
  bool _isSpacePressed = false;
  SystemMouseCursor _mouseCursor = SystemMouseCursors.grab;
  Offset? _selectDragStartPosition;
  Offset? _selectCurrentDragPosition;

  FocusNode get keyboardFocusNode => _keyboardFocusNode;
  bool get isSpacePressed => _isSpacePressed;
  SystemMouseCursor get mouseCursor => _mouseCursor;
  Offset? get selectDragStartPosition => _selectDragStartPosition;
  Offset? get selectCurrentDragPosition => _selectCurrentDragPosition;

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

  void setSpacePressed(bool value) {
    _isSpacePressed = value;
    notifyListeners();
  }

  void setMouseGrabCursor(bool grabbing) {
    _mouseCursor = grabbing //
        ? SystemMouseCursors.grabbing
        : SystemMouseCursors.grab;
    notifyListeners();
  }

  void setSelectDragPositions(Offset? start, Offset? current) {
    _selectDragStartPosition = start;
    _selectCurrentDragPosition = current;
    notifyListeners();
  }
}
