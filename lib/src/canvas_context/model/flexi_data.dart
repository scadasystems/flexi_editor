import 'package:flexi_editor/flexi_editor.dart';

class FlexiData {
  final List<Component> components;

  FlexiData({
    required this.components,
  });

  FlexiData.fromJson(
    Map<String, dynamic> json, {
    Function(Map<String, dynamic> json)? decodeCustomComponentData,
  }) : components = (json['components'] as List).map((componentJson) {
          return Component.fromJson(
            componentJson,
            decodeCustomComponentData: decodeCustomComponentData,
          );
        }).toList();

  Map<String, dynamic> toJson() => {
        'components': components,
      };
}
