// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:example/main.dart';
import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';

class RectComponent extends StatelessWidget {
  final ComponentData componentData;

  const RectComponent({
    super.key,
    required this.componentData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: (componentData.data as MyComponentData).color,
        border: Border.all(
          width: 2,
          color: (componentData.data as MyComponentData).isHoverHighlight
              ? Colors.blue
              : (componentData.data as MyComponentData).isHighlightVisible //
                  ? Colors.pink
                  : Colors.black,
        ),
      ),
      child: const Center(
        child: Text('component'),
      ),
    );
  }
}
