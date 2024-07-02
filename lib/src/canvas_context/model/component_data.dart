// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flexi_editor/src/canvas_context/model/connection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ComponentData<T> with ChangeNotifier {
  final String id;
  Offset position;
  Size size;
  final Size minSize;
  final String? type;
  int zOrder = 0;
  String? parentId;
  final List<String> childrenIds = [];
  final List<Connection> connections = [];
  final T? data;

  ComponentData({
    String? id,
    this.position = Offset.zero,
    this.size = const Size(80, 80),
    this.minSize = const Size(4, 4),
    this.type,
    this.data,
  })  : assert(minSize <= size),
        id = id ?? const Uuid().v4();

  void refresh() {
    notifyListeners();
  }

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
    var tempSize = size + deltaSize;
    if (tempSize.width < minSize.width) {
      tempSize = Size(minSize.width, tempSize.height);
    }
    if (tempSize.height < minSize.height) {
      tempSize = Size(tempSize.width, minSize.height);
    }
    size = tempSize;
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

  void setParent(String parentId) {
    this.parentId = parentId;
  }

  void removeParent() {
    parentId = null;
  }

  void addChild(String childId) {
    childrenIds.add(childId);
  }

  void removeChild(String childId) {
    childrenIds.remove(childId);
  }

  ComponentData.fromJson(
    Map<String, dynamic> json, {
    Function(Map<String, dynamic> json)? decodeCustomComponentData,
  })  : id = json['id'],
        position = Offset(json['position'][0], json['position'][1]),
        size = Size(json['size'][0], json['size'][1]),
        minSize = Size(json['min_size'][0], json['min_size'][1]),
        type = json['type'],
        zOrder = json['z_order'],
        parentId = json['parent_id'],
        data = decodeCustomComponentData?.call(json['dynamic_data']) {
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
        'position': [position.dx, position.dy],
        'size': [size.width, size.height],
        'min_size': [minSize.width, minSize.height],
        'type': type,
        'z_order': zOrder,
        'parent_id': parentId,
        'children_ids': childrenIds,
        'connections': connections,
        'dynamic_data': (data as dynamic)?.toJson(),
      };

  @override
  String toString() {
    return 'ComponentData(id: $id, position: $position, size: $size, minSize: $minSize, type: $type, zOrder: $zOrder, parentId: $parentId, childrenIds: $childrenIds)';
  }
}
