import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flexi_editor/src/canvas_context/model/component.dart';
import 'package:flutter/material.dart';

mixin LinkAttachmentPolicy on BasePolicySet {
  Alignment getLinkEndpointAlignment(
    Component componentData,
    Offset targetPoint,
  ) {
    return Alignment.center;
  }
}
