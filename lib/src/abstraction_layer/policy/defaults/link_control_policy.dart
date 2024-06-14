import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';

mixin LinkControlPolicy implements LinkPolicy {
  @override
  void onLinkTapUp(String linkId, TapUpDetails details) {
    canvasWriter.model.hideAllLinkJoints();
    canvasWriter.model.showLinkJoints(linkId);
  }

  int? _segmentIndex;

  @override
  void onLinkScaleStart(String linkId, ScaleStartDetails details) {
    canvasWriter.model.hideAllLinkJoints();
    canvasWriter.model.showLinkJoints(linkId);
    _segmentIndex = canvasReader.model
        .determineLinkSegmentIndex(linkId, details.localFocalPoint);
    if (_segmentIndex != null) {
      canvasWriter.model.insertLinkMiddlePoint(
          linkId, details.localFocalPoint, _segmentIndex!);
      canvasWriter.model.updateLink(linkId);
    }
  }

  @override
  void onLinkScaleUpdate(String linkId, ScaleUpdateDetails details) {
    if (_segmentIndex != null) {
      canvasWriter.model.setLinkMiddlePointPosition(
          linkId, details.localFocalPoint, _segmentIndex!);
      canvasWriter.model.updateLink(linkId);
    }
  }

  @override
  void onLinkLongPressStart(String linkId, LongPressStartDetails details) {
    canvasWriter.model.hideAllLinkJoints();
    canvasWriter.model.showLinkJoints(linkId);
    _segmentIndex = canvasReader.model
        .determineLinkSegmentIndex(linkId, details.localPosition);
    if (_segmentIndex != null) {
      canvasWriter.model
          .insertLinkMiddlePoint(linkId, details.localPosition, _segmentIndex!);
      canvasWriter.model.updateLink(linkId);
    }
  }

  @override
  void onLinkLongPressMoveUpdate(
      String linkId, LongPressMoveUpdateDetails details) {
    if (_segmentIndex != null) {
      canvasWriter.model.setLinkMiddlePointPosition(
          linkId, details.localPosition, _segmentIndex!);
      canvasWriter.model.updateLink(linkId);
    }
  }
}
