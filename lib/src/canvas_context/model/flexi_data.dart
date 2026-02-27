import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/model/connection.dart';

class FlexiData {
  final List<Component> components;
  final List<Connection> connections;

  FlexiData({
    required this.components,
    this.connections = const [],
  });

  FlexiData.fromJson(
    Map<String, dynamic> json, {
    Function(Map<String, dynamic> json)? decodeCustomComponentData,
  })  : components = (json['components'] as List).map((componentJson) {
          return Component.fromJson(
            componentJson,
            decodeCustomComponentData: decodeCustomComponentData,
          );
        }).toList(),
        connections = json['connections'] != null
            ? (json['connections'] as List)
                .map((connectionJson) => Connection.fromJson(connectionJson))
                .toList()
            : [];

  Map<String, dynamic> toJson() => {
        'components': components,
        'connections': connections,
      };
}
