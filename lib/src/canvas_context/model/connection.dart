/// 컴포넌트 간 링크(Edge) 연결을 표현하는 커넥션 모델입니다.
///
/// 생성자 파라미터:
/// - [connectionId]: 링크/커넥션 고유 ID
/// - [otherComponentId]: 연결된 상대 컴포넌트 ID
abstract class Connection {
  final String connectionId;
  final String otherComponentId;

  /// [Connection]을 생성합니다.
  Connection({
    /// 링크/커넥션 고유 ID입니다.
    required this.connectionId,
    /// 연결된 상대 컴포넌트 ID입니다.
    required this.otherComponentId,
  });

  bool contains(String id) {
    return id == connectionId;
  }

  factory Connection.fromJson(Map<String, dynamic> json) => (json['type'] == 0)
      ? ConnectionOut(
          connectionId: json['connection_id'],
          otherComponentId: json['other_component_id'],
        )
      : ConnectionIn(
          connectionId: json['connection_id'],
          otherComponentId: json['other_component_id'],
        );

  Map<String, dynamic> toJson() => (this is ConnectionOut)
      ? {
          'type': 0,
          'connection_id': connectionId,
          'other_component_id': otherComponentId,
        }
      : {
          'type': 1,
          'connection_id': connectionId,
          'other_component_id': otherComponentId,
        };
}

/// 아웃바운드(출발) 커넥션입니다.
class ConnectionOut extends Connection {
  /// [ConnectionOut]을 생성합니다.
  ConnectionOut({
    required super.connectionId,
    required super.otherComponentId,
  });
}

/// 인바운드(도착) 커넥션입니다.
class ConnectionIn extends Connection {
  /// [ConnectionIn]을 생성합니다.
  ConnectionIn({
    required super.connectionId,
    required super.otherComponentId,
  });
}
