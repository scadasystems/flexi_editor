import 'package:flexi_editor/flexi_editor.dart';

class FlexiData {
  final List<ComponentData> components;
  final List<LinkData> links;

  FlexiData({
    required this.components,
    required this.links,
  });

  FlexiData.fromJson(
    Map<String, dynamic> json, {
    Function(Map<String, dynamic> json)? decodeCustomComponentData,
    Function(Map<String, dynamic> json)? decodeCustomLinkData,
  })  : components = (json['components'] as List).map((componentJson) {
          return ComponentData.fromJson(
            componentJson,
            decodeCustomComponentData: decodeCustomComponentData,
          );
        }).toList(),
        links = (json['links'] as List).map((linkJson) {
          return LinkData.fromJson(
            linkJson,
            decodeCustomLinkData: decodeCustomLinkData,
          );
        }).toList();

  Map<String, dynamic> toJson() => {
        'components': components,
        'links': links,
      };
}
