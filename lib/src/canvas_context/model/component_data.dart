// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flexi_editor/src/canvas_context/model/connection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ComponentData<T> with ChangeNotifier {
  final String id;
  Offset position;
  Size size;
  final String type;
  String? subtype;
  int zOrder = 0;
  bool locked = false;
  String? parentId;
  final List<String> childrenIds = [];
  final List<Connection> connections = [];
  final T? data;

  ComponentData({
    String? id,
    this.position = Offset.zero,
    this.size = const Size(100, 100),
    required this.type,
    this.subtype,
    this.data,
  }) : id = id ?? const Uuid().v4();

  void refresh() => notifyListeners();

  void move(Offset offset) {
    position += offset;
    notifyListeners();
  }

  void setPosition(Offset position) {
    this.position = position;
    notifyListeners();
  }

  void addConnection(Connection connection) {
    connections.add(connection);
  }

  void removeConnection(String connectionId) {
    connections.removeWhere((conn) => conn.connectionId == connectionId);
  }

  void resizeDelta(Offset deltaSize) {
    size = size + deltaSize;
    notifyListeners();
  }

  void setSize(Size size) {
    this.size = size;
    notifyListeners();
  }

  Offset getPointOnComponent(Alignment alignment) {
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

  void setZOrder(int zOrder) {
    this.zOrder = zOrder;
    notifyListeners();
  }

  void setLocked(bool locked) {
    this.locked = locked;
    notifyListeners();
  }

  void addChild(String childId) {
    childrenIds.add(childId);
  }

  void removeChild(String childId) {
    childrenIds.remove(childId);
  }

  void setSubtype(String subtype) {
    this.subtype = subtype;
  }

  ComponentData.fromJson(
    Map<String, dynamic> json, {
    Function(Map<String, dynamic> json)? decodeCustomComponentData,
  })  : id = json['id'],
        position = Offset(json['position'][0], json['position'][1]),
        size = Size(json['size'][0], json['size'][1]),
        type = json['type'],
        subtype = json['subtype'],
        zOrder = json['z_order'],
        parentId = json['parent_id'],
        data = decodeCustomComponentData?.call(json['dynamic_data'] ?? {}) {
    childrenIds.addAll(
      (json['children_ids'] as List).map((id) => id as String).toList(),
    );
    connections.addAll(
      (json['connections'] as List).map((connectionJson) {
        return Connection.fromJson(connectionJson);
      }),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': [position.dx.round(), position.dy.round()],
        'size': [size.width.round(), size.height.round()],
        'type': type,
        if (subtype != null) 'subtype': subtype,
        'z_order': zOrder,
        if (parentId != null) 'parent_id': parentId,
        if (childrenIds.isNotEmpty) 'children_ids': childrenIds,
        if (connections.isNotEmpty) 'connections': connections,
        if (data != null) 'dynamic_data': (data as dynamic)?.toJson(),
      };

  ComponentData<T> copyWith({
    String? id,
    Offset? position,
    Size? size,
    String? type,
    String? subtype,
    String? parentId,
    int? zOrder,
    T? data,
  }) {
    final component = ComponentData<T>(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      data: data ?? this.data,
    );

    component.setZOrder(zOrder ?? this.zOrder);
    component.setParent(parentId ?? this.parentId);

    return component;
  }
}
