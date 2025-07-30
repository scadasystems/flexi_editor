import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';
import 'package:flexi_editor/src/canvas_context/model/component.dart';
import 'package:flutter/material.dart';

mixin ComponentWidgetsPolicy on BasePolicySet {
  Widget showCustomWidgetWithComponentDataUnder(
    BuildContext context,
    Component componentData,
  ) {
    return const SizedBox.shrink();
  }

  Widget showCustomWidgetWithComponentData(
    BuildContext context,
    Component componentData,
  ) {
    return const SizedBox.shrink();
  }

  Widget buildComponentOverWidget(
    BuildContext context,
    Component componentData,
  ) {
    return const SizedBox.shrink();
  }

  Widget buildLinkOverWidget(
    BuildContext context,
    Component componentData,
  ) {
    return const SizedBox.shrink();
  }
}
