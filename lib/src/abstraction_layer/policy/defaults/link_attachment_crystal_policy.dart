import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';

mixin LinkAttachmentCrystalPolicy implements LinkAttachmentPolicy {
  @override
  Alignment getLinkEndpointAlignment(
    ComponentData componentData,
    Offset targetPoint,
  ) {
    Offset pointPosition = targetPoint -
        (componentData.position + componentData.size.center(Offset.zero));
    pointPosition = Offset(
      pointPosition.dx / componentData.size.width,
      pointPosition.dy / componentData.size.height,
    );

    Offset pointAlignment =
        pointPosition / (pointPosition.dx.abs() + pointPosition.dy.abs());

    return Alignment(pointAlignment.dx, pointAlignment.dy);
  }
}
