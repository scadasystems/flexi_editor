import 'package:flutter/foundation.dart';

enum EditorTool {
  select,
  rectangle,
  oval,
  connector,
}

class EditorController extends ChangeNotifier {
  EditorTool _tool = EditorTool.select;
  EditorTool get tool => _tool;

  final Set<String> _selectedComponentIds = {};
  Set<String> get selectedComponentIds => _selectedComponentIds;

  String? _selectedLinkId;
  String? get selectedLinkId => _selectedLinkId;

  String? _pendingConnectorSourceComponentId;
  String? get pendingConnectorSourceComponentId =>
      _pendingConnectorSourceComponentId;

  bool isComponentSelected(String componentId) =>
      _selectedComponentIds.contains(componentId);

  void setTool(EditorTool tool) {
    if (_tool == tool) return;
    _tool = tool;
    _pendingConnectorSourceComponentId = null;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedComponentIds.isEmpty && _selectedLinkId == null) return;
    _selectedComponentIds.clear();
    _selectedLinkId = null;
    notifyListeners();
  }

  void selectSingleComponent(String componentId) {
    final changed = _selectedComponentIds.length != 1 ||
        !_selectedComponentIds.contains(componentId) ||
        _selectedLinkId != null;

    _selectedComponentIds
      ..clear()
      ..add(componentId);
    _selectedLinkId = null;

    if (changed) {
      notifyListeners();
    }
  }

  void setSelectedComponents(Iterable<String> componentIds) {
    final next = componentIds.toSet();
    if (setEquals(next, _selectedComponentIds) && _selectedLinkId == null) {
      return;
    }
    _selectedComponentIds
      ..clear()
      ..addAll(next);
    _selectedLinkId = null;
    notifyListeners();
  }

  void selectLink(String linkId) {
    if (_selectedLinkId == linkId && _selectedComponentIds.isEmpty) return;
    _selectedComponentIds.clear();
    _selectedLinkId = linkId;
    notifyListeners();
  }

  void clearPendingConnector() {
    if (_pendingConnectorSourceComponentId == null) return;
    _pendingConnectorSourceComponentId = null;
    notifyListeners();
  }

  void setPendingConnectorSource(String componentId) {
    if (_pendingConnectorSourceComponentId == componentId) return;
    _pendingConnectorSourceComponentId = componentId;
    notifyListeners();
  }
}

