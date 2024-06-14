import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';

mixin LinkJointControlPolicy implements LinkJointPolicy {
  @override
  void onLinkJointLongPress(int jointIndex, String linkId) {
    canvasWriter.model.removeLinkMiddlePoint(linkId, jointIndex);
    canvasWriter.model.updateLink(linkId);
  }

  @override
  void onLinkJointScaleUpdate(
    int jointIndex,
    String linkId,
    ScaleUpdateDetails details,
  ) {
    canvasWriter.model.setLinkMiddlePointPosition(
      linkId,
      details.localFocalPoint,
      jointIndex,
    );
    canvasWriter.model.updateLink(linkId);
  }
}
