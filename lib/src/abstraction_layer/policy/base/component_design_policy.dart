import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flexi_editor/src/canvas_context/model/component_data.dart';
import 'package:flutter/material.dart';

mixin ComponentDesignPolicy on BasePolicySet {
  Widget? showComponentBody(ComponentData componentData) {
    return null;
  }
}
