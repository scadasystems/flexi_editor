// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flexi_editor/src/canvas_context/model/connection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ComponentData<T> with ChangeNotifier {
  final String id;
  final String type;
  String? subtype;
  Offset position;
  Size size;
  int zOrder = 0;
  bool locked = false;
  String? parentId;
  final List<String> childrenIds;
  final List<Connection> connections;
  final T? data;

  ComponentData({
    String? id,
    required this.type,
    this.subtype,
    this.position = Offset.zero,
    this.size = const Size(100, 100),
    this.parentId,
    this.zOrder = 0,
    List<String>? childrenIds,
    List<Connection>? connections,
    this.data,
  })  : id = id ?? const Uuid().v4(),
        childrenIds = childrenIds ?? [],
        connections = connections ?? [];

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
        childrenIds = json['children_ids'] != null //
            ? (json['children_ids'] as List).map((id) => id.toString()).toList()
            : [],
        connections = json['connections'] != null
            ? (json['connections'] as List).map((connectionJson) => Connection.fromJson(connectionJson)).toList()
            : [],
        data = decodeCustomComponentData?.call(json['dynamic_data'] ?? {});

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
      zOrder: zOrder ?? this.zOrder,
      parentId: parentId ?? this.parentId,
      data: data ?? this.data,
    );

    return component;
  }
}
