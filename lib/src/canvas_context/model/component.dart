// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flexi_editor/src/canvas_context/model/connection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// 캔버스 상의 컴포넌트(노드) 모델입니다.
///
/// 생성자 파라미터/필드 의미:
/// - [id]: 컴포넌트 고유 ID. 미지정 시 자동 생성됩니다.
/// - [type]: 컴포넌트 타입(예: `screen`).
/// - [name]: 레이어 패널 등에서 표시되는 이름(선택).
/// - [subtype]: 타입의 세부 분류(선택).
/// - [position]: 부모 좌표계 기준 위치.
/// - [scrollOffset]: 스크롤 컨테이너로 동작할 때의 스크롤 오프셋.
/// - [size]: 컴포넌트 크기.
/// - [zOrder]: 렌더링 순서(값이 클수록 위에 렌더링).
/// - [locked]: 잠금 여부(편집/이동 등 상호작용 제한에 사용).
/// - [visible]: 표시 여부. `false`면 렌더링/히트테스트에서 제외됩니다.
/// - [parentId]: 부모 컴포넌트 ID(루트면 null).
/// - [childrenIds]: 자식 컴포넌트 ID 목록.
/// - [connections]: 링크 연결을 위한 커넥션 목록.
/// - [data]: 사용자 정의 데이터(선택).
/// - [groupId]/[groupName]/[groupCollapsed]: 그룹 관련 상태(선택).
class Component<T> with ChangeNotifier {
  final String id;
  final String type;
  String? name;
  String? subtype;
  Offset position;
  Offset scrollOffset;
  Size size;
  int zOrder = 0;
  bool locked = false;
  bool visible = true;
  String? parentId;
  final List<String> childrenIds;
  final List<Connection> connections;
  T? data;

  // 그룹 관련 필드
  String? groupId;
  String? groupName;
  bool groupCollapsed = false;

  // 그룹 관련 메서드

  /// [Component]를 생성합니다.
  ///
  /// - [id]를 지정하지 않으면 자동으로 생성됩니다.
  /// - [visible]의 기본값은 `true`이며, 숨김(`false`)이면 렌더링/히트테스트에서 제외됩니다.
  Component({
    /// 컴포넌트 고유 ID입니다. 미지정 시 자동 생성됩니다.
    String? id,
    /// 컴포넌트 타입(예: `screen`)입니다.
    required this.type,
    /// 레이어 패널 등에 표시되는 이름(선택)입니다.
    this.name,
    /// 타입의 세부 분류(선택)입니다.
    this.subtype,
    /// 부모 좌표계 기준 위치입니다.
    this.position = Offset.zero,
    /// 스크롤 컨테이너로 동작할 때의 스크롤 오프셋입니다.
    this.scrollOffset = Offset.zero,
    /// 컴포넌트 크기입니다.
    this.size = const Size(100, 100),
    /// 부모 컴포넌트 ID입니다(루트면 null).
    this.parentId,
    /// 렌더링 순서입니다(값이 클수록 위에 렌더링).
    this.zOrder = 0,
    /// 자식 컴포넌트 ID 목록입니다.
    List<String>? childrenIds,
    /// 링크 연결을 위한 커넥션 목록입니다.
    List<Connection>? connections,
    /// 사용자 정의 데이터(선택)입니다.
    this.data,
    /// 잠금 여부입니다.
    this.locked = false,
    /// 표시 여부입니다. `false`면 렌더링/히트테스트에서 제외됩니다.
    this.visible = true,
    /// 그룹 ID(선택)입니다.
    this.groupId,
    /// 그룹 이름(선택)입니다.
    this.groupName,
    /// 그룹 접힘 여부입니다.
    this.groupCollapsed = false,
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

  void setScrollOffset(Offset offset) {
    scrollOffset = offset;
    notifyListeners();
  }

  void updateScrollOffset(Offset delta) {
    scrollOffset += delta;
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
    notifyListeners();
  }

  void removeParent() {
    parentId = null;
    notifyListeners();
  }

  void setLocked(bool locked) {
    this.locked = locked;
    notifyListeners();
  }

  void lock() => setLocked(true);
  void unlock() => setLocked(false);
  void toggleLock() => setLocked(!locked);

  void setVisible(bool visible) {
    this.visible = visible;
    notifyListeners();
  }

  void show() => setVisible(true);
  void hide() => setVisible(false);
  void toggleVisible() => setVisible(!visible);

  void addChild(String childId) {
    childrenIds.add(childId);
    notifyListeners();
  }

  void removeChild(String childId) {
    childrenIds.remove(childId);
    notifyListeners();
  }

  void setSubtype(String subtype) {
    this.subtype = subtype;
  }

  void setName(String? name) {
    this.name = name;
    notifyListeners();
  }

  void updateData(T? newData) {
    data = newData;
    notifyListeners();
  }

  bool get isScreen => type == 'screen';
  bool get hasParent => parentId != null;
  bool get hasChildren => childrenIds.isNotEmpty;

  /// JSON으로부터 [Component]를 복원합니다.
  ///
  /// - [decodeCustomComponentData]: `dynamic_data`를 사용자 정의 타입으로 복원할 때 사용합니다.
  Component.fromJson(
    Map<String, dynamic> json, {
    Function(Map<String, dynamic> json)? decodeCustomComponentData,
  })  : id = json['id'],
        position = Offset(json['position'][0], json['position'][1]),
        scrollOffset = json['scroll_offset'] != null
            ? Offset(json['scroll_offset'][0], json['scroll_offset'][1])
            : Offset.zero,
        size = Size(json['size'][0], json['size'][1]),
        type = json['type'],
        name = json['name'],
        subtype = json['subtype'],
        zOrder = json['z_order'],
        parentId = json['parent_id'],
        childrenIds = json['children_ids'] != null //
            ? (json['children_ids'] as List).map((id) => id.toString()).toList()
            : [],
        connections = json['connections'] != null
            ? (json['connections'] as List)
                .map((connectionJson) => Connection.fromJson(connectionJson))
                .toList()
            : [],
        data = decodeCustomComponentData?.call(
          json['dynamic_data'] ?? {},
        ),
        locked = json['locked'] ?? false,
        visible = json['visible'] ?? true,
        groupId = json['group_id'],
        groupName = json['group_name'],
        groupCollapsed = json['group_collapsed'] ?? false;

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': [position.dx.round(), position.dy.round()],
        if (scrollOffset != Offset.zero)
          'scroll_offset': [scrollOffset.dx.round(), scrollOffset.dy.round()],
        'size': [size.width.round(), size.height.round()],
        'type': type,
        if (name != null) 'name': name,
        if (subtype != null) 'subtype': subtype,
        'z_order': zOrder,
        if (parentId != null) 'parent_id': parentId,
        if (childrenIds.isNotEmpty) 'children_ids': childrenIds,
        if (connections.isNotEmpty) 'connections': connections,
        if (data != null) 'dynamic_data': (data as dynamic)?.toJson(),
        if (locked) 'locked': locked,
        if (!visible) 'visible': visible,
        if (groupId != null) 'group_id': groupId,
        if (groupName != null) 'group_name': groupName,
        if (groupCollapsed) 'group_collapsed': groupCollapsed,
      };

  /// 현재 [Component]를 일부 값만 변경해 복사합니다.
  ///
  /// - [replaceData]가 `true`면 [data]를 그대로 교체합니다.
  Component<T> copyWith({
    String? id,
    Offset? position,
    Offset? scrollOffset,
    Size? size,
    String? type,
    String? name,
    String? subtype,
    String? parentId,
    int? zOrder,
    T? data,
    bool replaceData = false,
    bool? visible,
  }) {
    final component = Component<T>(
      id: id ?? this.id,
      position: position ?? this.position,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      size: size ?? this.size,
      type: type ?? this.type,
      name: name ?? this.name,
      subtype: subtype ?? this.subtype,
      zOrder: zOrder ?? this.zOrder,
      parentId: parentId ?? this.parentId,
      data: replaceData ? data : (data ?? this.data),
      visible: visible ?? this.visible,
    );

    return component;
  }
}
