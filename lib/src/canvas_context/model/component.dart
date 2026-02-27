// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flexi_editor/src/canvas_context/model/port_type.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Component<T> with ChangeNotifier {
  final String id;
  final String type;
  String? subtype;
  Offset position;
  Size size;
  int zOrder = 0;
  bool locked = false;
  String? parentId;
  final List<String> childrenIds;
  T? data;

  // 포트 관련 필드
  bool showPort = true;
  Map<PortType, bool>? showPorts;

  // 그룹 관련 필드
  String? groupId;
  String? groupName;
  bool groupCollapsed = false;

  // 그룹 관련 메서드

  Component({
    String? id,
    required this.type,
    this.subtype,
    this.position = Offset.zero,
    this.size = const Size(100, 100),
    this.parentId,
    this.zOrder = 0,
    List<String>? childrenIds,
    this.data,
    this.locked = false,
    this.showPort = true,
    this.showPorts,
    this.groupId,
    this.groupName,
    this.groupCollapsed = false,
  })  : id = id ?? const Uuid().v4(),
        childrenIds = childrenIds ?? [];

  void refresh() => notifyListeners();

  void move(Offset offset) {
    position += offset;
    notifyListeners();
  }

  void setPosition(Offset position) {
    this.position = position;
    notifyListeners();
  }

  void resizeDelta(Offset deltaSize) {
    size = size + deltaSize;
    notifyListeners();
  }

  void setSize(Size size) {
    this.size = size;
    notifyListeners();
  }

  Offset getPortPosition(PortType portType) {
    switch (portType) {
      case PortType.top:
        return position + getPointOnComponent(Alignment.topCenter);
      case PortType.bottom:
        return position + getPointOnComponent(Alignment.bottomCenter);
      case PortType.left:
        return position + getPointOnComponent(Alignment.centerLeft);
      case PortType.right:
        return position + getPointOnComponent(Alignment.centerRight);
    }
  }

  Offset getPointOnComponent(Alignment alignment) {
    // Alignment 좌표계: (-1.0, -1.0) ~ (1.0, 1.0)
    // 0.0 ~ 1.0 범위로 변환: (alignment.x + 1) / 2
    return Offset(
      size.width * ((alignment.x + 1) / 2),
      size.height * ((alignment.y + 1) / 2),
    );
  }

  void setParent(String? parentId) {
    this.parentId = parentId;
  }

  void removeParent() {
    parentId = null;
  }

  void setLocked(bool locked) {
    this.locked = locked;
    notifyListeners();
  }

  void lock() => setLocked(true);
  void unlock() => setLocked(false);
  void toggleLock() => setLocked(!locked);

  void addChild(String childId) {
    childrenIds.add(childId);
  }

  void removeChild(String childId) {
    childrenIds.remove(childId);
  }

  void setSubtype(String subtype) {
    this.subtype = subtype;
  }

  void updateData(T? newData) {
    data = newData;
    notifyListeners();
  }

  void setShowPort(bool show) {
    showPort = show;
    notifyListeners();
  }

  void setShowPorts(Map<PortType, bool>? ports) {
    showPorts = ports;
    notifyListeners();
  }

  bool isPortVisible(PortType type) {
    if (!showPort) return false;
    return showPorts?[type] ?? true;
  }

  bool get isScreen => type == 'screen';
  bool get hasParent => parentId != null;
  bool get hasChildren => childrenIds.isNotEmpty;

  Component.fromJson(
    Map<String, dynamic> json, {
    Function(Map<String, dynamic> json)? decodeCustomComponentData,
  })  : id = json['id'],
        position = Offset(json['position'][0], json['position'][1]),
        size = Size(json['size'][0], json['size'][1]),
        type = json['type'],
        subtype = json['subtype'],
        zOrder = json['z_order'],
        parentId = json['parent_id'],
        childrenIds = json['children_ids'] != null //
            ? (json['children_ids'] as List).map((id) => id.toString()).toList()
            : [],
        data = decodeCustomComponentData?.call(
          json['dynamic_data'] ?? {},
        ),
        locked = json['locked'] ?? false,
        showPort = json['show_port'] ?? true,
        showPorts = json['show_ports'] != null
            ? (json['show_ports'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(PortType.values.byName(key), value),
              )
            : null,
        groupId = json['group_id'],
        groupName = json['group_name'],
        groupCollapsed = json['group_collapsed'] ?? false;

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': [position.dx.round(), position.dy.round()],
        'size': [size.width.round(), size.height.round()],
        'type': type,
        if (subtype != null) 'subtype': subtype,
        'z_order': zOrder,
        if (parentId != null) 'parent_id': parentId,
        if (childrenIds.isNotEmpty) 'children_ids': childrenIds,
        if (data != null) 'dynamic_data': (data as dynamic)?.toJson(),
        if (locked) 'locked': locked,
        'show_port': showPort,
        if (showPorts != null)
          'show_ports': showPorts!.map(
            (key, value) => MapEntry(key.name, value),
          ),
        if (groupId != null) 'group_id': groupId,
        if (groupName != null) 'group_name': groupName,
        if (groupCollapsed) 'group_collapsed': groupCollapsed,
      };

  Component<T> copyWith({
    String? id,
    Offset? position,
    Size? size,
    String? type,
    String? subtype,
    String? parentId,
    int? zOrder,
    T? data,
    bool replaceData = false,
    bool? showPort,
    Map<PortType, bool>? showPorts,
  }) {
    final component = Component<T>(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      zOrder: zOrder ?? this.zOrder,
      parentId: parentId ?? this.parentId,
      data: replaceData ? data : (data ?? this.data),
      showPort: showPort ?? this.showPort,
      showPorts: showPorts ?? this.showPorts,
    );

    return component;
  }
}
