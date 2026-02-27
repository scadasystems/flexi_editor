import 'package:flexi_editor/src/canvas_context/model/port_type.dart';
import 'package:uuid/uuid.dart';

class Connection {
  final String id;
  final String sourceComponentId;
  final PortType sourcePort;
  final String targetComponentId;
  final PortType targetPort;

  Connection({
    String? id,
    required this.sourceComponentId,
    required this.sourcePort,
    required this.targetComponentId,
    required this.targetPort,
  }) : id = id ?? const Uuid().v4();

  Connection.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        sourceComponentId = json['source_component_id'],
        sourcePort = PortType.values.byName(json['source_port']),
        targetComponentId = json['target_component_id'],
        targetPort = PortType.values.byName(json['target_port']);

  Map<String, dynamic> toJson() => {
        'id': id,
        'source_component_id': sourceComponentId,
        'source_port': sourcePort.name,
        'target_component_id': targetComponentId,
        'target_port': targetPort.name,
      };

  Connection copyWith({
    String? id,
    String? sourceComponentId,
    PortType? sourcePort,
    String? targetComponentId,
    PortType? targetPort,
  }) {
    return Connection(
      id: id ?? this.id,
      sourceComponentId: sourceComponentId ?? this.sourceComponentId,
      sourcePort: sourcePort ?? this.sourcePort,
      targetComponentId: targetComponentId ?? this.targetComponentId,
      targetPort: targetPort ?? this.targetPort,
    );
  }
}
