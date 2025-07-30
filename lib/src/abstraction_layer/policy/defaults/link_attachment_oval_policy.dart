import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';

mixin LinkAttachmentOvalPolicy implements LinkAttachmentPolicy {
  @override
  Alignment getLinkEndpointAlignment(
    Component componentData,
    Offset targetPoint,
  ) {
    Offset pointPosition = targetPoint -
        (componentData.position + componentData.size.center(Offset.zero));
    pointPosition = Offset(
      pointPosition.dx / componentData.size.width,
      pointPosition.dy / componentData.size.height,
    );

    Offset pointAlignment = pointPosition / pointPosition.distance;

    return Alignment(pointAlignment.dx, pointAlignment.dy);
  }
}
