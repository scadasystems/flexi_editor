abstract class Connection {
  final String connectionId;
  final String otherComponentId;

  Connection({
    required this.connectionId,
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

class ConnectionOut extends Connection {
  ConnectionOut({
    required super.connectionId,
    required super.otherComponentId,
  });
}

class ConnectionIn extends Connection {
  ConnectionIn({
    required super.connectionId,
    required super.otherComponentId,
  });
}
