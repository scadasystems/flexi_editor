import 'package:flexi_editor/src/canvas_context/model/port_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PortInfo {
  final String componentId;
  final PortType portType;

  PortInfo(this.componentId, this.portType);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PortInfo &&
        other.componentId == componentId &&
        other.portType == portType;
  }

  @override
  int get hashCode => componentId.hashCode ^ portType.hashCode;
}

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

  // 연결 드래그 관련 상태
  bool _isDragConnection = false;
  bool get isDragConnection => _isDragConnection;

  String? _draggingSourceComponentId;
  String? get draggingSourceComponentId => _draggingSourceComponentId;

  PortType? _draggingSourcePort;
  PortType? get draggingSourcePort => _draggingSourcePort;

  PortInfo? _hoveringPort;
  PortInfo? get hoveringPort => _hoveringPort;

  PortInfo? _snappedPort;
  PortInfo? get snappedPort => _snappedPort;

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

  // 연결 드래그 관련 메서드

  void startDragConnection(String componentId, PortType portType, Offset startPos) {
    _isDragConnection = true;
    _draggingSourceComponentId = componentId;
    _draggingSourcePort = portType;
    _startDragPosition = startPos;
    _currentDragPosition = startPos;
    // 드래그 시작 시 selection 비활성화
    _isStartDragSelection = false;
    notifyListeners();
  }

  void updateDragConnection(Offset currentPos) {
    _currentDragPosition = currentPos;
    notifyListeners();
  }

  void stopDragConnection() {
    _isDragConnection = false;
    _draggingSourceComponentId = null;
    _draggingSourcePort = null;
    _startDragPosition = null;
    _currentDragPosition = null;
    _snappedPort = null;
    // 드래그 종료 시 selection 다시 활성화
    _isStartDragSelection = true;
    notifyListeners();
  }

  void setHoveringPort(String? componentId, PortType? portType) {
    if (componentId == null || portType == null) {
      _hoveringPort = null;
    } else {
      _hoveringPort = PortInfo(componentId, portType);
    }
    notifyListeners();
  }

  void setSnappedPort(String? componentId, PortType? portType) {
    if (componentId == null || portType == null) {
      _snappedPort = null;
    } else {
      _snappedPort = PortInfo(componentId, portType);
    }
    notifyListeners();
  }
}
